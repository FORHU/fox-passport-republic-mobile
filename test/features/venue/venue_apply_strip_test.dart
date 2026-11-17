import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/venue/presentation/widgets/venue_apply_strip.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Partner _partner(PartnerStatus status, {bool applied = true}) => Partner(
      id: 'p1',
      venueId: 'v1',
      venueName: 'averie',
      partnerId: 'u1',
      partnerName: 'Rosa',
      status: status,
      startedByEventFoxer: applied,
      side: PartnerSide.eventFoxer,
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<String> roles,
  List<Partner> partners = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        heldRolesProvider.overrideWithValue(roles),
        partnersProvider.overrideWith(
          (ref) async => PartnerLists(asEventFoxer: partners),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VenueApplyStrip(venueId: 'v1', venueName: 'averie'),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  const apply = 'Apply to host events here';

  testWidgets('shows nothing to someone who is not an Event Foxer', (
    tester,
  ) async {
    await _pump(tester, roles: const ['citizen']);
    expect(find.text(apply), findsNothing);
  });

  testWidgets('an Event Foxer who has not applied can apply', (tester) async {
    await _pump(tester, roles: const ['eventFoxer']);
    expect(find.text(apply), findsOneWidget);
  });

  testWidgets('after applying, it says so and offers no second apply', (
    tester,
  ) async {
    await _pump(
      tester,
      roles: const ['eventFoxer'],
      partners: [_partner(PartnerStatus.pending)],
    );
    expect(find.text('You applied to host at averie'), findsOneWidget);
    expect(find.text(apply), findsNothing);
  });

  testWidgets('an approved partner is told they host there', (tester) async {
    await _pump(
      tester,
      roles: const ['eventFoxer'],
      partners: [_partner(PartnerStatus.approved)],
    );
    expect(find.text('You host events here'), findsOneWidget);
    expect(find.text(apply), findsNothing);
  });

  testWidgets('a declined application shows as declined', (tester) async {
    await _pump(
      tester,
      roles: const ['eventFoxer'],
      partners: [_partner(PartnerStatus.rejected)],
    );
    expect(find.text('Declined'), findsOneWidget);
    expect(find.text(apply), findsNothing);
  });
}
