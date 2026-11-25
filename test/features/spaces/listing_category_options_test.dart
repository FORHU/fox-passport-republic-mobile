import 'package:flutter_template/features/spaces/domain/listing_draft.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo =
    ProviderSpecialtyGroup(slug: 'photo_video', name: 'Photo & Video');
const _rentals = ProviderSpecialtyGroup(slug: 'rentals', name: 'Rentals');
const _catalog = [
  ProviderSpecialty(
    slug: 'photo_booth',
    name: 'Photo booth',
    group: _photo,
    listingKind: 'service',
  ),
  ProviderSpecialty(
    slug: 'photography',
    name: 'Photography',
    group: _photo,
    listingKind: 'service',
  ),
  ProviderSpecialty(
    slug: 'tents',
    name: 'Tents',
    group: _rentals,
    listingKind: 'asset',
  ),
  // Approved, but no listing can carry it yet.
  ProviderSpecialty(slug: 'kites', name: 'Kites'),
];

void main() {
  test('a service offers the catalog services, then other', () {
    expect(
      listingCategoryOptions(gear: false, catalog: _catalog),
      ['photo_booth', 'photography', 'other'],
    );
  });

  test('gear offers the catalog gear, then other', () {
    expect(
      listingCategoryOptions(gear: true, catalog: _catalog),
      ['tents', 'other'],
    );
  });

  test('an older API, or no catalog, gets the fixed lists', () {
    const old = [ProviderSpecialty(slug: 'dj', name: 'DJ')];
    expect(
      listingCategoryOptions(gear: false, catalog: old),
      serviceCategories,
    );
    expect(listingCategoryOptions(gear: true), gearCategories);
  });

  test("keeps an existing listing's category", () {
    expect(
      listingCategoryOptions(
        gear: false,
        catalog: _catalog,
        current: 'entertainment',
      ).first,
      'entertainment',
    );
    expect(
      listingCategoryOptions(gear: false, catalog: _catalog, current: 'other'),
      ['photo_booth', 'photography', 'other'],
    );
  });

  test('names a subcategory with its main category', () {
    expect(_catalog.first.fullName, 'Photo & Video · Photo booth');
    expect(_catalog.last.fullName, 'Kites');
  });
}
