import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/tickets/event_edit_proposal.dart';
import 'package:flutter_template/shared/tickets/replacement_status.dart';

/// A booking's replacement proposals, for its citizen to answer.
class EventEditProposalsRepository {
  EventEditProposalsRepository(this._api);

  final ApiService _api;

  /// Every proposal on [bookingId], newest first.
  Future<List<EventEditProposal>> forBooking(String bookingId) async {
    final body = await _api.get(
      ApiEndpoints.eventEditProposals,
      query: {'bookingId': bookingId},
    );
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Proposals response is not a list');
    }
    return [
      for (final row in data)
        if (row is Map) EventEditProposal.fromJson(row.cast<String, dynamic>()),
    ];
  }

  /// Which Suppliers on [bookingId] need replacing, by when, and whether a
  /// full-refund cancel is open.
  Future<ReplacementStatus> status(String bookingId) async {
    final body = await _api.get(ApiEndpoints.bookingReplacement(bookingId));
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Replacement response has no status');
    }
    return ReplacementStatus.fromJson(data.cast<String, dynamic>());
  }

  /// The new Supplier is asked to confirm; the old one is let go. On a paid
  /// booking whose total goes up, nothing changes yet: the result carries
  /// what is needed to pay the difference, then [confirmPayment] applies it.
  Future<AcceptResult> accept(String proposalId) async {
    final body = await _api.post(
      ApiEndpoints.eventEditProposalAnswer(proposalId, 'accept'),
    );
    final data = body is Map ? body['data'] : null;
    if (data is Map && data['paymentRequired'] == true) {
      return AcceptResult(
        paymentRequired: true,
        clientSecret: data['clientSecret']?.toString(),
        amount: num.tryParse('${data['amount']}') ?? 0,
        alreadyPaid: data['paid'] == true,
      );
    }
    return const AcceptResult();
  }

  /// After the difference was paid: the API checks it and applies the change,
  /// or refunds it if the change can no longer apply (and says so).
  Future<void> confirmPayment(String proposalId) async {
    await _api.post(
      ApiEndpoints.eventEditProposalAnswer(proposalId, 'confirm-payment'),
    );
  }

  /// The host is told and may propose another.
  Future<void> decline(String proposalId) async {
    await _api.post(
      ApiEndpoints.eventEditProposalAnswer(proposalId, 'decline'),
    );
  }
}

/// What accepting a proposal needs next.
class AcceptResult {
  const AcceptResult({
    this.paymentRequired = false,
    this.clientSecret,
    this.amount = 0,
    this.alreadyPaid = false,
  });

  /// A paid booking whose total goes up: the difference is paid first.
  final bool paymentRequired;
  final String? clientSecret;
  final num amount;

  /// The difference went through earlier (the app closed before confirming).
  final bool alreadyPaid;
}

final eventEditProposalsRepositoryProvider =
    Provider<EventEditProposalsRepository>(
  (ref) => EventEditProposalsRepository(ref.watch(apiServiceProvider)),
);

/// A booking's replacement status: read first, so proposals are only asked
/// for when one is waiting.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final replacementStatusProvider =
    FutureProvider.autoDispose.family<ReplacementStatus, String>(
  (ref, bookingId) {
    ref.watch(currentUserIdProvider);
    return ref.watch(eventEditProposalsRepositoryProvider).status(bookingId);
  },
);

/// The proposal on a booking still waiting for an answer, if any.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final openProposalProvider =
    FutureProvider.autoDispose.family<EventEditProposal?, String>(
  (ref, bookingId) async {
    ref.watch(currentUserIdProvider);
    final all = await ref
        .watch(eventEditProposalsRepositoryProvider)
        .forBooking(bookingId);
    for (final p in all) {
      if (p.isOpen()) return p;
    }
    return null;
  },
);
