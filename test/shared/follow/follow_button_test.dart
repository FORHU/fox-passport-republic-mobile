import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/follow/follow_button.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

/// Answers the follow calls from a script and remembers what was asked.
class _FakeFollows extends FollowRepository {
  _FakeFollows({
    this.current = const FollowStatus(followers: 4),
    this.answer = FollowState.following,
    this.fails = false,
  }) : super(_MockApi());

  FollowStatus current;
  final FollowState answer;
  final bool fails;
  final calls = <String>[];

  @override
  Future<FollowStatus> status(String userId) async {
    calls.add('status $userId');
    return current;
  }

  @override
  Future<FollowState> follow(String userId) async {
    calls.add('follow $userId');
    if (fails) throw const ServerException('Cannot follow yourself');
    return answer;
  }

  @override
  Future<void> unfollow(String userId) async {
    calls.add('unfollow $userId');
    if (fails) throw const ServerException('Nope');
  }
}

Future<void> _pump(WidgetTester tester, _FakeFollows follows) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        followRepositoryProvider.overrideWithValue(follows),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FollowButton(userId: 'u1')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('FollowStatus', () {
    test('reads what the API sends', () {
      final s = FollowStatus.fromJson(
        {'status': 'accepted', 'direction': 'outgoing'},
        {'followers': 7, 'following': 2},
      );
      expect(s.state, FollowState.following);
      expect(s.followers, 7);
    });

    test('them following you is not you following them', () {
      final s = FollowStatus.fromJson(
        {'status': 'accepted', 'direction': 'incoming'},
        null,
      );
      expect(s.state, FollowState.none);
      expect(s.followers, isNull);
    });

    test('a request waiting for a private account is pending', () {
      final s = FollowStatus.fromJson(
        {'status': 'pending', 'direction': 'outgoing'},
        null,
      );
      expect(s.state, FollowState.pending);
    });

    test('only an accepted follow moves the count', () {
      const s = FollowStatus(followers: 4);
      expect(s.after(FollowState.following).followers, 5);
      expect(s.after(FollowState.pending).followers, 4);
      expect(
        s.after(FollowState.following).after(FollowState.none).followers,
        4,
      );
    });
  });

  group('FollowButton', () {
    testWidgets('follows, shows Following and counts one more', (tester) async {
      final follows = _FakeFollows();
      await _pump(tester, follows);
      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('4 followers'), findsOneWidget);

      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      expect(follows.calls, ['status u1', 'follow u1']);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('5 followers'), findsOneWidget);
    });

    testWidgets('a private account shows Requested and says so',
        (tester) async {
      await _pump(tester, _FakeFollows(answer: FollowState.pending));

      await tester.tap(find.text('Follow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Follow request sent.'), findsOneWidget);
      expect(find.text('4 followers'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('tapping Following unfollows', (tester) async {
      final follows = _FakeFollows(
        current: const FollowStatus(
          state: FollowState.following,
          followers: 4,
        ),
      );
      await _pump(tester, follows);

      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();

      expect(follows.calls.last, 'unfollow u1');
      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('3 followers'), findsOneWidget);
    });

    testWidgets('a refusal keeps the button as it was and says why',
        (tester) async {
      await _pump(tester, _FakeFollows(fails: true));

      await tester.tap(find.text('Follow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cannot follow yourself'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('no numbers when the account keeps them private',
        (tester) async {
      await _pump(tester, _FakeFollows(current: const FollowStatus()));
      expect(find.textContaining('follower'), findsNothing);
    });
  });
}
