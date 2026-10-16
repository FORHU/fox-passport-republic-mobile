import 'package:flutter_template/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel profile photo', () {
    test('reads the photo the API calls imgId', () {
      final user = UserModel.fromJson(const {
        'user': {
          'id': 'u1',
          'email': 'a@b.co',
          'name': 'Ada',
          'imgId': ' https://img.example/ada.jpg ',
        },
        'token': 't',
      });

      expect(user.imageUrl, 'https://img.example/ada.jpg');
      expect(user.toJson()['imgId'], 'https://img.example/ada.jpg');
    });

    test('is null when there is none, so the initial is shown', () {
      final user = UserModel.fromJson(const {
        'user': {'id': 'u1', 'email': 'a@b.co', 'name': 'Ada', 'imgId': ''},
        'token': 't',
      });

      expect(user.imageUrl, isNull);
    });
  });
}
