import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum SocialProvider { google, facebook }

/// What the platform handed back. Which of the two depends on the path taken:
/// the native SDK yields a provider [SocialToken]; the browser redirect flow
/// yields a one-time [SocialExchangeCode] the API redeems for a session.
sealed class SocialCredential {
  const SocialCredential();
}

/// A Google ID token or a Facebook user access token, minted on-device.
class SocialToken extends SocialCredential {
  const SocialToken(this.value);
  final String value;
}

/// The `xc` code from the API's redirect back to the app's URL scheme.
class SocialExchangeCode extends SocialCredential {
  const SocialExchangeCode(this.code);
  final String code;
}

/// The user closed the provider's UI. Not an error worth showing.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

/// The only seam to platform plugins, so repositories and controllers stay
/// testable without a device. Implementations talk to the provider; they never
/// touch the Fox Passport API.
abstract class SocialCredentialSource {
  /// False where neither flow can run (Flutter web — see the plan doc).
  bool get isSupported;

  /// Throws [SocialSignInCancelled] on cancel, [ServerException] otherwise.
  Future<SocialCredential> obtain(SocialProvider provider);
}

class PlatformSocialCredentialSource implements SocialCredentialSource {
  PlatformSocialCredentialSource(this._config);

  final AppConfig _config;
  bool _googleInitialised = false;

  @override
  bool get isSupported => !kIsWeb;

  @override
  Future<SocialCredential> obtain(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => _google(),
      SocialProvider.facebook => _facebook(),
    };
  }

  // ── Google ────────────────────────────────────────────────────────────

  Future<SocialCredential> _google() async {
    final native = _config.googleServerClientId.isNotEmpty &&
        GoogleSignIn.instance.supportsAuthenticate();
    if (!native) return _browser(ApiEndpoints.googleStart);

    try {
      if (!_googleInitialised) {
        await GoogleSignIn.instance.initialize(
          clientId:
              _config.googleClientId.isEmpty ? null : _config.googleClientId,
          serverClientId: _config.googleServerClientId,
        );
        _googleInitialised = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ServerException('Google did not return an ID token.');
      }
      return SocialToken(idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled();
      }
      throw ServerException(
        e.description ?? 'Google sign-in failed (${e.code.name}).',
      );
    }
  }

  // ── Facebook ──────────────────────────────────────────────────────────

  Future<SocialCredential> _facebook() async {
    if (!_config.facebookNativeEnabled) {
      return _browser(ApiEndpoints.facebookStart);
    }

    // `enabled` tracking, not the iOS default `limited`: a limited login
    // returns an OIDC JWT, which the Graph API (and the server's
    // `debug_token` check) does not accept as a user access token.
    final result = await FacebookAuth.instance.login(
      permissions: const ['public_profile', 'email'],
      loginTracking: LoginTracking.enabled,
    );
    switch (result.status) {
      case LoginStatus.success:
        final token = result.accessToken?.tokenString;
        if (token == null || token.isEmpty) {
          throw const ServerException('Facebook did not return a token.');
        }
        return SocialToken(token);
      case LoginStatus.cancelled:
        throw const SocialSignInCancelled();
      case LoginStatus.failed:
      case LoginStatus.operationInProgress:
        throw ServerException(result.message ?? 'Facebook sign-in failed.');
    }
  }

  // ── Browser redirect flow (both providers) ────────────────────────────

  /// Opens the API's `/auth/<provider>?origin=<app scheme>` in the system
  /// browser. The API sends it back to `<origin>/auth/<provider>/callback`,
  /// which the OS hands to this app, carrying `?xc=<one-time code>` — or
  /// `?<provider>AuthError=1` when the provider or the server refused.
  Future<SocialCredential> _browser(String startPath) async {
    final url = Uri.parse('${_config.baseUrl}$startPath').replace(
      queryParameters: {'origin': _config.socialRedirectOrigin},
    );

    final String callback;
    try {
      callback = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _config.socialRedirectScheme,
        options: const FlutterWebAuth2Options(preferEphemeral: true),
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const SocialSignInCancelled();
      throw ServerException(e.message ?? 'Sign-in could not be completed.');
    }

    final params = Uri.parse(callback).queryParameters;
    final code = params['xc'];
    if (code == null || code.isEmpty) {
      throw const ServerException(
        'Sign-in was refused. Please try again or use another method.',
      );
    }
    return SocialExchangeCode(code);
  }
}
