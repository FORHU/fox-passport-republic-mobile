import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';

/// One round icon in "Or book just one thing".
class SingleBooking {
  const SingleBooking({
    required this.category,
    required this.kind,
    required this.count,
  });

  /// `venues`, or a service / gear category name such as `photography`.
  final String category;

  /// Which Search switch it opens on.
  final CatalogKind kind;
  final int count;
}

/// One occasion tile, with how many ideas there are (null while unknown).
class OccasionTileData {
  const OccasionTileData({required this.occasion, this.count});

  final Occasion occasion;
  final int? count;
}

/// The five occasions, most to least bookable. Without counts (still
/// loading, or the call failed) they keep their built-in order, so the grid
/// is drawn at once and does not reshuffle when numbers arrive for the same
/// data. [preferred] (what the person last opened) goes first when known.
List<OccasionTileData> occasionTiles(
  List<CategorySummary>? categories, {
  Occasion? preferred,
}) {
  final counts = <Occasion, int>{};
  for (final c in categories ?? const <CategorySummary>[]) {
    final occasion = Occasion.fromName(c.name);
    if (occasion != null) counts[occasion] = c.count;
  }

  final tiles = [
    for (final o in Occasion.values)
      OccasionTileData(
        occasion: o,
        count: categories == null ? null : counts[o] ?? 0,
      ),
  ];

  if (categories != null) {
    // Stable sort: ties keep the built-in order. "Other" stays last.
    tiles.sort((a, b) {
      if (a.occasion == Occasion.other) {
        return b.occasion == Occasion.other ? 0 : 1;
      }
      if (b.occasion == Occasion.other) return -1;
      return (b.count ?? 0).compareTo(a.count ?? 0);
    });
  }

  if (preferred != null && preferred != Occasion.other) {
    final i = tiles.indexWhere((t) => t.occasion == preferred);
    if (i > 0) tiles.insert(0, tiles.removeAt(i));
  }
  return tiles;
}

/// How many bookable categories sit behind the "All" tile: every category
/// with something in it that is not one of the five occasions.
int moreCategories(List<CategorySummary>? categories) {
  if (categories == null) return 0;
  return categories
      .where((c) => c.count > 0 && Occasion.fromName(c.name) == null)
      .length;
}

/// The single bookings to offer: Venues first, then the service and gear
/// categories with the most listings. A category with nothing is left out.
List<SingleBooking> singleBookings(
  List<CategorySummary>? categories, {
  int limit = 5,
}) {
  if (categories == null) return const [];

  final venues = categories.fold<int>(0, (sum, c) => sum + c.venues);
  final rows = <SingleBooking>[];
  for (final c in categories) {
    // The five occasions are planned above, and "other" says nothing.
    if (Occasion.fromName(c.name) != null) continue;
    if (c.services >= c.assets && c.services > 0) {
      rows.add(
        SingleBooking(
          category: c.name,
          kind: CatalogKind.services,
          count: c.services,
        ),
      );
    } else if (c.assets > 0) {
      rows.add(
        SingleBooking(
          category: c.name,
          kind: CatalogKind.gear,
          count: c.assets,
        ),
      );
    }
  }
  rows.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : a.category.compareTo(b.category);
  });

  return [
    if (venues > 0)
      SingleBooking(
        category: 'venues',
        kind: CatalogKind.venues,
        count: venues,
      ),
    ...rows,
  ].take(limit).toList();
}
