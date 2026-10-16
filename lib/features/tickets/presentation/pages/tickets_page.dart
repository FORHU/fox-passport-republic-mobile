import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/match_request_card.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

enum _Segment { upcoming, past, requests }

/// Tickets: the bookings the user holds, upcoming and past.
class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({this.initialSegment, super.key});

  /// `requests` opens on the Match requests switch.
  final String? initialSegment;

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  late _Segment _segment = _fromParam(widget.initialSegment);

  static _Segment _fromParam(String? value) =>
      value == 'requests' ? _Segment.requests : _Segment.upcoming;

  @override
  void didUpdateWidget(TicketsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shell keeps this page alive, so a link arrives as an update.
    if (oldWidget.initialSegment != widget.initialSegment &&
        widget.initialSegment != null) {
      setState(() => _segment = _fromParam(widget.initialSegment));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tickets = _segment == _Segment.upcoming
        ? ref.watch(upcomingTicketsProvider)
        : ref.watch(pastTicketsProvider);
    final requests = ref.watch(myMatchRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref
              ..invalidate(upcomingTicketsProvider)
              ..invalidate(pastTicketsProvider)
              ..invalidate(myMatchRequestsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Text(
                    l10n.bookings,
                    style: AppTypography.display(size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedPills<_Segment>(
                value: _segment,
                onChanged: (v) => setState(() => _segment = v),
                options: [
                  SegmentOption(_Segment.upcoming, l10n.ticketsUpcoming),
                  SegmentOption(_Segment.past, l10n.ticketsPast),
                  SegmentOption(_Segment.requests, l10n.ticketsRequests),
                ],
              ),
              const SizedBox(height: 16),
              if (_segment == _Segment.requests)
                ...requests.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                  error: (_, __) => [
                    _loadError(
                      l10n.apiLoadFailed,
                      l10n.retry,
                      () => ref.invalidate(myMatchRequestsProvider),
                    ),
                  ],
                  data: (list) => list.isEmpty
                      ? [_empty(l10n.ticketsEmptyRequests)]
                      : [
                          for (final r in list)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: MatchRequestCard(item: r),
                            ),
                        ],
                )
              else
                ...tickets.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                  error: (_, __) => [
                    _loadError(l10n.apiLoadFailed, l10n.retry, () {
                      if (_segment == _Segment.upcoming) {
                        ref.invalidate(upcomingTicketsProvider);
                      } else {
                        ref.invalidate(pastTicketsProvider);
                      }
                    }),
                  ],
                  data: (list) => list.isEmpty
                      ? [
                          _empty(
                            _segment == _Segment.upcoming
                                ? l10n.ticketsEmptyUpcoming
                                : l10n.ticketsEmptyPast,
                          ),
                        ]
                      : [for (final t in list) _item(t)],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(Ticket ticket) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TicketCard(ticket: ticket),
      );

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ),
      );

  Widget _loadError(String message, String retry, VoidCallback onRetry) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              TextButton(onPressed: onRetry, child: Text(retry)),
            ],
          ),
        ),
      );
}
