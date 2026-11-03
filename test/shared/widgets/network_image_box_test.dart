import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeWidthFor', () {
    test('a thumbnail decodes far smaller than a full photo', () {
      final px = decodeWidthFor(width: 52, height: 52, pixelRatio: 2.75);

      expect(px, lessThan(300));
      expect(px, greaterThanOrEqualTo(52 * 2.75));
    });

    test('uses the longer side so a wide photo still covers the box', () {
      expect(
        decodeWidthFor(width: 112, height: 96, pixelRatio: 2),
        decodeWidthFor(width: 112, height: 112, pixelRatio: 2),
      );
    });

    test('works from one known side', () {
      expect(decodeWidthFor(width: 100, height: null, pixelRatio: 2), 360);
      expect(decodeWidthFor(width: null, height: 100, pixelRatio: 2), 360);
    });

    test('keeps the photo its own size when the box has none', () {
      expect(decodeWidthFor(width: null, height: null, pixelRatio: 3), isNull);
      expect(
        decodeWidthFor(
          width: double.infinity,
          height: double.infinity,
          pixelRatio: 3,
        ),
        isNull,
      );
    });

    test('is never absurdly small or large', () {
      expect(decodeWidthFor(width: 8, height: 8, pixelRatio: 1), 64);
      expect(decodeWidthFor(width: 3000, height: 3000, pixelRatio: 3), 2048);
    });
  });
}
