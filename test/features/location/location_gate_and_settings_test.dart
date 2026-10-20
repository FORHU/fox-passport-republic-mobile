import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/location/presentation/pages/location_gate_page.dart';
import 'package:flutter_template/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

class _FakeLocator implements DeviceLocator {
  _FakeLocator(this.result);

  final LocateResult result;
  int asked = 0;

  /// The `prompt` flag of every call; only a tap may ask the user.
  final prompts = <bool>[];

  @override
  Future<LocateResult> locate({bool prompt = true}) async {
    asked++;
    prompts.add(prompt);
    return result;
  }

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async =>
      const DevicePlace(city: 'Davao City');
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u', email: 'me@example.com', name: 'Mia'),
      );
}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.getString(any())).thenReturn(null);
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    when(() => storage.setLocationPromptSeen()).thenAnswer((_) async {});
    when(storage.readUserModel).thenReturn(null);
  });

  Future<void> pumpGate(WidgetTester tester, _FakeLocator locator) async {
    final router = GoRouter(
      initialLocation: RouteNames.location,
      routes: [
        GoRoute(
          path: RouteNames.location,
          builder: (_, __) => const LocationGatePage(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          deviceLocatorProvider.overrideWithValue(locator),
          profileCityProvider.overrideWith((ref) async => 'Baguio'),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks once, explains why, and uses the device when allowed', (
    tester,
  ) async {
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 7.19, lng: 125.45),
    );
    await pumpGate(tester, locator);

    expect(find.text('See what is near you'), findsOneWidget);
    expect(locator.asked, 0, reason: 'nothing is requested until a tap');

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();

    // The area first looks quietly; only the tap opens the permission dialog.
    expect(locator.prompts.where((prompt) => prompt), hasLength(1));
    verify(() => storage.setLocationPromptSeen()).called(1);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('"Not now" still counts as asked and does not locate', (
    tester,
  ) async {
    final locator = _FakeLocator(const LocateResult(LocateOutcome.denied));
    await pumpGate(tester, locator);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(locator.asked, 0);
    verify(() => storage.setLocationPromptSeen()).called(1);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a refusal is explained, then the app carries on',
      (tester) async {
    final locator = _FakeLocator(const LocateResult(LocateOutcome.denied));
    await pumpGate(tester, locator);

    await tester.tap(find.text('Use my location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'Location is off for this app. Turn it on in Settings to use it.',
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 4));
    verify(() => storage.setLocationPromptSeen()).called(1);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('settings shows the area and account, and the area opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          authControllerProvider.overrideWith(_Auth.new),
          deviceLocatorProvider.overrideWithValue(
            _FakeLocator(const LocateResult(LocateOutcome.denied)),
          ),
          profileCityProvider.overrideWith((ref) async => 'Baguio'),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Where you are'), findsOneWidget);
    expect(find.text('Baguio'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Blocked users'), findsOneWidget);

    // Security and sign out are further down the list.
    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Where you are'), -200);

    await tester.tap(find.text('Where you are'));
    await tester.pumpAndSettle();

    expect(find.text('Use my current location'), findsOneWidget);
    expect(find.text('Another city'.toUpperCase()), findsOneWidget);
  });

  testWidgets('settings lets the user pick the currency prices show in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          authControllerProvider.overrideWith(_Auth.new),
          deviceLocatorProvider.overrideWithValue(
            _FakeLocator(const LocateResult(LocateOutcome.denied)),
          ),
          profileCityProvider.overrideWith((ref) async => 'Tokyo'),
          profileLocationProvider.overrideWith(
            (ref) async => const ProfileLocation(
              city: 'Tokyo',
              country: 'Japan',
            ),
          ),
          fxRatesProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Based on the profile's country until the user chooses.
    expect(find.text('JPY · Based on your location'), findsOneWidget);

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Show prices in'), findsOneWidget);
    await tester.tap(find.text('EUR'));
    await tester.pumpAndSettle();

    verify(() => storage.setString('currency.choice', 'EUR')).called(1);
    expect(find.text('EUR'), findsOneWidget);
  });
}
