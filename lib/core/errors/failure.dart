import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
/// Ensures that domain layers return consistent error objects.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

/// Represents an error returned by an external server/API.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Represents an error caching data locally.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Represents an error indicating no network connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet connection']);
}

/// Represents an unauthorized or unauthenticated error.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access']);
}

/// The user dismissed Google/Facebook sign-in. Not an error: the UI shows
/// nothing and leaves them on the form.
class SocialSignInCancelledFailure extends Failure {
  const SocialSignInCancelledFailure([super.message = 'Sign-in cancelled']);
}

/// Google/Facebook sign-in found a Fox Passport account with the same email
/// whose email isn't verified, and the API won't join the two until it is
/// (Better Auth's `account not linked`). The UI explains how to verify.
class SocialAccountNotLinkedFailure extends Failure {
  const SocialAccountNotLinkedFailure([
    super.message = 'This email already has an account that is not verified.',
  ]);
}

/// Login was refused because the account's email isn't verified yet. The UI
/// routes the user to the OTP screen instead of showing a plain error.
class EmailNotVerifiedFailure extends Failure {
  const EmailNotVerifiedFailure([
    super.message = 'Please verify your email before signing in.',
  ]);
}
