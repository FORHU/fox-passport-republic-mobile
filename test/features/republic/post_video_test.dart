import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/media_picker.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/pages/compose_post_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Picker implements MediaPicker {
  PickedMedia? video;
  bool tooLarge = false;

  @override
  Future<List<PickedMedia>> pickMany(int limit) async => [
        PickedMedia(bytes: Uint8List(0), name: 'a.jpg'),
      ];

  @override
  Future<PickedMedia?> pickVideo() async {
    if (tooLarge) throw const MediaTooLarge();
    return video;
  }
}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

PickedMedia _clip() => PickedMedia(
      bytes: Uint8List(3 * 1024 * 1024),
      name: 'party.mp4',
      isVideo: true,
    );

void main() {
  late _MockApi api;
  late _Picker picker;

  setUpAll(() {
    registerFallbackValue(FormData());
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    api = _MockApi();
    picker = _Picker();
  });

  group('uploading', () {
    test('a video goes through the long upload and reports its progress',
        () async {
      final progress = <double>[];
      when(
        () => api.upload(
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((inv) async {
        (inv.namedArguments[#onProgress] as void Function(int, int))(50, 100);
        return {'url': 'https://video.example/a.mp4'};
      });

      final url = await RepublicRepository(api).uploadMedia(
        _clip(),
        onProgress: (sent, total) => progress.add(sent / total),
      );

      expect(url, 'https://video.example/a.mp4');
      expect(progress, [0.5]);
      verifyNever(() => api.post(any(), any()));
    });

    test('a photo still goes through the ordinary call', () async {
      when(() => api.post(ApiEndpoints.uploadFile, any())).thenAnswer(
        (_) async => {
          'file': {'url': 'https://img.example/a.webp'},
        },
      );

      final url = await RepublicRepository(api).uploadMedia(
        PickedMedia(bytes: Uint8List(1), name: 'a.jpg'),
      );

      expect(url, 'https://img.example/a.webp');
      verifyNever(
        () => api.upload(any(), any(), onProgress: any(named: 'onProgress')),
      );
    });
  });

  group('the composer', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(_Session.new),
            mediaPickerProvider.overrideWithValue(picker),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ComposePostPage(),
          ),
        ),
      );
      await tester.pump();
    }

    ElevatedButton postButton(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    testWidgets('a chosen video shows its name and size, and can go', (
      tester,
    ) async {
      picker.video = _clip();
      await open(tester);

      await tester.tap(find.text('Add a video'));
      await tester.pump();

      expect(find.text('party.mp4'), findsOneWidget);
      expect(find.text('3.0 MB'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove video'));
      await tester.pump();
      expect(find.text('party.mp4'), findsNothing);
    });

    testWidgets('a video alone is enough to post, and only one is allowed', (
      tester,
    ) async {
      picker.video = _clip();
      await open(tester);
      expect(postButton(tester).onPressed, isNull);

      await tester.tap(find.text('Add a video'));
      await tester.pump();

      expect(postButton(tester).onPressed, isNotNull);
      final add = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Add a video'),
      );
      expect(add.onPressed, isNull);
    });

    testWidgets('says so when the video is over the limit', (tester) async {
      picker.tooLarge = true;
      await open(tester);

      await tester.tap(find.text('Add a video'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('over 100 MB'), findsOneWidget);
      expect(find.text('party.mp4'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('posting uploads the video and sends its address', (
      tester,
    ) async {
      picker.video = _clip();
      when(
        () => api.upload(any(), any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => {'url': 'https://video.example/a.mp4'});
      when(() => api.post(ApiEndpoints.feed, any())).thenAnswer(
        (_) async => {
          'data': {'id': 'p1'},
        },
      );
      await open(tester);

      await tester.tap(find.text('Add a video'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final sent = verify(() => api.post(ApiEndpoints.feed, captureAny()))
          .captured
          .single as Map;
      expect(sent['mediaUrls'], ['https://video.example/a.mp4']);
    });

    testWidgets('shows why the server would not take the video', (
      tester,
    ) async {
      picker.video = _clip();
      when(
        () => api.upload(any(), any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(
        const ServerException(
          'Video uploads are not set up on this server yet.',
        ),
      );
      await open(tester);

      await tester.tap(find.text('Add a video'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Video uploads are not set up on this server yet.'),
        findsOneWidget,
      );
      // Still there to try again.
      expect(find.text('party.mp4'), findsOneWidget);
      verifyNever(() => api.post(ApiEndpoints.feed, any()));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
