import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:flutter_template/features/reviews/presentation/widgets/write_review_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/reviews/review.dart';
import 'package:flutter_template/shared/reviews/reviews_repository.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReviews implements ReviewsRepository {
  _FakeReviews(this.summary);

  final ReviewSummary summary;
  final created = <Map<String, Object>>[];

  @override
  Future<ReviewSummary> forListing(String listingId) async => summary;

  @override
  Future<void> create({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async =>
      created.add({
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      });
}

Widget _app(ReviewsRepository repo, Widget home) => ProviderScope(
      overrides: [reviewsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: home)),
      ),
    );

void main() {
  test('reads the API shape: stars as numbers, percentages as strings', () {
    final summary = ReviewSummary.fromJson(const {
      'reviews': [
        {
          'id': '1',
          'rating': 5,
          'comment': ' Lovely ',
          'createdAt': '2026-09-12T10:00:00.000Z',
          'user': {'name': 'Maria', 'imgId': null},
          'replies': [
            {
              'text': 'Thanks',
              'user': {'name': 'Host'},
            },
          ],
        },
        {
          'id': '2',
          'rating': 3,
          'user': {'name': 'Jon'},
        },
      ],
      'ratingDistribution': {'5': '50%', '3': '50%'},
    });

    expect(summary.count, 2);
    expect(summary.average, 4);
    expect(summary.percentByStar[5], 50);
    expect(summary.reviews.first.comment, 'Lovely');
    expect(summary.reviews.first.replies.single.author, 'Host');
    expect(summary.reviews.last.comment, isNull);
  });

  test('a ticket remembers whether it was reviewed', () {
    final t = Ticket.fromBooking(const {
      'id': 'b1',
      'status': 'completed',
      'startAt': '2026-01-01T10:00:00.000Z',
      'endAt': '2026-01-01T12:00:00.000Z',
      'hasReview': true,
    });
    expect(t.hasReview, isTrue);
  });

  testWidgets('shows the stars, the reviews and a host reply', (tester) async {
    final repo = _FakeReviews(
      ReviewSummary.fromJson(const {
        'reviews': [
          {
            'id': '1',
            'rating': 5,
            'comment': 'Beautiful space',
            'user': {'name': 'Maria'},
            'replies': [
              {
                'text': 'Thank you!',
                'user': {'name': 'Host'},
              },
            ],
          },
        ],
        'ratingDistribution': {'5': '100%'},
      }),
    );
    await tester.pumpWidget(_app(repo, const ReviewsSection(listingId: 'v1')));
    await tester.pumpAndSettle();

    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('1 review'), findsOneWidget);
    expect(find.text('Beautiful space'), findsOneWidget);
    expect(find.text('Thank you!'), findsOneWidget);
  });

  testWidgets('says so when there are no reviews', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeReviews(ReviewSummary.empty),
        const ReviewsSection(listingId: 'v1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reviews yet.'), findsOneWidget);
  });

  testWidgets('posting needs a star, then sends the booking and note', (
    tester,
  ) async {
    final repo = _FakeReviews(ReviewSummary.empty);
    bool? result;
    await tester.pumpWidget(
      _app(
        repo,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showWriteReviewSheet(
              context,
              bookingId: 'b1',
              title: 'Sky Hall',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post review'));
    await tester.pump();
    expect(find.text('Choose a star rating.'), findsOneWidget);
    expect(repo.created, isEmpty);

    await tester.tap(find.byTooltip('4'));
    await tester.enterText(find.byType(TextField), 'Loved it');
    await tester.tap(find.text('Post review'));
    await tester.pumpAndSettle();

    expect(repo.created.single, {
      'bookingId': 'b1',
      'rating': 4,
      'comment': 'Loved it',
    });
    expect(result, isTrue);
  });
}
