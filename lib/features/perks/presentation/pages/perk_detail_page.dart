import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/features/perks/presentation/widgets/perk_confirm_sheet.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// One perk: who offers it, the booking it is for (Change to pick another),
/// how it works, and Redeem with the price and the balance.
class PerkDetailPage extends ConsumerStatefulWidget {
  const PerkDetailPage({required this.perkId, super.key});

  final String perkId;

  @override
  ConsumerState<PerkDetailPage> createState() => _PerkDetailPageState();
}

class _PerkDetailPageState extends ConsumerState<PerkDetailPage> {
  String? _bookingId;

  PerkBooking? _selected(PerkDetail detail) {
    for (final b in detail.bookings) {
      if (b.id == _bookingId) return b;
    }
    return detail.bookings.isEmpty ? null : detail.bookings.first;
  }

  Future<void> _pick(PerkDetail detail) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookingPicker(
        bookings: detail.bookings,
        selectedId: _selected(detail)?.id,
      ),
    );
    if (id != null && mounted) setState(() => _bookingId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = ref.watch(perkDetailProvider(widget.perkId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(backgroundColor: AppColors.canvas),
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(perkDetailProvider(widget.perkId)),
        ),
        data: (d) => _body(context, d),
      ),
    );
  }

  Widget _body(BuildContext context, PerkDetail d) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPattern(locale);
    final perk = d.perk;
    final booking = _selected(d);
    final canRedeem = booking != null && d.balance >= perk.tokenCost;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: AppRadius.brPill,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    perk.isHost
                        ? l10n.perksOfferedByHost
                        : l10n.perksOfferedByVenue,
                    style: AppTypography.body(
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(perk.title, style: AppTypography.display(size: 24)),
              if (perk.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 6),
                Text(
                  perk.description!,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 16),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.perkUseItOn.toUpperCase(),
                            style: AppTypography.label(),
                          ),
                        ),
                        if (d.bookings.length > 1)
                          TextButton(
                            onPressed: () => unawaited(_pick(d)),
                            child: Text(
                              l10n.perkChange,
                              style: AppTypography.body(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (booking == null)
                      Text(
                        l10n.perkNoBooking,
                        style: AppTypography.body(
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      )
                    else ...[
                      Text(
                        booking.name,
                        style: AppTypography.display(size: 15),
                      ),
                      if (booking.startAt != null)
                        Text(
                          DateFormat.yMMMd(locale).add_jm().format(
                                booking.startAt!,
                              ),
                          style: AppTypography.body(
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.perkHowItWorks.toUpperCase(),
                      style: AppTypography.label(),
                    ),
                    const SizedBox(height: 8),
                    _Step(1, l10n.perkStep1),
                    _Step(2, l10n.perkStep2),
                    _Step(3, l10n.perkStep3),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.perkRule,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(coinsIcon, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            format.format(perk.tokenCost),
                            style: AppTypography.display(size: 20),
                          ),
                        ],
                      ),
                      Text(
                        l10n.perkYouHave(format.format(d.balance)),
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: l10n.perkRedeem,
                  expand: false,
                  onPressed: canRedeem
                      ? () => unawaited(
                            showPerkConfirmSheet(
                              context,
                              perk: perk,
                              booking: booking,
                              balance: d.balance,
                            ),
                          )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$n',
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ),
            Expanded(child: Text(text, style: AppTypography.body())),
          ],
        ),
      );
}

/// The bookings this perk works for; tapping one returns its id.
class _BookingPicker extends StatelessWidget {
  const _BookingPicker({required this.bookings, required this.selectedId});

  final List<PerkBooking> bookings;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.perkPickBooking, style: AppTypography.display(size: 20)),
            const SizedBox(height: 12),
            for (final b in bookings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(b.name, style: AppTypography.display(size: 15)),
                subtitle: b.startAt == null
                    ? null
                    : Text(
                        DateFormat.yMMMd(locale).add_jm().format(b.startAt!),
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                trailing: b.id == selectedId
                    ? const Icon(Icons.check_rounded, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(b.id),
              ),
          ],
        ),
      ),
    );
  }
}
