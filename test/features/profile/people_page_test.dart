import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/people_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _FakePeople extends FollowRepository {
  _FakePeople({this.answerFails = false}) : super(_MockApi());

  final bool answerFails;
  final calls = <String>[];
  final lists = <PeopleList, List<Person>>{
    PeopleList.followers: [
      const Person(id: 'f1', name: 'Fern', username: 'fern'),
    ],
    PeopleList.following: [],
    PeopleList.requests: [
      const Person(id: 'r1', name: 'Rex', username: 'rex'),
      const Person(id: 'r2', name: 'Rae'),
    ],
  };

  @override
  Future<List<Person>> people(String userId, PeopleList list) async {
    calls.add('people $userId ${list.name}');
    return lists[list]!;
  }

  @override
  Future<void> answerRequest(String requesterId, {required bool accept}) async {
    calls.add('${accept ? 'accept' : 'decline'} $requesterId');
    if (answerFails) throw const ServerException('No such request');
    if (accept) {
      final asked = lists[PeopleList.requests]!;
      lists[PeopleList.followers]!
          .add(asked.firstWhere((p) => p.id == requesterId));
    }
    lists[PeopleList.requests]!.removeWhere((p) => p.id == requesterId);
  }
}

Future<void> _pump(WidgetTester tester, _FakePeople repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        followRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PeoplePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('followers first, then the other two tabs', (tester) async {
    await _pump(tester, _FakePeople());
    expect(find.text('Fern'), findsOneWidget);
    expect(find.text('@fern'), findsOneWidget);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('You are not following anyone yet.'), findsOneWidget);

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Rae'), findsOneWidget);
  });

  testWidgets('accepting moves the request into followers', (tester) async {
    final repo = _FakePeople();
    await _pump(tester, repo);
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept').first);
    await tester.pumpAndSettle();
    expect(repo.calls, contains('accept r1'));
    expect(find.text('Rex'), findsNothing);

    await tester.tap(find.text('Followers'));
    await tester.pumpAndSettle();
    expect(find.text('Rex'), findsOneWidget);
  });

  testWidgets('declining only removes the request', (tester) async {
    final repo = _FakePeople();
    await _pump(tester, repo);
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Decline').last);
    await tester.pumpAndSettle();
    expect(repo.calls, contains('decline r2'));
    expect(find.text('Rae'), findsNothing);
    expect(find.text('Rex'), findsOneWidget);
  });

  testWidgets('a refused answer keeps the request and says why',
      (tester) async {
    await _pump(tester, _FakePeople(answerFails: true));
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No such request'), findsOneWidget);
    expect(find.text('Rex'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  test('a person is read from the API row', () {
    final p = Person.fromJson({
      'id': 'u',
      'name': ' Ann ',
      'username': null,
      'imgId': '',
    });
    expect(p.name, 'Ann');
    expect(p.username, '');
    expect(p.imageUrl, isNull);
  });
}
