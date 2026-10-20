import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The person's Passport in one line under the search bar: level, XP towards
/// the next, and the one next step. It makes Home about them, and opens the
/// Passport. Shows nothing while the Passport loads or if it fails, never an
/// error box.
class PassportStrip extends ConsumerWidget {
  const PassportStrip({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(passportProvider).asData?.value;
    if (summary == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final name = ref.watch(authControllerProvider.select((s) => s.user?.name));
    final initial = (name != null && name.isNotEmpty)
        ? name.characters.first.toUpperCase()
        : '?';
    final level = l10n.passportCitizenLevel(summary.level);
    final xp = l10n.passportXp(summary.totalXp);
    // The one next step: the first stamp, then the next level.
    final next = summary.stamps.isEmpty
        ? l10n.passportEmptyStamps
        : l10n.passportNextLevel(summary.level + 1, summary.nextLevelXp);

    return Semantics(
      button: true,
      label: '$level, $xp. $next',
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.textPrimary,
                      child: Text(
                        initial,
                        style: AppTypography.display(color: AppColors.canvas),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  level,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.display(size: 15),
                                ),
                              ),
                              Text(
                                xp.toUpperCase(),
                                style: AppTypography.label(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: AppRadius.brPill,
                            child: LinearProgressIndicator(
                              value: summary.progress,
                              minHeight: 5,
                              color: AppColors.accent,
                              backgroundColor: AppColors.borderStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(next, style: AppTypography.body(size: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
