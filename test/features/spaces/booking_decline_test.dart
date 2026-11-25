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

  test('reasons read and write the API spelling', () {
    expect(
      BookingDeclineReason.values.map((r) => r.apiValue),
      ['already_booked', 'closed', 'not_suitable', 'other'],
    );
    for (final r in BookingDeclineReason.values) {
      expect(BookingDeclineReason.parse(r.apiValue), r);
    }
    expect(BookingDeclineReason.parse('too_far'), isNull);
    expect(BookingDeclineReason.parse(null), isNull);
  });

  test('only Something else needs a note', () {
    expect(
      BookingDeclineReason.values.where((r) => r.needsNote),
      [BookingDeclineReason.other],
    );
  });

  test('sends the reason, and the note only when one was typed', () {
    expect(
      const BookingDecline(reason: BookingDeclineReason.closed).body,
      {'reason': 'closed'},
    );
    expect(
      const BookingDecline(reason: BookingDeclineReason.closed, note: '   ')
          .body,
      {'reason': 'closed'},
    );
    expect(
      const BookingDecline(
        reason: BookingDeclineReason.other,
        note: '  Private party ',
      ).body,
      {'reason': 'other', 'note': 'Private party'},
    );
  });

  test("a booked Supplier carries its reason and note; an older API's doesn't",
      () {
    Map<String, Object?> event(Map<String, Object?> supplier) => {
          'eventId': 'e1',
          'eventName': 'Garden wedding',
          'suppliers': [
            {
              'kind': 'venue',
              'transactionId': 't1',
              'supplierName': 'Sky Hall',
              'itemName': 'Sky Hall',
              'status': 'rejected',
              'reason': 'declined',
              ...supplier,
            },
          ],
        };
    final withReason = BookedEvent.tryParse(
      event({'declineReason': 'closed', 'declineNote': ' Repairs '}),
    )!
        .suppliers
        .single;
    expect(withReason.declineReason, BookingDeclineReason.closed);
    expect(withReason.declineNote, 'Repairs');

    final old = BookedEvent.tryParse(event({}))!.suppliers.single;
    expect(old.declineReason, isNull);
    expect(old.declineNote, isNull);
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
