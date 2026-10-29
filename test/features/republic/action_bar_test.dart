import 'package:flutter/material.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

final _post = Post.fromJson(const {
  'id': 'p1',
  'content': 'Hello',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'author': {'id': 'u', 'name': 'Maria'},
});

void main() {
  // Three equal buttons share the width. "Comments" used to wrap onto two
  // lines ("Commen" / "ts") on a 360-wide phone.
  for (final (width, textScale) in [(360.0, 1.0), (360.0, 1.3), (320.0, 1.3)]) {
    testWidgets(
        'Like, Comments and Share stay on one line at $width wide, '
        '${textScale}x text', (tester) async {
      tester.view
        ..physicalSize = Size(width, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCard(
                post: _post,
                onLike: () {},
                onComments: () {},
                onShare: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final label in ['Like', 'Comments', 'Share']) {
        final box = tester.getRect(find.text(label));
        // One line of body text is under 30 logical pixels tall even at
        // 1.3x; two lines would be about double.
        expect(box.height, lessThan(30), reason: '$label wrapped');
        expect(box.left, greaterThanOrEqualTo(0), reason: label);
        expect(box.right, lessThanOrEqualTo(width), reason: label);
      }
    });
  }

  testWidgets('tapping the author opens their profile', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: _post,
              onLike: () {},
              onComments: () {},
              onAuthor: () => opened++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Maria'));
    await tester.tap(find.byType(AuthorAvatar));

    expect(opened, 2);
  });
}
