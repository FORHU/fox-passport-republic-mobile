import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('with no picture it shows the fallback', (tester) async {
    for (final url in <String?>[null, '']) {
      await tester.pumpWidget(
        _app(AvatarImage(url: url, radius: 20, fallback: const Text('A'))),
      );

      expect(find.text('A'), findsOneWidget, reason: 'url: "$url"');
      expect(find.byType(NetworkImageBox), findsNothing);
    }
  });

  testWidgets('with a picture it loads through the shared loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const AvatarImage(
          url: 'https://example.com/a.png',
          radius: 20,
          fallback: Text('A'),
        ),
      ),
    );

    final box = tester.widget<NetworkImageBox>(find.byType(NetworkImageBox));
    expect(box.url, 'https://example.com/a.png');
    // Sized to the circle, so it never decodes bigger than it is drawn.
    expect(box.width, 40);
    expect(box.height, 40);
    expect(find.text('A'), findsNothing);
  });
}
