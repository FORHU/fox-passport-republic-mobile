import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only Already booked is sent as busy', () {
    expect(BookingDeclineReason.alreadyBooked.cause, DeclineCause.busy);
    expect(BookingDeclineReason.closed.cause, DeclineCause.other);
    expect(BookingDeclineReason.notSuitable.cause, DeclineCause.other);
    expect(BookingDeclineReason.other.cause, DeclineCause.other);
  });

  test('Already booked and Closed block the day unless changed', () {
    expect(BookingDeclineReason.alreadyBooked.blocksDayByDefault, isTrue);
    expect(BookingDeclineReason.closed.blocksDayByDefault, isTrue);
    expect(BookingDeclineReason.notSuitable.blocksDayByDefault, isFalse);
    expect(BookingDeclineReason.other.blocksDayByDefault, isFalse);
  });

  test('a venue request keeps its venue id; gear does not', () {
    final row = {
      'id': 'r1',
      'status': 'pending_provider_confirmation',
      'venueId': 'v1',
      'event': {'name': 'Ada Birthday'},
      'venue': {'name': 'Sky Hall'},
    };
    expect(VenueRequest.tryParse(row)?.venueId, 'v1');
    expect(
      VenueRequest.tryParse(
        {
          ...row,
          'asset': {'name': 'Speakers'},
        },
        kind: RequestKind.asset,
      )?.venueId,
      isNull,
    );
  });
}
