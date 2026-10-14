import 'dart:convert';
import 'dart:io';

import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parity with the web app.
///
/// `test/fixtures/web_validation_vectors.json` was produced by running the web
/// app's real zod schemas (`fox-passport-republic-app/src/shared/lib/schema.ts`)
/// over a few hundred inputs and recording the first message per field. Every
/// vector must come out identically from [Validators] — same accept / refuse,
/// same message.
///
/// Regenerate it when the web schema changes (the generator is described in
/// `test/fixtures/README.md`).
void main() {
  final vectors = jsonDecode(
    File('test/fixtures/web_validation_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  List<Map<String, dynamic>> rule(String name) => [
        for (final v in vectors[name] as List)
          (v as Map).cast<String, dynamic>(),
      ];

  /// A browser strips surrounding whitespace from `<input type="email">`
  /// before the form sees it, so mobile trims too. Expected result for such an
  /// input is the web's result for the trimmed text.
  String? expectedEmail(List<Map<String, dynamic>> all, String input) {
    final key = input.trim();
    return all.firstWhere((v) => v['input'] == key)['message'] as String?;
  }

  void checkEach(
    String name,
    String? Function(String input, Map<String, dynamic> v) actual, {
    String? Function(List<Map<String, dynamic>> all, String input)? expected,
  }) {
    final all = rule(name);
    test('$name matches the web on ${all.length} inputs', () {
      for (final v in all) {
        final input = v['input'] as String;
        final want =
            expected != null ? expected(all, input) : v['message'] as String?;
        expect(
          actual(input, v),
          want,
          reason: '$name(${jsonEncode(input)}) — web says ${jsonEncode(want)}',
        );
      }
    });
  }

  group('web parity (generated from the real zod schemas)', () {
    checkEach('loginEmail', (i, _) => Validators.loginEmail(i),
        expected: expectedEmail);
    checkEach('loginPassword', (i, _) => Validators.loginPassword(i));
    checkEach('signupEmail', (i, _) => Validators.signupEmail(i),
        expected: expectedEmail);
    checkEach('signupName', (i, _) => Validators.signupName(i));
    checkEach('signupUsername', (i, _) => Validators.signupUsername(i));
    checkEach('signupPassword', (i, _) => Validators.signupPassword(i));
    checkEach(
      'signupConfirm',
      (i, v) => Validators.signupConfirmPassword(i, v['password'] as String),
    );
    checkEach('forgotEmail', (i, _) => Validators.forgotEmail(i),
        expected: expectedEmail);
    checkEach('otpCode', (i, _) => Validators.otpCode(i));
    checkEach('resetCode', (i, _) => Validators.otpCode(i));
    checkEach('resetNewPassword', (i, _) => Validators.resetNewPassword(i));
    checkEach(
      'resetConfirm',
      (i, v) => Validators.resetConfirmPassword(i, v['password'] as String),
    );
  });

  group('the web rules, stated plainly', () {
    test('sign-up needs 16+ chars with upper, lower, digit and special', () {
      expect(
        Validators.signupPassword('Abcdefghijklmn1'),
        'Password must be at least 16 characters',
      );
      expect(
        Validators.signupPassword('abcdefghijklmn1!'),
        'Password must contain at least one uppercase letter',
      );
      expect(
        Validators.signupPassword('ABCDEFGHIJKLMN1!'),
        'Password must contain at least one lowercase letter',
      );
      expect(
        Validators.signupPassword('Abcdefghijklmno!'),
        'Password must contain at least one digit',
      );
      expect(
        Validators.signupPassword('Abcdefghijklmno1'),
        'Password must contain at least one special character',
      );
      expect(Validators.signupPassword('Abcdefghijklmn1!'), isNull);
    });

    test('reset needs only 8+ chars with upper, lower and a digit', () {
      expect(Validators.resetNewPassword('Abcdefg1'), isNull);
      expect(
        Validators.resetNewPassword('Abcdef1'),
        'Password must be at least 8 characters',
      );
    });

    test('sign-in only asks for a password to be present', () {
      expect(Validators.loginPassword('x'), isNull);
      expect(Validators.loginPassword(''), 'Please enter your password');
    });

    test('names are ASCII letters, spaces, apostrophes and hyphens', () {
      expect(Validators.signupName("Mary-Jane O'Neil"), isNull);
      expect(Validators.signupName('Zoë'), 'Name can only contain letters');
      expect(Validators.signupName(''), 'Name is required');
    });

    test('usernames need at least 3 characters', () {
      expect(Validators.signupUsername('ab'),
          'Username must be at least 3 characters');
      expect(Validators.signupUsername('abc'), isNull);
    });

    test('codes are exactly 6 characters long', () {
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode('12345'), 'Code must be 6 digits');
    });
  });
}
