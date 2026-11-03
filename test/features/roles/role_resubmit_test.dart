import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_resubmit_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/role_resubmit_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/roles/role_request.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _MockRepo extends Mock implements RoleApplicationRepository {}

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async =>
      PickedPhoto(bytes: Uint8List.fromList([1]), name: 'scan.jpg');
}

PickedPhoto _photo(String name) =>
    PickedPhoto(bytes: Uint8List.fromList([1, 2]), name: name);

const _flagged = RoleRequestSummary(
  id: 'r1',
  roleType: 'organizer',
  status: 'revision_requested',
  flaggedDocuments: ['validId1', 'selfieFile'],
  revisionNote: 'The photo is blurry',
);

void main() {
  setUpAll(() {
    registerFallbackValue(FormData());
  });

  group('RoleRequestSummary', () {
    test('reads what an admin flagged, and why', () {
      final r = RoleRequestSummary.fromJson(const {
        'id': 'r1',
        'roleType': 'organizer',
        'status': 'revision_requested',
        'flaggedDocuments': ['validId1', 'nbiFile'],
        'revisionNote': 'Blurry',
      });

      expect(r.needsRevision, isTrue);
      expect(r.flaggedDocuments, ['validId1', 'nbiFile']);
      expect(r.revisionNote, 'Blurry');
    });

    test('has nothing flagged when the API sends nothing', () {
      final r = RoleRequestSummary.fromJson(const {
        'id': 'r2',
        'roleType': 'organizer',
        'status': 'pending',
      });

      expect(r.flaggedDocuments, isEmpty);
      expect(r.revisionNote, isNull);
    });
  });

  group('the repository', () {
    test('stores each document privately, then sends their ids', () async {
      final api = _MockApi();
      var n = 0;
      when(() => api.upload(any(), any())).thenAnswer(
        (_) async => {'success': true, 'fileId': 'file-${++n}'},
      );
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});

      await RoleApplicationRepository(api).resubmit('r1', {
        'validId1': _photo('id.jpg'),
        'selfieFile': _photo('me.jpg'),
      });

      verify(() => api.upload('/files/upload-private', any())).called(2);
      verify(
        () => api.patch('/role-requests/r1/resubmit-documents', {
          'documents': {'validId1': 'file-1', 'selfieFile': 'file-2'},
        }),
      ).called(1);
    });

    test('stops when an upload gives no file id, and sends nothing', () async {
      final api = _MockApi();
      when(() => api.upload(any(), any())).thenAnswer((_) async => {});

      await expectLater(
        RoleApplicationRepository(api).resubmit('r1', {
          'validId1': _photo('id.jpg'),
        }),
        throwsA(isA<FormatException>()),
      );
      verifyNever(() => api.patch(any(), any()));
    });
  });

  group('the controller', () {
    late _MockRepo repo;

    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [roleApplicationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.listen(roleResubmitProvider(_flagged), (_, __) {});
      return c;
    }

    setUp(() => repo = _MockRepo());

    test('is complete only when every flagged document has a new file', () {
      final c = container();
      final controller = c.read(roleResubmitProvider(_flagged).notifier);
      expect(controller.complete, isFalse);

      controller.setFile('validId1', _photo('id.jpg'));
      expect(controller.complete, isFalse);

      controller.setFile('selfieFile', _photo('me.jpg'));
      expect(controller.complete, isTrue);

      controller.removeFile('validId1');
      expect(controller.complete, isFalse);
    });

    test('sends only what was chosen, once it is complete', () async {
      when(() => repo.resubmit(any(), any())).thenAnswer((_) async {});
      final c = container();
      final controller = c.read(roleResubmitProvider(_flagged).notifier);

      // Nothing chosen yet: nothing is sent.
      expect(await controller.submit(), isFalse);
      verifyNever(() => repo.resubmit(any(), any()));

      controller
        ..setFile('validId1', _photo('id.jpg'))
        ..setFile('selfieFile', _photo('me.jpg'));
      expect(await controller.submit(), isTrue);

      final sent = verify(() => repo.resubmit('r1', captureAny())).captured;
      expect((sent.single as Map<String, PickedPhoto>).keys, [
        'validId1',
        'selfieFile',
      ]);
    });

    test('keeps the reason when the API refuses', () async {
      when(() => repo.resubmit(any(), any())).thenThrow(Exception('no'));
      final c = container();
      final controller = c.read(roleResubmitProvider(_flagged).notifier)
        ..setFile('validId1', _photo('id.jpg'))
        ..setFile('selfieFile', _photo('me.jpg'));

      expect(await controller.submit(), isFalse);
      expect(c.read(roleResubmitProvider(_flagged)).submitting, isFalse);
    });
  });

  group('the page', () {
    Future<void> open(
      WidgetTester tester,
      List<RoleRequestSummary> requests,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myRoleRequestsProvider.overrideWith((ref) async => requests),
            photoPickerProvider.overrideWithValue(_FakePicker()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RoleResubmitPage(requestId: 'r1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the flagged documents and the reviewer note', (
      tester,
    ) async {
      await open(tester, const [_flagged]);

      expect(find.text('Fix your Organizer application'), findsOneWidget);
      expect(find.text('The photo is blurry'), findsOneWidget);
      expect(find.text('Primary valid ID'), findsOneWidget);
      expect(find.text('Verification selfie'), findsOneWidget);
      // Documents that were not flagged are not asked for again.
      expect(find.text('Police or background clearance'), findsNothing);
    });

    testWidgets('Send waits until every flagged document is replaced', (
      tester,
    ) async {
      await open(tester, const [_flagged]);

      final send = find.widgetWithText(ElevatedButton, 'Send documents');
      expect(tester.widget<ElevatedButton>(send).onPressed, isNull);

      for (final choose in find.text('Choose').evaluate().toList()) {
        await tester.tap(find.byWidget(choose.widget).first);
        await tester.pumpAndSettle();
      }
      expect(tester.widget<ElevatedButton>(send).onPressed, isNotNull);
    });

    testWidgets('says there is nothing to fix for another status', (
      tester,
    ) async {
      await open(tester, const [
        RoleRequestSummary(id: 'r1', roleType: 'organizer', status: 'pending'),
      ]);

      expect(find.text('Nothing to fix here'), findsOneWidget);
      expect(find.text('Send documents'), findsNothing);
    });
  });
}
