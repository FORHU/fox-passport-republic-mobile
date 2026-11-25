import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a specialty with its main category (api#503)', () {
    final s = ProviderSpecialty.fromJson(const {
      'slug': 'photography',
      'name': 'Photography',
      'group': {
        'slug': 'photo_video',
        'name': 'Photo & Video',
        'icon': 'photo_camera',
      },
    });
    expect(
      s.group,
      const ProviderSpecialtyGroup(
        slug: 'photo_video',
        name: 'Photo & Video',
        icon: 'photo_camera',
      ),
    );
  });

  test('reads one from an older API, or with no main category', () {
    expect(
      ProviderSpecialty.fromJson(const {'slug': 'dj', 'name': 'DJ'}).group,
      isNull,
    );
    expect(
      ProviderSpecialty.fromJson(
        const {'slug': 'dj', 'name': 'DJ', 'group': null},
      ).group,
      isNull,
    );
  });

  test('groups by main category in API order, the ungrouped last', () {
    const photo = ProviderSpecialtyGroup(slug: 'photo_video', name: 'P&V');
    const music = ProviderSpecialtyGroup(slug: 'music', name: 'Music');
    const list = [
      ProviderSpecialty(slug: 'dj', name: 'DJ', group: music),
      ProviderSpecialty(slug: 'kites', name: 'Kites'),
      ProviderSpecialty(slug: 'photography', name: 'Photography', group: photo),
      ProviderSpecialty(slug: 'mc', name: 'MC', group: music),
    ];
    final groups = groupSpecialties(list);
    expect(groups.map((g) => g.$1?.slug), ['music', 'photo_video', null]);
    expect(groups[0].$2.map((s) => s.slug), ['dj', 'mc']);
    expect(groups[2].$2.single.slug, 'kites');
  });
}
