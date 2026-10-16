import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

enum _Segment { upcoming, past }

/// Tickets: the bookings the user holds, upcoming and past.
class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({super.key});

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  _Segment _segment = _Segment.upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tickets = _segment == _Segment.upcoming
        ? ref.watch(upcomingTicketsProvider)
        : ref.watch(pastTicketsProvider);

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
              ..invalidate(pastTicketsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(l10n.ticketsTitle, style: AppTypography.display(size: 28)),
              const SizedBox(height: 16),
              SegmentedPills<_Segment>(
                value: _segment,
                onChanged: (v) => setState(() => _segment = v),
                options: [
                  SegmentOption(_Segment.upcoming, l10n.ticketsUpcoming),
                  SegmentOption(_Segment.past, l10n.ticketsPast),
                ],
              ),
              const SizedBox(height: 16),
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
