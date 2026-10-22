import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/cookie_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_template/features/auth/data/datasources/social_credential_source.dart';
import 'package:flutter_template/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_template/features/auth/domain/usecases/refresh_auth_usecase.dart';
import 'package:flutter_template/features/auth/domain/usecases/register_usecase.dart';
import 'package:fpdart/fpdart.dart';

// --- Dependency wiring (Riverpod providers) ---

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    storage: ref.watch(storageServiceProvider),
    cookieService: ref.watch(cookieServiceProvider),
    onUnauthenticated: () {
      unawaited(ref.read(authControllerProvider.notifier).onUnauthenticated());
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = AuthRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return AuthRepositoryImpl(
    remote,
    ref.watch(storageServiceProvider),
    cookieService: ref.watch(cookieServiceProvider),
    social: PlatformSocialCredentialSource(AppConfig.instance),
  );
});

/// Whether to render the Google / Facebook buttons at all.
final socialSignInSupportedProvider = Provider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isSocialSignInSupported,
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final refreshAuthUseCaseProvider = Provider<RefreshAuthUseCase>(
  (ref) => RefreshAuthUseCase(ref.watch(authRepositoryProvider)),
);

// --- State ---

class AuthState extends Equatable {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.pendingVerificationEmail,
  });

  final bool isLoading;
  final UserEntity? user;
  final String? error;

  /// Set after sign-up, or after a login refused for an unverified email, so
  /// the OTP screen knows which account to verify.
  final String? pendingVerificationEmail;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? error,
    String? pendingVerificationEmail,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        // Intentionally not `error ?? this.error`: passing null clears it.
        error: error,
        pendingVerificationEmail:
            pendingVerificationEmail ?? this.pendingVerificationEmail,
      );

  @override
  List<Object?> get props => [isLoading, user, error, pendingVerificationEmail];
}

// --- Controller ---

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Hydrate state from local cache (instant startup, no flicker).
    final cachedUser = ref.read(storageServiceProvider).readUserModel();
    if (cachedUser != null) {
      // Fire-and-forget background refresh to re-validate the cached user.
      unawaited(Future.microtask(refreshAuth));
    }
    return AuthState(user: cachedUser);
  }

  /// Called by the ApiService interceptor when a 401 cannot be recovered.
  Future<void> onUnauthenticated() async {
    await ref.read(storageServiceProvider).clearSession();
    state = const AuthState();
  }

  /// The profile step is answered once per account, not once per device: a
  /// profile with a city was set up already (here or on another device or
  /// browser), so the router must not send that user back to it.
  Future<void> _markProfileSetUp() async {
    final storage = ref.read(storageServiceProvider);
    if (storage.onboardingSeen) return;
    try {
      final body = await ref.read(apiServiceProvider).get(ApiEndpoints.profile);
      final data = body is Map ? (body['data'] ?? body) : null;
      final city = data is Map ? data['city'] : null;
      if (city is String && city.trim().isNotEmpty) {
        await storage.setOnboardingSeen();
      }
    } on Object {
      // Offline or refused: the local flag decides, as before.
    }
  }

  /// Silent background re-validation of the stored token.
  Future<void> refreshAuth() async {
    final result = await ref.read(refreshAuthUseCaseProvider).execute();
    if (result.isRight()) await _markProfileSetUp();
    result.fold(
      // If failed (e.g. token expired), sign out silently.
      (failure) => state = const AuthState(),
      (user) => state = AuthState(user: user),
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final result = await ref.read(loginUseCaseProvider)(email, password);
    // Before the signed-in state reaches the router, so it can skip the
    // profile step for an account that has one.
    if (result.isRight()) await _markProfileSetUp();

    return result.fold(
      (failure) {
        state = AuthState(
          error: failure.message,
          pendingVerificationEmail:
              failure is EmailNotVerifiedFailure ? email.trim() : null,
        );
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  /// Google / Facebook sign-in. A user dismissing the provider's UI returns
  /// false with no error set, so the form stays quiet.
  Future<bool> loginWithSocial(SocialProvider provider) async {
    state = state.copyWith(isLoading: true);

    final result =
        await ref.read(authRepositoryProvider).loginWithSocial(provider);
    if (result.isRight()) await _markProfileSetUp();

    return result.fold(
      (failure) {
        state = AuthState(
          error:
              failure is SocialSignInCancelledFailure ? null : failure.message,
        );
        return false;
      },
      (user) {
        state = AuthState(user: user);
        return true;
      },
    );
  }

  Future<bool> register(
    String email,
    String password, {
    String? name,
    String? username,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await ref.read(registerUseCaseProvider)(
      email,
      password,
      name: name,
      username: username,
    );

    return result.fold(
      (failure) {
        state = AuthState(error: failure.message);
        return false;
      },
      (_) {
        // The account exists but must verify its email before it can sign in.
        state = AuthState(pendingVerificationEmail: email.trim());
        return true;
      },
    );
  }

  /// Confirms the 6-digit email code. On success the user can sign in.
  Future<bool> verifyEmail(String email, String otpCode) => _run(
        () => ref.read(authRepositoryProvider).verifyEmail(email, otpCode),
        clearPendingOnSuccess: true,
      );

  Future<bool> resendVerificationOtp(String email) => _run(
        () => ref.read(authRepositoryProvider).resendVerificationOtp(email),
      );

  Future<bool> forgotPassword(String email) => _run(
        () => ref.read(authRepositoryProvider).forgotPassword(email),
      );

  Future<bool> resetPassword(
    String email,
    String otpCode,
    String newPassword,
  ) =>
      _run(
        () => ref
            .read(authRepositoryProvider)
            .resetPassword(email, otpCode, newPassword),
      );

  /// Shared loading/error handling for the void OTP and recovery calls.
  Future<bool> _run(
    Future<Either<Failure, void>> Function() call, {
    bool clearPendingOnSuccess = false,
  }) async {
    final pending = state.pendingVerificationEmail;
    state = AuthState(isLoading: true, pendingVerificationEmail: pending);

    final result = await call();

    return result.fold(
      (failure) {
        state = AuthState(
          error: failure.message,
          pendingVerificationEmail: pending,
        );
        return false;
      },
      (_) {
        state = AuthState(
          pendingVerificationEmail: clearPendingOnSuccess ? null : pending,
        );
        return true;
      },
    );
  }

  /// Shows a new display name everywhere the session user is read, once the
  /// server has accepted it.
  void setSessionName(String name) => setSessionProfile(name: name);

  /// Shows a changed name, username or photo everywhere the session user is
  /// read, once the server has accepted it.
  void setSessionProfile({String? name, String? username, String? imageUrl}) {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(
      user: user.withProfile(
        name: name,
        username: username,
        imageUrl: imageUrl,
      ),
    );
  }

  Future<bool> logout() async {
    final result = await ref.read(authRepositoryProvider).logout();
    return result.fold(
      // Keep the user signed in on failure — server session was not revoked.
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = const AuthState();
        return true;
      },
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in user's id, or null. Providers that hold one person's data
/// watch this, so a different account never sees the previous one's.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user?.id)),
);
