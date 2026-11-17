import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

class _Capture implements PhotoCapture {
  _Capture(this.result);

  final PhotoPickResult result;
  PhotoSource? source;
  bool? front;

  @override
  Future<PhotoPickResult> take({
    required PhotoSource source,
    bool frontCamera = false,
  }) async {
    this.source = source;
    front = frontCamera;
    return result;
  }
}

final _scan = PickedPhoto(bytes: Uint8List.fromList([1]), name: 'id.jpg');

void main() {
  PickedPhoto? got;

  Future<void> open(
    WidgetTester tester,
    _Capture capture, {
    bool frontCamera = false,
  }) async {
    got = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [photoCaptureProvider.overrideWithValue(capture)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DocumentRow(
              label: 'Valid ID',
              photo: null,
              frontCamera: frontCamera,
              onPicked: (p) => got = p,
              onRemove: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
  }

  group('DocumentRow', () {
    testWidgets('offers the camera and the gallery', (tester) async {
      await open(tester, _Capture(PhotoPicked(_scan)));

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
    });

    testWidgets('takes the photo with the rear camera for a document', (
      tester,
    ) async {
      final capture = _Capture(PhotoPicked(_scan));
      await open(tester, capture);

      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(capture.source, PhotoSource.camera);
      expect(capture.front, isFalse);
      expect(got?.name, 'id.jpg');
    });

    testWidgets('opens the front camera for the selfie', (tester) async {
      final capture = _Capture(PhotoPicked(_scan));
      await open(tester, capture, frontCamera: true);

      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(capture.source, PhotoSource.camera);
      expect(capture.front, isTrue);
    });

    testWidgets('chooses from the gallery', (tester) async {
      final capture = _Capture(PhotoPicked(_scan));
      await open(tester, capture);

      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(capture.source, PhotoSource.gallery);
      expect(got, isNotNull);
    });

    testWidgets('says plainly when camera access is refused', (tester) async {
      await open(
        tester,
        _Capture(const PhotoPickFailed(PhotoPickFailure.cameraDenied)),
      );

      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Camera access is off'), findsOneWidget);
      expect(got, isNull);
    });

    testWidgets('says plainly when there is no camera', (tester) async {
      await open(
        tester,
        _Capture(const PhotoPickFailed(PhotoPickFailure.cameraUnavailable)),
      );

      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No camera found'), findsOneWidget);
      expect(got, isNull);
    });

    testWidgets('keeps quiet when the user backs out of the camera', (
      tester,
    ) async {
      await open(tester, _Capture(const PhotoPickCancelled()));

      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(got, isNull);
      expect(find.textContaining('Camera access'), findsNothing);
      expect(find.textContaining('Could not get'), findsNothing);
    });
  });

  group('DevicePhotoPicker.failureFor', () {
    test('maps the platform codes', () {
      expect(
        DevicePhotoPicker.failureFor('camera_access_denied'),
        PhotoPickFailure.cameraDenied,
      );
      expect(
        DevicePhotoPicker.failureFor('camera_access_restricted'),
        PhotoPickFailure.cameraDenied,
      );
      expect(
        DevicePhotoPicker.failureFor('no_available_camera'),
        PhotoPickFailure.cameraUnavailable,
      );
      expect(
        DevicePhotoPicker.failureFor('something_else'),
        PhotoPickFailure.other,
      );
    });
  });
}
