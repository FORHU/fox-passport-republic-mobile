import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum SocialProvider { google, facebook }

/// What the platform handed back: a provider token minted on-device, which
/// the API's Better Auth `/auth/sign-in/social` verifies.
sealed class SocialCredential {
  const SocialCredential();
}

/// A Google ID token or a Facebook user access token, minted on-device.
class SocialToken extends SocialCredential {
  const SocialToken(this.value);
  final String value;
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
    if (!native) {
      throw const ServerException(
        'Google sign-in is not set up on this build.',
      );
    }

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
      throw const ServerException(
        'Facebook sign-in is not set up on this build.',
      );
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
}
