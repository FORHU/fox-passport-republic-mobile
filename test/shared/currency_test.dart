import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockApi extends Mock implements ApiService {}

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u', email: 'u@example.com', name: 'U'),
      );
}

const _rates = FxRates(
  base: 'PHP',
  rates: {'PHP': 1, 'USD': 0.02, 'EUR': 0.018},
);

void main() {
  group('convertCurrency', () {
    test('converts through the base currency', () {
      expect(convertCurrency(25000, 'PHP', 'USD', _rates), 500);
      expect(convertCurrency(500, 'USD', 'PHP', _rates), 25000);
      expect(convertCurrency(1, 'USD', 'EUR', _rates), closeTo(0.9, 1e-9));
    });

    test('leaves the amount alone with no rate', () {
      expect(convertCurrency(100, 'PHP', 'USD', null), 100);
      expect(convertCurrency(100, 'PHP', 'XYZ', _rates), 100);
      expect(convertCurrency(100, 'PHP', 'PHP', _rates), 100);
    });
  });

  group('MoneyFormatter', () {
    test('shows the converted amount in the chosen currency', () {
      const f = MoneyFormatter(currency: 'USD', rates: _rates);
      expect(f.format(25000, 'PHP', locale: 'en'), r'$500');
      expect(f.converts('PHP'), isTrue);
    });

    test('keeps the original currency when there is no rate', () {
      const f = MoneyFormatter(currency: 'USD');
      expect(f.format(25000, 'PHP', locale: 'en'), '₱25,000');
      expect(f.converts('PHP'), isFalse);
    });
  });

  group('currencyForCountry', () {
    test('reads ISO codes and English names', () {
      expect(currencyForCountry('PH'), 'PHP');
      expect(currencyForCountry('us'), 'USD');
      expect(currencyForCountry('Japan'), 'JPY');
      expect(currencyForCountry('Germany'), 'EUR');
      expect(currencyForCountry('FR'), 'EUR');
    });

    test('is null for a country with no supported currency', () {
      expect(currencyForCountry('BR'), isNull);
      expect(currencyForCountry(''), isNull);
      expect(currencyForCountry(null), isNull);
    });
  });

  group('displayCurrencyProvider', () {
    late _MockStorage storage;
    late _MockApi api;

    setUp(() {
      storage = _MockStorage();
      api = _MockApi();
      when(() => storage.getString(any())).thenReturn(null);
      when(() => storage.setString(any(), any())).thenAnswer((_) async {});
      when(() => storage.remove(any())).thenAnswer((_) async {});
      when(() => api.put(any(), any())).thenAnswer((_) async => {});
    });

    ProviderContainer make({ProfileLocation? profile, Area? area}) {
      final c = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          apiServiceProvider.overrideWithValue(api),
          authControllerProvider.overrideWith(_SignedIn.new),
          profileLocationProvider
              .overrideWith((ref) async => profile ?? const ProfileLocation()),
          fxRatesProvider.overrideWith((ref) async => _rates),
          if (area != null) areaProvider.overrideWith(() => _FixedArea(area)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('falls back to the platform currency with nothing known', () async {
      final c = make();
      await c.read(profileLocationProvider.future);
      expect(c.read(displayCurrencyProvider), 'PHP');
    });

    test('follows the country on the profile', () async {
      final c = make(profile: const ProfileLocation(country: 'United States'));
      await c.read(profileLocationProvider.future);
      expect(c.read(displayCurrencyProvider), 'USD');
    });

    test('follows the device country when the device is shared', () async {
      final c = make(
        profile: const ProfileLocation(country: 'Philippines'),
        area: const Area(
          source: AreaSource.device,
          lat: 1,
          lng: 2,
          deviceCountry: 'JP',
        ),
      );
      await c.read(profileLocationProvider.future);
      expect(c.read(displayCurrencyProvider), 'JPY');
    });

    test('a non-default account currency beats the location', () async {
      final c = make(
        profile: const ProfileLocation(
          country: 'Philippines',
          preferredCurrency: 'EUR',
        ),
      );
      await c.read(profileLocationProvider.future);
      expect(c.read(displayCurrencyProvider), 'EUR');
    });

    test('the account default (PHP) does not hide the location', () async {
      final c = make(
        profile: const ProfileLocation(
          country: 'Japan',
          preferredCurrency: 'PHP',
        ),
      );
      await c.read(profileLocationProvider.future);
      expect(c.read(displayCurrencyProvider), 'JPY');
    });

    test('an explicit choice wins, is saved, and can be undone', () async {
      final c = make(profile: const ProfileLocation(country: 'Japan'));
      await c.read(profileLocationProvider.future);

      await c.read(currencyChoiceProvider.notifier).choose('GBP');

      expect(c.read(displayCurrencyProvider), 'GBP');
      verify(() => storage.setString('currency.choice', 'GBP')).called(1);
      verify(
        () => api.put(ApiEndpoints.profile, {'preferredCurrency': 'GBP'}),
      ).called(1);

      await c.read(currencyChoiceProvider.notifier).useAutomatic();

      expect(c.read(displayCurrencyProvider), 'JPY');
      verify(() => storage.remove('currency.choice')).called(1);
    });

    test('the formatter converts with the fetched rates', () async {
      final c = make(profile: const ProfileLocation(country: 'US'));
      await c.read(profileLocationProvider.future);
      await c.read(fxRatesProvider.future);

      final money = c.read(moneyFormatterProvider);

      expect(money.format(25000, 'PHP', locale: 'en'), r'$500');
    });
  });
}

class _FixedArea extends AreaController {
  _FixedArea(this._area);

  final Area _area;

  @override
  Area build() => _area;
}
