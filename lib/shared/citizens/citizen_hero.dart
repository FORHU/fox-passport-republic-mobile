import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/citizens/citizen_widgets.dart';
import 'package:flutter_template/shared/follow/follow_button.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// A person's profile card and their four counts, shared by their profile and
/// the Passport so the two look the same.

class CitizenHero extends ConsumerWidget {
  const CitizenHero({
    required this.profile,
    required this.isMe,
    this.onMessage,
    this.progress,
    this.xpText,
    super.key,
  });

  final CitizenProfile profile;
  final bool isMe;
  final VoidCallback? onMessage;

  /// 0 to 1. Where the level curve is known (the Passport), it replaces the
  /// profile's own estimate.
  final double? progress;

  /// The XP line to show, in place of the one worked out from the profile.
  final String? xpText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final counts = ref.watch(citizenCountsProvider(profile.id)).value;
    final place =
        [profile.city, profile.country].whereType<String>().join(', ');
    final since = profile.joinedAt?.year;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: profile.isPartner
              ? AppColors.warning.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CitizenAvatar(
                name: profile.name,
                level: profile.level,
                imageUrl: profile.imageUrl,
                partner: profile.isPartner,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          profile.name,
                          style: AppTypography.display(size: 18 * context.fit),
                        ),
                        if (profile.verified)
                          Icon(
                            Icons.verified_rounded,
                            size: 16 * context.fit,
                            color: AppColors.accent,
                          ),
                      ],
                    ),
                    if (profile.isPartner)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: CitizenChip(
                          label: l10n.citizenPartner,
                          color: AppColors.warning,
                          icon: Icons.verified_outlined,
                        ),
                      ),
                    if (profile.username != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '@${profile.username}',
                          style: AppTypography.body(
                            size: 12 * context.fit,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null) ...[
            const SizedBox(height: 12),
            Text(profile.bio!, style: AppTypography.body(size: 13)),
          ] else if (isMe) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push(RouteNames.profileEdit),
              child: Text(
                l10n.citizenAddBio,
                style: AppTypography.body(
                  size: 12,
                  color: AppColors.accent,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (place.isNotEmpty)
                _Meta(icon: Icons.place_outlined, text: place),
              if (since != null)
                _Meta(
                  icon: Icons.calendar_today_outlined,
                  text: l10n.citizenSince(
                    DateFormat.y(locale).format(DateTime(since)),
                  ),
                ),
            ],
          ),
          if (counts != null) ...[
            const SizedBox(height: 10),
            // On your own profile the counts open who follows you, who you
            // follow and the requests waiting for you.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isMe ? () => context.push(RouteNames.people) : null,
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Count(
                    value: counts.followers,
                    label: l10n.citizenFollowers,
                  ),
                  _Count(
                    value: counts.following,
                    label: l10n.citizenFollowing,
                  ),
                ],
              ),
            ),
          ],
          if (profile.roles.isNotEmpty ||
              profile.specializations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in profile.roles)
                  CitizenChip(
                    label: citizenRoleLabel(l10n, r),
                    color: r == 'investor'
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                for (final s in profile.specializations)
                  CitizenChip(label: s, color: AppColors.textMuted, soft: true),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (isMe)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                label: Text(l10n.profileEdit),
                onPressed: () => context.push(RouteNames.profileEdit),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FollowButton(
                  userId: profile.id,
                  compact: true,
                  showCount: false,
                ),
                if (onMessage != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: AppTypography.display(size: 12),
                    ),
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: Text(l10n.citizenMessage),
                    onPressed: onMessage,
                  ),
              ],
            ),
          // Experience points are private: only the owner sees them. Others
          // still see the level.
          if (isMe) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.citizenProgression,
                    style: citizenTiny(context),
                  ),
                ),
                Flexible(
                  child: Text(
                    xpText ??
                        l10n.citizenXp(
                          profile.xp,
                          profile.nextLevelXp,
                          (profile.progress * 100).round(),
                        ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    style: citizenTiny(context, color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: progress ?? profile.progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceRaised,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * context.fit, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.body(size: 11 * context.fit)),
        ],
      );
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: AppTypography.body(
                size: 12 * context.fit,
                weight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: label,
              style: AppTypography.body(size: 12 * context.fit),
            ),
          ],
        ),
      );
}

class CitizenStats extends StatelessWidget {
  const CitizenStats({
    required this.profile,
    this.stampCount,
    this.badgeCount,
    super.key,
  });

  final CitizenProfile profile;

  /// Counts the caller knows better than the profile does.
  final int? stampCount;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget tile(IconData icon, Color color, String label, String value) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(icon, size: 15 * context.fit, color: color),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.display(size: 16 * context.fit),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: citizenTiny(context),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        tile(
          Icons.military_tech_outlined,
          AppColors.accent,
          l10n.citizenStatLevel,
          'L${profile.level}',
        ),
        const SizedBox(width: 8),
        tile(
          Icons.verified_outlined,
          AppColors.warning,
          l10n.citizenStatStamps,
          '${stampCount ?? profile.stamps.length}',
        ),
        const SizedBox(width: 8),
        tile(
          Icons.workspace_premium_outlined,
          AppColors.roleVenue,
          l10n.citizenStatBadges,
          '${badgeCount ?? profile.badges.length}',
        ),
        const SizedBox(width: 8),
        tile(
          Icons.forum_outlined,
          AppColors.roleTalent,
          l10n.citizenStatPosts,
          '${profile.postCount}',
        ),
      ],
    );
  }
}
