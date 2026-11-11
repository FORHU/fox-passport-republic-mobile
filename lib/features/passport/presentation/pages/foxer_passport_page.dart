import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/foxer_score_card.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A Foxer's Passport for one role: their own Foxer Score, the perks they hold
/// and the badges they can earn. There is no level, rank, XP or Tokens here:
/// a Foxer earns Tokens only as a citizen.
///
/// [path] is the role of the space it was opened from. Stamps are left out on
/// purpose: they come from attending events, which is the Citizen's Passport.
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
