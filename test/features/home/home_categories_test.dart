import 'package:flutter_template/features/home/domain/home_categories.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_test/flutter_test.dart';

CategorySummary _c(
  String name,
  int count, {
  int venues = 0,
  int services = 0,
  int assets = 0,
}) =>
    CategorySummary(
      name: name,
      count: count,
      isEventCategory: Occasion.fromName(name) != null,
      venues: venues,
      services: services,
      assets: assets,
    );

void main() {
  group('occasionTiles', () {
    test('keeps the built-in order, with no counts, until they arrive', () {
      final tiles = occasionTiles(null);

      expect(
        tiles.map((t) => t.occasion),
        [
          Occasion.birthday,
          Occasion.wedding,
          Occasion.corporate,
          Occasion.social,
          Occasion.other,
        ],
      );
      expect(tiles.every((t) => t.count == null), isTrue);
    });

    test('sorts by count and keeps Other last', () {
      final tiles = occasionTiles([
        _c('wedding', 28),
        _c('birthday', 10),
        _c('other', 99),
        _c('social', 40),
      ]);

      expect(tiles.map((t) => t.occasion).toList(), [
        Occasion.social,
        Occasion.wedding,
        Occasion.birthday,
        Occasion.corporate,
        Occasion.other,
      ]);
      expect(tiles.last.count, 99);
    });

    test('puts what the person last opened first', () {
      final tiles = occasionTiles(
        [_c('birthday', 34), _c('wedding', 28), _c('corporate', 19)],
        preferred: Occasion.corporate,
      );

      expect(tiles.first.occasion, Occasion.corporate);
    });
  });

  group('moreCategories', () {
    test('counts bookable categories that are not occasions', () {
      expect(
        moreCategories([
          _c('birthday', 34),
          _c('photography', 15, services: 15),
          _c('dj', 9, services: 9),
          _c('garden', 0),
        ]),
        2,
      );
      expect(moreCategories(null), 0);
    });
  });

  group('singleBookings', () {
    test('lists venues first, then the busiest services and gear', () {
      final rows = singleBookings([
        _c('birthday', 34, venues: 20),
        _c('garden', 5, venues: 5),
        _c('dj', 9, services: 9),
        _c('photography', 15, services: 15),
        _c('sound_system', 11, assets: 11),
        _c('decorations', 0),
      ]);

      expect(rows.map((r) => r.category).toList(), [
        'venues',
        'photography',
        'sound_system',
        'dj',
      ]);
      expect(rows.first.kind, CatalogKind.venues);
      expect(rows[2].kind, CatalogKind.gear);
      expect(rows[1].kind, CatalogKind.services);
    });

    test('is empty with nothing to book', () {
      expect(singleBookings(null), isEmpty);
      expect(singleBookings([_c('birthday', 0)]), isEmpty);
    });
  });
}
