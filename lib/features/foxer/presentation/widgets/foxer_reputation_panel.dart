import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/foxers/foxer_reputation.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Three facts and the earned labels for the Foxer with [userId]: bookings
/// done, replies in time and cancellations. It takes no room until the server
/// has answered, and nothing shows if it fails or there is nothing to say yet,
/// so a new Foxer's page is not a row of zeros.
class FoxerReputationPanel extends ConsumerWidget {
  const FoxerReputationPanel({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reputation = ref.watch(foxerReputationProvider(userId)).value;
    if (reputation == null || reputation.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Fact(
                  value: '${reputation.completedBookings}',
                  label: context.l10n.foxerStatBookings,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Fact(
                  value: context.l10n
                      .foxerStatPercent(reputation.responseRatePercent),
                  label: context.l10n.foxerStatReplies,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Fact(
                  value: context.l10n
                      .foxerStatPercent(reputation.cancellationRatePercent),
                  label: context.l10n.foxerStatCancellations,
                ),
              ),
            ],
          ),
          if (reputation.foxerSince != null) ...[
            const SizedBox(height: 8),
            _Fact(
              value: DateFormat.yMMM(
                Localizations.localeOf(context).toString(),
              ).format(reputation.foxerSince!.toLocal()),
              label: context.l10n.foxerSinceLabel,
            ),
          ],
          if (reputation.place != null) ...[
            const SizedBox(height: 10),
            _Place(text: foxerPlaceText(context.l10n, reputation.place!)),
          ],
          if (reputation.labels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in reputation.labels)
                  _LabelChip(text: foxerLabelText(context.l10n, label)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "#3 Venues in Manila": the place, the kind of Foxer and the city.
String foxerPlaceText(AppLocalizations l10n, FoxerPlace place) {
  final role = switch (place.role) {
    'venueFoxer' => l10n.leaderboardRoleVenue,
    'eventFoxer' => l10n.leaderboardRoleEvent,
    'providerFoxer' => l10n.foxerPlaceRoleProviders,
    _ => '',
  };
  final city = place.city;
  if (role.isEmpty) {
    return city == null ? '#${place.position}' : '#${place.position} · $city';
  }
  return city == null
      ? l10n.foxerPlaceNoCity(place.position, role)
      : l10n.foxerPlace(place.position, role, city);
}

/// The words for a label the server named. One it does not know is shown as
/// sent, so a new label is never lost.
String foxerLabelText(AppLocalizations l10n, String label) => switch (label) {
      'Top rated' => l10n.foxerLabelTopRated,
      'Fast responder' => l10n.foxerLabelFastResponder,
      'Reliable' => l10n.foxerLabelReliable,
      'Rising' => l10n.foxerLabelRising,
      _ => label,
    };

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.display(size: 18)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// The leaderboard place, on its own line above the labels.
class _Place extends StatelessWidget {
  const _Place({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events_outlined,
          size: 18,
          color: AppColors.warning,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTypography.display(size: 14),
          ),
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.16),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppTypography.display(size: 12),
      ),
    );
  }
}
