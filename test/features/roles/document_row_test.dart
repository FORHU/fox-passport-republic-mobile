import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/documents/document_picker.dart';
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

class _Documents implements DocumentPicker {
  _Documents(this.result);

  final DocumentPickResult result;
  int asked = 0;

  @override
  Future<DocumentPickResult> pick() async {
    asked++;
    return result;
  }
}

final _scan = PickedPhoto(bytes: Uint8List.fromList([1]), name: 'id.jpg');
final _cv = PickedPhoto(bytes: Uint8List.fromList([1]), name: 'cv.docx');

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

  group('DocumentRow for a portfolio (app#371)', () {
    Future<void> openDocument(WidgetTester tester, _Documents documents) async {
      got = null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentPickerProvider.overrideWithValue(documents),
            photoCaptureProvider
                .overrideWithValue(_Capture(const PhotoPickCancelled())),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DocumentRow(
                label: 'Portfolio or resume (optional)',
                photo: null,
                document: true,
                onPicked: (p) => got = p,
                onRemove: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('says which files it takes, and opens the files, not photos', (
      tester,
    ) async {
      final documents = _Documents(DocumentPicked(_cv));
      await openDocument(tester, documents);
      expect(find.text('PDF, DOC or DOCX, up to 15 MB'), findsOneWidget);

      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();

      expect(documents.asked, 1);
      expect(find.text('Take a photo'), findsNothing);
      expect(got?.name, 'cv.docx');
    });

    testWidgets('says plainly when the file is not a PDF or Word document', (
      tester,
    ) async {
      await openDocument(
        tester,
        _Documents(const DocumentPickFailed(DocumentPickFailure.unsupported)),
      );

      await tester.tap(find.text('Choose'));
      await tester.pump();

      expect(got, isNull);
      expect(
        find.text('Use a PDF or Word document (.pdf, .doc, .docx).'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('isPortfolioFileName', () {
    test('takes PDF and Word names, any case, and nothing else', () {
      expect(isPortfolioFileName('cv.pdf'), isTrue);
      expect(isPortfolioFileName('CV.DOCX'), isTrue);
      expect(isPortfolioFileName('resume.doc'), isTrue);
      expect(isPortfolioFileName('work.png'), isFalse);
      expect(isPortfolioFileName('pdf'), isFalse);
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
