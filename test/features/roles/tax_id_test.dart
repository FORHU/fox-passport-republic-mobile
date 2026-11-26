import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/domain/tax_id.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /locations/countries/:code/tin-formats` bodies, as the API answers
/// (api utils/tax-id-formats).
const Map<String, Object?> phBody = {
  'status': 'success',
  'data': {
    'issuesTin': true,
    'message': 'TIN must look like 123-456-789 or 123-456-789-000',
    'formats': [
      {
        'label': 'TIN',
        'mask': '000-000-000',
        'example': '123-456-789',
        'pattern': r'^(\d\d\d)\-?(\d\d\d)\-?(\d\d\d)$',
        'rule': null,
      },
      {
        'label': 'TIN',
        'mask': '000-000-000-000',
        'example': '123-456-789-000',
        'pattern': r'^(\d\d\d)\-?(\d\d\d)\-?(\d\d\d)\-?(\d\d\d)$',
        'rule': null,
      },
    ],
  },
};

const Map<String, Object?> caBody = {
  'status': 'success',
  'data': {
    'issuesTin': true,
    'message': 'SIN must look like 12345678-9',
    'formats': [
      {
        'label': 'SIN',
        'mask': '00000000-0',
        'example': '12345678-9',
        'pattern': r'^(\d\d\d\d\d\d\d\d)\-?(\d)$',
        'rule': null,
      },
    ],
  },
};

/// A country the API has no rules for gets its catch-all format.
const Map<String, Object?> fallbackBody = {
  'status': 'success',
  'data': {
    'issuesTin': true,
    'message': 'Tax ID must be 4-20 letters or digits',
    'formats': [
      {
        'label': 'Tax ID',
        'mask': '',
        'example': 'Tax ID number',
        'pattern': r'^[A-Z0-9](?:[A-Z0-9]|[-./](?=[A-Z0-9])){3,19}$',
        'rule': null,
      },
    ],
  },
};

void main() {
  group('TinFormats', () {
    test('reads a country and checks numbers as the API does', () {
      final ph = TinFormats.tryParse(phBody)!;
      expect(ph.label, 'TIN');
      expect(ph.example, '123-456-789');
      expect(ph.accepts('123456789'), isTrue);
      expect(ph.accepts('123-456-789-000'), isTrue);
      expect(ph.accepts(' 123 456 789 '), isTrue, reason: 'spaces ignored');
      expect(ph.accepts('12345678'), isFalse);
      expect(ph.accepts('12345678-9'), isFalse);

      final ca = TinFormats.tryParse(caBody)!;
      expect(ca.label, 'SIN');
      expect(ca.accepts('12345678-9'), isTrue);
      expect(ca.accepts('ABC'), isFalse);
    });

    test('a rule narrows the captured groups', () {
      const f = TinFormat(
        label: 'X',
        example: '1A',
        pattern: r'^(\d)([A-Z0-9])$',
        rule: r'^\d[A-Z]$',
      );
      expect(f.accepts('1a'), isTrue, reason: 'uppercased first');
      expect(f.accepts('12'), isFalse);
    });

    test('the catch-all format has no label or example to show', () {
      final any = TinFormats.tryParse(fallbackBody)!;
      expect(any.label, isEmpty);
      expect(any.example, isEmpty);
      expect(any.accepts('AB-1234'), isTrue);
      expect(any.accepts('AB'), isFalse);
    });

    test('a body without formats is not read', () {
      expect(TinFormats.tryParse({'data': <String, Object>{}}), isNull);
      expect(TinFormats.tryParse('nope'), isNull);
    });
  });

  group('taxCountryFor', () {
    const countries = [
      TaxCountry(code: 'CA', name: 'Canada'),
      TaxCountry(code: 'PH', name: 'Philippines'),
    ];

    test('matches the profile country by name or code', () {
      expect(taxCountryFor('Canada', countries), 'CA');
      expect(taxCountryFor('ca', countries), 'CA');
    });

    test('starts on the Philippines when it matches nothing', () {
      expect(taxCountryFor('', countries), 'PH');
      expect(taxCountryFor('Atlantis', countries), 'PH');
    });

    test('reads only rows with a 2-letter code and a name', () {
      expect(
        TaxCountry.tryParse({'code': 'ca', 'name': 'Canada'}),
        const TaxCountry(code: 'CA', name: 'Canada'),
      );
      expect(TaxCountry.tryParse({'code': 'CAN', 'name': 'Canada'}), isNull);
      expect(TaxCountry.tryParse({'code': 'CA', 'name': ''}), isNull);
    });
  });

  test('a Venue application sends its tax country with the number', () {
    const draft = RoleApplicationDraft(
      roleType: 'venueFoxer',
      tinNumber: ' 12345678-9 ',
      tinCountry: 'CA',
    );
    expect(draft.toData()['tinNumber'], '12345678-9');
    expect(draft.toData()['tinCountry'], 'CA');
    expect(
      const RoleApplicationDraft(roleType: 'venueFoxer', tinCountry: 'CA')
          .toData()
          .containsKey('tinCountry'),
      isFalse,
      reason: 'no number, no country',
    );
  });
}
