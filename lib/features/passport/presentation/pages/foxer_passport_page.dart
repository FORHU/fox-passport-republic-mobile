import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/foxer_passport.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/foxer_score_card.dart';
import 'package:flutter_template/shared/widgets/role_progress.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// A Foxer's Passport for one role: rank and level, progress to the next
/// level, the Wallet, the perks they hold and the badges they can earn.
///
/// [path] is the XP path of the space it was opened from, so a Foxer with
/// several roles sees each role's own level. Stamps are left out on purpose:
/// they come from attending events, which is the Citizen's Passport.
class FoxerPassportPage extends ConsumerWidget {
  const FoxerPassportPage({required this.path, super.key});

  /// The XP path as the API names it (`venueFoxer`, `eventFoxer`, ...).
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final passport = ref.watch(foxerPassportProvider(path));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.passportTitle, style: AppTypography.display(size: 22)),
      ),
      body: passport.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(foxerPassportProvider(path)),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.refresh(foxerPassportProvider(path).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _LevelCard(passport: data, path: path),
              const WalletRow(),
              // Only the Foxer sees their score.
              const FoxerScoreCard(),
              const SizedBox(height: 24),
              _Section(title: l10n.foxerPassportPerks),
              if (data.perks.isEmpty)
                _Hint(text: l10n.foxerPassportNoPerks)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final perk in data.perks)
                      _Chip(label: perkLabel(perk)),
                  ],
                ),
              const SizedBox(height: 24),
              _Section(title: l10n.passportBadges),
              if (data.badges.isEmpty)
                _Hint(text: l10n.foxerPassportNoBadges)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final badge in data.badges)
                      _Chip(
                        label: badge.earned || badge.name.isNotEmpty
                            ? badge.name
                            : l10n.passportLocked,
                        muted: !badge.earned,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "venue_authority" as "Venue authority". The perk keys are the API's; there
/// is no name for them to look up, so this reads them out as words.
String perkLabel(String key) {
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.passport, required this.path});

  final FoxerPassport passport;
  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = NumberFormat.decimalPattern();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.citizenLevelChip(passport.level),
            style: AppTypography.display(size: 24),
          ),
          // Rank name and level of this role, and the Coins chip.
          RoleProgress(path: path),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: passport.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceRaised,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Only the owner sees raw XP, as on the citizen profile.
              Expanded(
                child: Text(
                  l10n.passportXp(passport.totalXp),
                  style: AppTypography.body(size: 13),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.foxerPassportXpToNext(
                    number.format(passport.xpToNext),
                    passport.level + 1,
                  ),
                  textAlign: TextAlign.end,
                  style: AppTypography.body(size: 13, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: AppTypography.display()),
      );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.body(size: 13, color: AppColors.textMuted),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: muted ? AppColors.surface : AppColors.surfaceRaised,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.body(
            size: 13,
            color: muted ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      );
}
