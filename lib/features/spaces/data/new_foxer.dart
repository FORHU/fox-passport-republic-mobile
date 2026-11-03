import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';

/// A space a Foxer works in, for telling whether they are new to it.
enum NewFoxerSpace { venue, event, gear, services }

/// Whether the Foxer is new to [NewFoxerSpace]: nothing of theirs is live and
/// nothing has been earned or is on its way yet. The getting-started card and
/// the first-time tour show only while this is true. A failed load counts as
/// not new, so a hiccup never throws a tour at an established Foxer.
// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final newFoxerProvider =
    FutureProvider.autoDispose.family<bool, NewFoxerSpace>((ref, space) async {
  try {
    final listings = await ref.watch(
      switch (space) {
        NewFoxerSpace.venue => myVenuesProvider,
        NewFoxerSpace.event => myEventsProvider,
        NewFoxerSpace.gear => myAssetsProvider,
        NewFoxerSpace.services => myServicesProvider,
      }
          .future,
    );
    if (listings.any((l) => l.group == 'live')) return false;
    final payouts = await ref.watch(payoutsProvider.future);
    return payouts.rows.isEmpty &&
        payouts.totals.paid == 0 &&
        payouts.totals.pending == 0;
  } on Object {
    return false;
  }
});
