import 'package:equatable/equatable.dart';

/// What cancelling a booking would do, from `POST /bookings/:id/cancel/check`.
class CancelQuote extends Equatable {
  const CancelQuote({
    required this.eligible,
    required this.refundPercent,
    required this.totalPaid,
    required this.estimatedRefund,
    this.message = '',
    this.hoursUntilStart,
  });

  factory CancelQuote.fromJson(Map<String, dynamic> json) {
    num n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
    return CancelQuote(
      eligible: json['eligible'] == true,
      refundPercent: n(json['refundPercent']),
      totalPaid: n(json['totalPaid']),
      estimatedRefund: n(json['estimatedRefund']),
      message: (json['message'] as String?) ?? '',
      hoursUntilStart: json['hoursUntilStart'] is num
          ? (json['hoursUntilStart'] as num)
          : null,
    );
  }

  /// False when the booking can no longer be cancelled; [message] says why.
  final bool eligible;

  /// How much of what was paid comes back, 0 to 100.
  final num refundPercent;
  final num totalPaid;
  final num estimatedRefund;

  /// The API's own explanation of the policy that applies.
  final String message;
  final num? hoursUntilStart;

  bool get hasRefund => estimatedRefund > 0;

  @override
  List<Object?> get props => [
        eligible,
        refundPercent,
        totalPaid,
        estimatedRefund,
        message,
        hoursUntilStart,
      ];
}
