/// Form-field validators — a **line-for-line mirror of the web app's zod
/// schemas** (`fox-passport-republic-app/src/shared/lib/schema.ts`), so the same
/// input is accepted or refused, with the same message, on web and on mobile.
///
/// Each returns `null` when valid, else the message to show under the field.
/// When the web schema changes, change this file with it.
///
/// | Web schema | Mirrored by |
/// |---|---|
/// | `loginSchema` | [loginEmail], [loginPassword] |
/// | `signupSchema` | [signupName], [signupEmail], [signupUsername],
///   [signupPassword], [signupConfirmPassword] |
/// | `forgotPasswordSchema` | [forgotEmail] |
/// | `resetPasswordSchema` | [otpCode], [resetNewPassword],
///   [resetConfirmPassword] |
/// | `verifyEmailSchema` | [otpCode] |
class Validators {
  Validators._();

  /// zod v4's `z.email()` pattern, verbatim.
  static final RegExp _zodEmail = RegExp(
    r"^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$",
  );

  /// `signupSchema.name`: `/^[A-Za-z\s'-]+$/`.
  static final RegExp _nameLetters = RegExp(r"^[A-Za-z\s'-]+$");

  /// A browser strips leading and trailing whitespace from an
  /// `<input type="email">` before the form sees it; do the same.
  static bool _isEmail(String? value) =>
      _zodEmail.hasMatch((value ?? '').trim());

  // ── Log in (`loginSchema`) ─────────────────────────────────────────────

  static String? loginEmail(String? value) =>
      _isEmail(value) ? null : 'Please enter a valid email address';

  /// `z.string().min(1)`: presence only, so older accounts can still sign in.
  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Please enter your password' : null;

  // ── Sign up (`signupSchema`) ───────────────────────────────────────────

  /// `min(1, "Name is required")` then `/^[A-Za-z\s'-]+$/`
  /// ("Name can only contain letters").
  static String? signupName(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Name is required';
    if (!_nameLetters.hasMatch(v)) return 'Name can only contain letters';
    return null;
  }

  static String? signupEmail(String? value) =>
      _isEmail(value) ? null : 'Invalid email address';

  /// `min(3)`.
  static String? signupUsername(String? value) {
    final v = value ?? '';
    if (v.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  /// At least 16 characters, one upper-case letter, one lower-case letter, one
  /// digit and one of `@$!%*?&`. As in zod, the first rule that fails is the
  /// one reported, in this order.
  static String? signupPassword(String? value) {
    final v = value ?? '';
    if (v.length < 16) return 'Password must be at least 16 characters';
    if (!RegExp('[A-Z]').hasMatch(v)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp('[a-z]').hasMatch(v)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'Password must contain at least one digit';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(v)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// `refine(password === confirmPassword)`.
  static String? signupConfirmPassword(String? value, String password) =>
      (value ?? '') == password ? null : 'Passwords do not match';

  // ── Forgot password (`forgotPasswordSchema`) ───────────────────────────

  static String? forgotEmail(String? value) =>
      _isEmail(value) ? null : 'Please enter a valid email address';

  // ── Reset password / verify email ──────────────────────────────────────

  /// `z.string().length(6)` — used for both the reset and the verification
  /// code. Length only, exactly as the web.
  static String? otpCode(String? value) =>
      (value ?? '').length == 6 ? null : 'Code must be 6 digits';

  /// `resetPasswordSchema.newPassword`: at least 8 characters, one upper-case
  /// letter, one lower-case letter and one digit. Note: unlike sign-up, no
  /// special character is required here — that is how the web behaves.
  static String? resetNewPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp('[A-Z]').hasMatch(v)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp('[a-z]').hasMatch(v)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'Password must contain at least one digit';
    }
    return null;
  }

  static String? resetConfirmPassword(String? value, String newPassword) =>
      (value ?? '') == newPassword ? null : 'Passwords do not match';
}
