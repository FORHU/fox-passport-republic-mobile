import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/events/event_package.dart';

export 'package:flutter_template/shared/payments/payments_repository.dart'
    show PaymentsUnavailable;

/// What the user has chosen so far in the venue booking flow.
class BookingSelection extends Equatable {
  const BookingSelection({
    required this.venue,
    this.date,
    this.endDate,
    this.guests = 1,
    this.notes = '',
    this.voucherCode = '',
    this.package,
    this.excluded = const {},
  });

  /// The venue being booked, or the event when [package] is set.
  final CatalogItem venue;

  /// Set when an event package is being booked rather than a venue.
  final EventPackage? package;

  /// Optional items of [package] the citizen left out.
  final Set<String> excluded;

  /// The first day booked, as a calendar date with no time of day.
  final DateTime? date;

  /// The last day of a venue booked for several days; null for a single day.
  final DateTime? endDate;
  final int guests;
  final String notes;
  final String voucherCode;

  /// Guests beyond what the venue holds. They need the owner's approval.
  int get overCapacity {
    // An event has its own attendee limit and takes no over-capacity requests.
    if (package != null) return 0;
    final capacity = venue.capacity;
    if (capacity == null) return 0;
    return guests > capacity ? guests - capacity : 0;
  }

  bool get isOverCapacity => overCapacity > 0;

  /// The last day booked: [endDate], or [date] for a single day.
  DateTime? get lastDate => endDate ?? date;

  /// How many days are booked, at least one.
  int get days {
    final first = date;
    final last = lastDate;
    if (first == null || last == null) return 1;
    // Through UTC, so a daylight-saving change cannot skew the count.
    final span = DateTime.utc(last.year, last.month, last.day)
        .difference(DateTime.utc(first.year, first.month, first.day))
        .inDays;
    return span + 1;
  }

  /// The start of the first day, in the user's local time, as the web app
  /// sends it.
  DateTime? get startAt =>
      date == null ? null : DateTime(date!.year, date!.month, date!.day);

  /// The end of the last day.
  DateTime? get endAt {
    final last = lastDate;
    return last == null
        ? null
        : DateTime(last.year, last.month, last.day, 23, 59, 59);
  }

  BookingSelection copyWith({
    DateTime? date,
    DateTime? endDate,
    bool clearEndDate = false,
    int? guests,
    String? notes,
    String? voucherCode,
  }) =>
      BookingSelection(
        venue: venue,
        date: date ?? this.date,
        endDate: clearEndDate ? null : endDate ?? this.endDate,
        guests: guests ?? this.guests,
        notes: notes ?? this.notes,
        voucherCode: voucherCode ?? this.voucherCode,
        package: package,
        excluded: excluded,
      );

  @override
  List<Object?> get props =>
      [venue, date, endDate, guests, notes, voucherCode, package, excluded];
}

/// The price of a booking as the API works it out. The app never computes the
/// service fee itself; [VenuePricing.estimate] exists only for sample venues.
class VenuePricing extends Equatable {
  const VenuePricing({
    required this.itemsTotal,
    required this.platformFeeAmount,
    required this.totalAmount,
    this.discountAmount = 0,
    this.needsApproval = false,
    this.extraGuests = 0,
    this.days = 1,
    this.isSample = false,
  });

  factory VenuePricing.fromJson(Map<String, dynamic> json, {int days = 1}) {
    num n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
    return VenuePricing(
      itemsTotal: n(json['itemsTotal']),
      discountAmount: n(json['discountAmount']),
      platformFeeAmount: n(json['platformFeeAmount']),
      totalAmount: n(json['totalAmount']),
      needsApproval: json['needsApproval'] == true,
      extraGuests: n(json['extraGuests']).toInt(),
      days: days,
    );
  }

  /// A stand-in for sample venues, flagged so the screen says so.
  factory VenuePricing.estimate({
    required num rate,
    required int guests,
    required int? capacity,
    int days = 1,
  }) {
    final items = rate * days;
    final fee = (items * 0.05).roundToDouble();
    return VenuePricing(
      itemsTotal: items,
      platformFeeAmount: fee,
      totalAmount: items + fee,
      needsApproval: capacity != null && guests > capacity,
      extraGuests: capacity == null ? 0 : (guests - capacity).clamp(0, guests),
      days: days,
      isSample: true,
    );
  }

  final num itemsTotal;
  final num discountAmount;
  final num platformFeeAmount;
  final num totalAmount;
  final bool needsApproval;
  final int extraGuests;
  final int days;
  final bool isSample;

  @override
  List<Object?> get props => [
        itemsTotal,
        discountAmount,
        platformFeeAmount,
        totalAmount,
        needsApproval,
        extraGuests,
        days,
        isSample,
      ];
}

/// A booking the API (or the sample path) created.
class BookingReceipt extends Equatable {
  const BookingReceipt({
    required this.id,
    required this.reference,
    required this.totalAmount,
    required this.currency,
    required this.needsApproval,
    this.isSample = false,
  });

  final String id;

  /// The ticket code shown to the user.
  final String reference;
  final num totalAmount;
  final String currency;

  /// True when the owner has to approve before payment.
  final bool needsApproval;
  final bool isSample;

  @override
  List<Object?> get props =>
      [id, reference, totalAmount, currency, needsApproval, isSample];
}
