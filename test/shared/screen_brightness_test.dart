import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/screen/screen_brightness_boost.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what would have happened to the screen.
class _Recorder implements BrightnessBackend {
  final calls = <String>[];
  bool failing = false;

  @override
  Future<void> raise() async {
    calls.add('raise');
    if (failing) throw UnimplementedError('no plugin here');
  }

  @override
  Future<void> restore() async {
    calls.add('restore');
    if (failing) throw UnimplementedError('no plugin here');
  }
}

Ticket _ticket({
  String id = 'b1',
  String status = 'confirmed',
  bool sample = false,
}) =>
    Ticket(
      id: id,
      eventName: 'Sky Hall',
      startAt: DateTime.now().add(const Duration(days: 5)),
      endAt: DateTime.now().add(const Duration(days: 5, hours: 5)),
      status: status,
      ticketCode: 'FXP-$id',
      isSample: sample,
    );

Widget _app(Widget body) => ProviderScope(
      overrides: [
        displayCurrencyProvider.overrideWithValue('PHP'),
        fxRatesProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    );

void _bigScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 3200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late _Recorder screen;

  setUp(() {
    screen = _Recorder();
    ScreenBrightnessBoost.backend = screen;
  });

  group('ScreenBrightnessBoost', () {
    test('raises on the first holder and restores after the last', () async {
      ScreenBrightnessBoost.acquire();
      ScreenBrightnessBoost.acquire();
      expect(screen.calls, ['raise']);

      ScreenBrightnessBoost.release();
      expect(screen.calls, ['raise']);

      ScreenBrightnessBoost.release();
      expect(screen.calls, ['raise', 'restore']);
    });

    test('an extra release does nothing', () {
      ScreenBrightnessBoost.release();
      expect(screen.calls, isEmpty);
    });

    test('a device that cannot change brightness is not an error', () async {
      screen.failing = true;
      ScreenBrightnessBoost.acquire();
      ScreenBrightnessBoost.release();
      await Future<void>.delayed(Duration.zero);

      expect(screen.calls, ['raise', 'restore']);
    });
  });

  group('ticket QR', () {
    testWidgets('turns the screen up while a real QR shows, then back down', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(_app(TicketCard(ticket: _ticket())));
      await tester.pump();
      expect(screen.calls, ['raise']);

      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump();
      expect(screen.calls, ['raise', 'restore']);
    });

    testWidgets('several QRs raise once and restore when the last is gone', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              TicketCard(ticket: _ticket()),
              TicketCard(ticket: _ticket(id: 'b2')),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(screen.calls, ['raise']);

      await tester.pumpWidget(
        _app(Column(children: [TicketCard(ticket: _ticket())])),
      );
      await tester.pump();
      expect(screen.calls, ['raise']);

      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump();
      expect(screen.calls, ['raise', 'restore']);
    });

    testWidgets('a cancelled booking and the sample ticket do not', (
      tester,
    ) async {
      _bigScreen(tester);
      for (final ticket in [
        _ticket(status: 'cancelled'),
        _ticket(status: 'pending'),
        _ticket(sample: true),
      ]) {
        await tester.pumpWidget(_app(TicketCard(ticket: ticket)));
        await tester.pump();
      }

      expect(screen.calls, isEmpty);
    });

    testWidgets('a QR on a tab nobody is looking at lets go', (tester) async {
      _bigScreen(tester);
      // How an inactive tab is held in the shell: still built, tickers off.
      Widget tab({required bool active}) => _app(
            TickerMode(
              enabled: active,
              child: TicketCard(ticket: _ticket()),
            ),
          );

      await tester.pumpWidget(tab(active: true));
      await tester.pump();
      expect(screen.calls, ['raise']);

      await tester.pumpWidget(tab(active: false));
      await tester.pump();
      expect(screen.calls, ['raise', 'restore']);

      await tester.pumpWidget(tab(active: true));
      await tester.pump();
      expect(screen.calls, ['raise', 'restore', 'raise']);
    });
  });
}
