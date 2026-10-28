import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/reports/file_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Harness extends ConsumerWidget {
  const _Harness(this.result);

  final ValueNotifier<bool?> result;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: TextButton(
          onPressed: () async {
            result.value = await fileReport(
              context,
              ref,
              target: ReportTarget.user,
              id: 'u1',
              title: 'Report this Foxer',
            );
          },
          child: const Text('open'),
        ),
      );
}

Future<ValueNotifier<bool?>> _open(WidgetTester tester, _MockApi api) async {
  final result = ValueNotifier<bool?>(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(api)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Harness(result),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('files the chosen reason against the person', (tester) async {
    final api = _MockApi();
    when(() => api.post(any(), any()))
        .thenAnswer((_) async => <String, dynamic>{});
    final result = await _open(tester, api);

    expect(find.text('Report this Foxer'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    verify(
      () => api.post(ApiEndpoints.reports, {
        'targetType': 'user',
        'targetId': 'u1',
        'reason': 'Spam',
      }),
    ).called(1);
    expect(result.value, isTrue);
  });

  testWidgets('files nothing when the sheet is dismissed', (tester) async {
    final api = _MockApi();
    final result = await _open(tester, api);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    verifyNever(() => api.post(any(), any()));
    expect(result.value, isFalse);
  });

  testWidgets('says why the API refused', (tester) async {
    final api = _MockApi();
    when(() => api.post(any(), any()))
        .thenThrow(const ServerException('You cannot report yourself'));
    final result = await _open(tester, api);

    await tester.tap(find.text('Spam'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('You cannot report yourself'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(result.value, isFalse);
  });
}
