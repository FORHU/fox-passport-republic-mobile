import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/blocks/data/blocks_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/blocks/confirm_block.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FakeBlocks extends BlocksRepository {
  _FakeBlocks({this.fails = false}) : super(_MockApi());

  final bool fails;
  final calls = <String>[];

  @override
  Future<void> block(String userId) async {
    calls.add('block $userId');
    if (fails) {
      throw const ServerException(
        "You can't block this citizen while you have an active booking "
        'together.',
      );
    }
  }
}

/// Opens the dialog from a button and keeps what it resolved to.
class _Harness extends ConsumerWidget {
  const _Harness(this.result);

  final ValueNotifier<bool?> result;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: TextButton(
          onPressed: () async {
            result.value = await confirmBlock(
              context,
              ref,
              userId: 'u1',
              name: 'Rex',
            );
          },
          child: const Text('open'),
        ),
      );
}

Future<ValueNotifier<bool?>> _pump(
  WidgetTester tester,
  _FakeBlocks blocks,
) async {
  final result = ValueNotifier<bool?>(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [blocksRepositoryProvider.overrideWithValue(blocks)],
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
  test('blocking posts the person to the API', () async {
    final api = _MockApi();
    when(() => api.post(ApiEndpoints.blocks, any()))
        .thenAnswer((_) async => {'success': true});

    await BlocksRepository(api).block('u1');

    verify(() => api.post(ApiEndpoints.blocks, {'targetId': 'u1'})).called(1);
  });

  testWidgets('asks first, then blocks and says so', (tester) async {
    final blocks = _FakeBlocks();
    final result = await _pump(tester, blocks);

    expect(find.text('Block Rex?'), findsOneWidget);
    expect(blocks.calls, isEmpty);

    await tester.tap(find.text('Block'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(blocks.calls, ['block u1']);
    expect(result.value, isTrue);
    expect(find.text('Rex is blocked.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Cancel blocks no one', (tester) async {
    final blocks = _FakeBlocks();
    final result = await _pump(tester, blocks);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(blocks.calls, isEmpty);
    expect(result.value, isFalse);
  });

  testWidgets('a refusal is shown and nobody is blocked', (tester) async {
    final result = await _pump(tester, _FakeBlocks(fails: true));

    await tester.tap(find.text('Block'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(result.value, isFalse);
    expect(find.textContaining('active booking'), findsOneWidget);
    expect(find.text('Rex is blocked.'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
