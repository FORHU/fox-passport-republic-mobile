import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/data/identity_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/identity_status.dart';
import 'package:flutter_template/features/profile/presentation/pages/identity_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _Picker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async =>
      PickedPhoto(bytes: Uint8List.fromList([1, 2, 3]), name: 'id.jpg');
}

class _FakeIdentity extends IdentityRepository {
  _FakeIdentity(this.current, {this.fails = false}) : super(_MockApi());

  IdentityStatus current;
  final bool fails;
  final sent = <String>[];

  @override
  Future<IdentityStatus> status() async => current;

  @override
  Future<void> submit({
    required IdType type,
    required PickedPhoto id,
    PickedPhoto? selfie,
  }) async {
    sent.add('${type.wire} selfie=${selfie != null}');
    if (fails) throw const ServerException('Your ID is already being reviewed');
    current = IdentityStatus(
      latest: IdentitySubmission(
        status: 'pending',
        createdAt: DateTime(2030, 1, 2),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester, _FakeIdentity repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        identityRepositoryProvider.overrideWithValue(repo),
        photoPickerProvider.overrideWithValue(_Picker()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IdentityPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('IdentityStatus', () {
    test('reads the API and works out what is possible', () {
      final none = IdentityStatus.fromJson({'verifiedAt': null});
      expect(none.canSubmit, isTrue);

      final pending = IdentityStatus.fromJson({
        'verifiedAt': null,
        'latest': {'status': 'pending', 'createdAt': '2030-01-02T00:00:00Z'},
      });
      expect(pending.isPending, isTrue);
      expect(pending.canSubmit, isFalse);

      final verified = IdentityStatus.fromJson({
        'verifiedAt': '2030-01-03T00:00:00Z',
        'latest': {'status': 'approved'},
      });
      expect(verified.isVerified, isTrue);
      expect(verified.canSubmit, isFalse);

      final rejected = IdentityStatus.fromJson({
        'verifiedAt': null,
        'latest': {'status': 'rejected', 'rejectionReason': ' Blurry '},
      });
      expect(rejected.canSubmit, isTrue);
      expect(rejected.latest?.rejectionReason, 'Blurry');
    });
  });

  test('the ID goes up as a form with its kind', () async {
    final api = _MockApi();
    when(() => api.post(ApiEndpoints.identityVerification, any()))
        .thenAnswer((_) async => {'success': true});

    await IdentityRepository(api).submit(
      type: IdType.driversLicense,
      id: PickedPhoto(bytes: Uint8List.fromList([1]), name: 'id.jpg'),
    );

    final form = verify(
      () => api.post(ApiEndpoints.identityVerification, captureAny()),
    ).captured.single as FormData;
    expect(form.fields.single.key, 'idType');
    expect(form.fields.single.value, 'drivers_license');
    expect(form.files.map((f) => f.key), ['idFile']);
  });

  group('the page', () {
    testWidgets('needs an ID photo before it can be sent', (tester) async {
      await _open(tester, _FakeIdentity(const IdentityStatus()));
      final send = find.widgetWithText(ElevatedButton, 'Send for review');
      expect(tester.widget<ElevatedButton>(send).onPressed, isNull);

      await tester.tap(find.text('Photo of your ID'));
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(send).onPressed, isNotNull);
    });

    testWidgets('sends the chosen kind, then shows it is being reviewed',
        (tester) async {
      final repo = _FakeIdentity(const IdentityStatus());
      await _open(tester, repo);

      await tester.tap(find.text('National ID'));
      await tester.tap(find.text('Photo of your ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(repo.sent, ['national_id selfie=false']);
      expect(find.textContaining('being reviewed'), findsOneWidget);
      expect(find.text('Send for review'), findsNothing);
    });

    testWidgets('a refusal is shown and the form stays', (tester) async {
      await _open(tester, _FakeIdentity(const IdentityStatus(), fails: true));
      await tester.tap(find.text('Photo of your ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send for review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Your ID is already being reviewed'), findsOneWidget);
      expect(find.text('Send for review'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a verified person sees the badge and no form', (tester) async {
      await _open(
        tester,
        _FakeIdentity(IdentityStatus(verifiedAt: DateTime(2030))),
      );
      expect(find.text('Your identity is verified.'), findsOneWidget);
      expect(find.text('Send for review'), findsNothing);
    });

    testWidgets('a rejection says why and lets you send another',
        (tester) async {
      await _open(
        tester,
        _FakeIdentity(
          const IdentityStatus(
            latest: IdentitySubmission(
              status: 'rejected',
              createdAt: null,
              rejectionReason: 'Photo is blurry',
            ),
          ),
        ),
      );
      expect(find.textContaining('Photo is blurry'), findsOneWidget);
      expect(find.text('Send for review'), findsOneWidget);
    });
  });
}
