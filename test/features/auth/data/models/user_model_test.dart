import 'package:flutter_template/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('parses roles and verification from a login response', () {
      final model = UserModel.fromJson(const {
        'accessToken': 'a',
        'user': {
          'id': 'u1',
          'email': 'foxer@example.com',
          'name': 'Fox',
          'username': 'fox',
          'systemRole': 'user',
          'roleType': ['venueFoxer', 'investor'],
          'isEmailVerified': true,
        },
      });

      expect(model.token, 'a');
      expect(model.username, 'fox');
      expect(model.roleType, ['venueFoxer', 'investor']);
      expect(model.isEmailVerified, isTrue);
      expect(model.isCitizen, isFalse);
      expect(model.hasRole('venueFoxer'), isTrue);
      expect(model.isAdmin, isFalse);
    });

    test('defaults to a plain Citizen when role fields are absent', () {
      final model = UserModel.fromJson(const {
        'accessToken': 'a',
        'user': {'id': 'u1', 'email': 'c@example.com', 'name': 'C'},
      });

      expect(model.systemRole, 'user');
      expect(model.roleType, isEmpty);
      expect(model.isCitizen, isTrue);
    });

    test('round-trips through the local cache JSON', () {
      const original = UserModel(
        id: 'u1',
        email: 'a@example.com',
        name: 'A',
        token: 't',
        username: 'a',
        systemRole: 'admin',
        roleType: ['eventFoxer'],
        isEmailVerified: true,
      );

      final restored = UserModel.fromJson(original.toJson());

      expect(restored, original);
    });

    // api#419: /profile says whether a Google account must still set up.
    test('reads account setup from /profile', () {
      final user = UserModel.fromJson(const {
        'success': true,
        'data': {
          'id': 'u1',
          'email': 'g@example.com',
          'name': 'G',
          'username': null,
          'hasPassword': false,
          'needsCredentialSetup': true,
        },
      });

      expect(user.hasPassword, isFalse);
      expect(user.needsCredentialSetup, isTrue);
      expect(user.username, '');
    });

    test('asks nothing when a sign-in payload leaves the fields out', () {
      final user = UserModel.fromJson(const {
        'token': 't',
        'user': {'id': 'u1', 'email': 'g@example.com', 'name': 'G'},
      });

      expect(user.hasPassword, isTrue);
      expect(user.needsCredentialSetup, isFalse);
    });

    test('keeps account setup through the local cache and a new token', () {
      const original = UserModel(
        id: 'u1',
        email: 'g@example.com',
        name: 'G',
        token: '',
        hasPassword: false,
        needsCredentialSetup: true,
      );

      final restored = UserModel.fromJson(original.toJson()).withToken('t');

      expect(restored.needsCredentialSetup, isTrue);
      expect(restored.hasPassword, isFalse);
      expect(restored.token, 't');
    });
  });
}
