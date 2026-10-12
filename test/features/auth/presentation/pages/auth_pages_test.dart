import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/brand_logo.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The restyled auth screens (docs/mobile-design.md §5) must lay out cleanly
/// on a small phone and a roomy one, with and without the keyboard's inset.
void main() {
  authValidationTests();
  late SharedPreferences prefs;

  setUp(() async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    required Size size,
    double keyboard = 0,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const small = Size(320, 568);
  const large = Size(412, 915);

  final pages = <String, Widget>{
    'login': const LoginPage(),
    'register': const RegisterPage(),
    'verify': const VerifyEmailPage(email: 'ada@example.com'),
    'forgot': const ForgotPasswordPage(),
    'reset': const ResetPasswordPage(email: 'ada@example.com'),
  };

  for (final entry in pages.entries) {
    for (final (label, size, keyboard) in [
      ('small', small, 0.0),
      ('large', large, 0.0),
      ('small with keyboard', small, 260.0),
    ]) {
      testWidgets('${entry.key} lays out on $label', (tester) async {
        await pump(tester, entry.value, size: size, keyboard: keyboard);

        expect(tester.takeException(), isNull);
        expect(find.text('FoxPassport'), findsOneWidget);
      });
    }
  }

  testWidgets('login follows the spec copy and has no card or badge',
      (tester) async {
    await pump(tester, const LoginPage(), size: large);

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('LOG IN TO YOUR ACCOUNT'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    // The mockup's divider and three social buttons, in its order.
    expect(find.text('OR'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    // The old white card and ink badge icon are gone; the brand mark is the
    // fox logo, not a placeholder paw icon.
    expect(find.byIcon(Icons.flutter_dash), findsNothing);
    expect(find.byIcon(Icons.pets_rounded), findsNothing);
    expect(find.byType(FoxLogo), findsOneWidget);
  });

  testWidgets('the social buttons are shown but disabled', (tester) async {
    await pump(tester, const LoginPage(), size: large);

    for (final label in [
      'Continue with Apple',
      'Continue with Google',
      'Continue with Facebook',
    ]) {
      final button = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, label),
      );
      expect(button.onPressed, isNull, reason: '$label should be disabled');
    }
  });

  testWidgets('the form sits clear of the bottom edge, not pushed to it',
      (tester) async {
    await pump(tester, const LoginPage(), size: const Size(412, 915));

    // With spare height split 1 : 2, there is breathing room under the last
    // link as well as above the eyebrow.
    final linkBottom = tester.getBottomLeft(find.text('Create an account')).dy;
    expect(linkBottom, lessThan(915 - 100));
  });

  testWidgets('register shows its own copy and a back arrow', (tester) async {
    await pump(tester, const RegisterPage(), size: large);

    expect(find.text('FREE TO JOIN'), findsOneWidget);
    expect(find.text('CREATE YOUR ACCOUNT'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });
}

/// Field validation on the forms: live as the user types, and on submit.
/// The rules and messages are the web app's (see validators_test.dart for the
/// exhaustive parity check); these tests prove the forms wire them up.
void authValidationTests() {
  late SharedPreferences prefs;

  setUp(() async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> show(WidgetTester tester, Widget page) async {
    tester.view
      ..physicalSize = const Size(412, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String hint) =>
      find.widgetWithText(TextFormField, hint, skipOffstage: false);

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
  }

  const termsMessage =
      'Please accept the Terms of Service and Privacy Policy to continue';

  group('Register validation (web signupSchema)', () {
    testWidgets(
        "has the web's fields: name, email, username, password, confirm",
        (tester) async {
      await show(tester, const RegisterPage());

      for (final hint in [
        'Full name',
        'Email address',
        'Username',
        'Password',
        'Confirm password',
      ]) {
        expect(field(hint), findsOneWidget, reason: hint);
      }
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('submitting an empty form lists every problem', (tester) async {
      await show(tester, const RegisterPage());

      await scrollTo(tester, find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Invalid email address'), findsOneWidget);
      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );
      expect(
        find.text('Password must be at least 16 characters'),
        findsOneWidget,
      );
      expect(find.text(termsMessage), findsOneWidget);
    });

    testWidgets('flags bad input as the user types, before submitting',
        (tester) async {
      await show(tester, const RegisterPage());

      await tester.enterText(field('Full name'), 'R2D2');
      await tester.enterText(field('Email address'), 'not-an-email');
      await tester.enterText(field('Username'), 'ab');
      await tester.enterText(field('Password'), 'short');
      await tester.pumpAndSettle();

      expect(find.text('Name can only contain letters'), findsOneWidget);
      expect(find.text('Invalid email address'), findsOneWidget);
      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );
      expect(
        find.text('Password must be at least 16 characters'),
        findsOneWidget,
      );
    });

    testWidgets("walks the password rules in the web's order", (tester) async {
      await show(tester, const RegisterPage());

      Future<void> expectFor(String password, String message) async {
        await tester.enterText(field('Password'), password);
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget, reason: password);
      }

      await expectFor(
        'abcdefghijklmn1!',
        'Password must contain at least one uppercase letter',
      );
      await expectFor(
        'ABCDEFGHIJKLMN1!',
        'Password must contain at least one lowercase letter',
      );
      await expectFor(
        'Abcdefghijklmno!',
        'Password must contain at least one digit',
      );
      await expectFor(
        'Abcdefghijklmno1',
        'Password must contain at least one special character',
      );
    });

    testWidgets('a mismatched confirmation is flagged', (tester) async {
      await show(tester, const RegisterPage());

      await tester.enterText(field('Password'), 'Abcdefghijklmn1!');
      await tester.enterText(field('Confirm password'), 'Abcdefghijklmn1?');
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('valid input shows no errors', (tester) async {
      await show(tester, const RegisterPage());

      await tester.enterText(field('Full name'), 'Ada Lovelace');
      await tester.enterText(field('Email address'), 'ada@example.com');
      await tester.enterText(field('Username'), 'ada_l');
      await tester.enterText(field('Password'), 'Abcdefghijklmn1!');
      await tester.enterText(field('Confirm password'), 'Abcdefghijklmn1!');
      await tester.pumpAndSettle();

      for (final msg in [
        'Name is required',
        'Name can only contain letters',
        'Invalid email address',
        'Username must be at least 3 characters',
        'Password must be at least 16 characters',
        'Passwords do not match',
      ]) {
        expect(find.text(msg), findsNothing, reason: msg);
      }
    });

    testWidgets('the terms checkbox is required and clears when ticked',
        (tester) async {
      await show(tester, const RegisterPage());

      await scrollTo(tester, find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text(termsMessage), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text(termsMessage), findsNothing);
    });

    testWidgets('tells the user the password rules up front', (tester) async {
      await show(tester, const RegisterPage());

      expect(find.textContaining('At least 16 characters'), findsOneWidget);
    });
  });

  group('Login validation (web loginSchema)', () {
    testWidgets("requires both fields on submit, with the web's messages",
        (tester) async {
      await show(tester, const LoginPage());

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid email address'),
        findsOneWidget,
      );
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('does not apply sign-up strength rules to sign-in',
        (tester) async {
      await show(tester, const LoginPage());

      // A short, simple password is a perfectly fine thing to *enter*.
      await tester.enterText(field('Password'), 'abc');
      await tester.pumpAndSettle();

      expect(find.textContaining('Password must'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
    });

    testWidgets('flags a malformed email live', (tester) async {
      await show(tester, const LoginPage());

      await tester.enterText(field('Email address'), 'ada@');
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid email address'),
        findsOneWidget,
      );
    });
  });
}
