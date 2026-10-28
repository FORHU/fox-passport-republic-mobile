import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/blocks/confirm_block.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/follow/follow_button.dart';
import 'package:flutter_template/shared/reports/file_report.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Opens a chat with the person. Passed in by the route, so this page does not
/// reach into Messages.
typedef MessageCitizen = Future<void> Function(
  BuildContext context,
  CitizenProfile profile,
);

enum _Tab { stamps, badges, activity, offerings }

/// Someone's public profile, laid out as on the web: a hero card with their
/// photo, level, roles and a Follow button; the level bar; four counts; then
/// tabs for stamps, badges, posts and what they list.
class CitizenProfilePage extends ConsumerStatefulWidget {
  const CitizenProfilePage({required this.userId, this.onMessage, super.key});

  /// The person's id or username.
  final String userId;
  final MessageCitizen? onMessage;

  @override
  ConsumerState<CitizenProfilePage> createState() => _CitizenProfilePageState();
}

class _CitizenProfilePageState extends ConsumerState<CitizenProfilePage> {
  _Tab _tab = _Tab.stamps;

  Future<void> _share(CitizenProfile profile) async {
    final l10n = context.l10n;
    final base = AppConfig.instance.webAppUrl;
    final link = base.isEmpty
        ? profile.username ?? profile.id
        : '$base/user/${profile.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) showTopToast(context, l10n.citizenLinkCopied);
  }

  Future<void> _block(CitizenProfile profile) async {
    final blocked = await confirmBlock(
      context,
      ref,
      userId: profile.id,
      name: profile.name,
    );
    if (blocked && mounted) context.pop();
  }

  Future<void> _message(CitizenProfile profile) async {
    final l10n = context.l10n;
    try {
      await widget.onMessage!(context, profile);
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.citizenMessageFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(citizenProfileProvider(widget.userId));
    final me = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (async.value case final profile?) ...[
            IconButton(
              tooltip: l10n.citizenShare,
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => unawaited(_share(profile)),
            ),
            if (profile.id != me)
              PopupMenuButton<void>(
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    onTap: () => unawaited(
                      fileReport(
                        context,
                        ref,
                        target: ReportTarget.user,
                        id: profile.id,
                        title: l10n.reportUserTitle,
                      ),
                    ),
                    child: Text(l10n.foxerMenuReport),
                  ),
                  PopupMenuItem<void>(
                    onTap: () => unawaited(_block(profile)),
                    child: Text(l10n.foxerMenuBlock),
                  ),
                ],
              ),
          ],
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          icon: Icons.person_off_outlined,
          title: l10n.citizenNotFound,
          message: l10n.citizenNotFoundBody,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(citizenProfileProvider(widget.userId)),
        ),
        data: (profile) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref
              ..invalidate(citizenProfileProvider(widget.userId))
              ..invalidate(citizenCountsProvider(profile.id));
            try {
              await ref.read(citizenProfileProvider(widget.userId).future);
            } on Object {
              // The page shows its own error state with a retry.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              _Hero(
                profile: profile,
                isMe: profile.id == me,
                onMessage: widget.onMessage == null
                    ? null
                    : () => unawaited(_message(profile)),
              ),
              const SizedBox(height: 12),
              _Stats(profile: profile),
              const SizedBox(height: 16),
              _TabBar(
                profile: profile,
                selected: _tab,
                onSelect: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 12),
              switch (_tab) {
                _Tab.stamps => _StampsTab(stamps: profile.stamps),
                _Tab.badges => _BadgesTab(badges: profile.badges),
                _Tab.activity => _ActivityTab(posts: profile.posts),
                _Tab.offerings => _OfferingsTab(items: profile.offerings),
              },
            ],
          ),
        ),
      ),
    );
  }
}

Color _accentFor(CitizenProfile p) =>
    p.isPartner ? AppColors.warning : AppColors.accent;

class _Hero extends ConsumerWidget {
  const _Hero({required this.profile, required this.isMe, this.onMessage});

  final CitizenProfile profile;
  final bool isMe;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final accent = _accentFor(profile);
    final counts = ref.watch(citizenCountsProvider(profile.id)).value;
    final place =
        [profile.city, profile.country].whereType<String>().join(', ');
    final since = profile.joinedAt?.year;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withValues(alpha: 0.45)],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: profile.imageUrl == null
                          ? ColoredBox(
                              color: AppColors.surfaceRaised,
                              child: Center(
                                child: Text(
                                  profile.name.isEmpty
                                      ? '?'
                                      : profile.name.characters.first
                                          .toUpperCase(),
                                  style: AppTypography.display(
                                    size: 32,
                                    color: accent,
                                  ),
                                ),
                              ),
                            )
                          : NetworkImageBox(
                              url: profile.imageUrl!,
                              width: 82,
                              height: 82,
                            ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: profile.isPartner
                            ? AppColors.warning
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: profile.isPartner
                              ? AppColors.warning
                              : AppColors.accentTintBorder,
                        ),
                      ),
                      child: Text(
                        l10n.citizenLevelChip(profile.level),
                        style: AppTypography.label(
                          color: profile.isPartner
                              ? AppColors.onAccent
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
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
                          style: AppTypography.display(size: 22),
                        ),
                        if (profile.verified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                      ],
                    ),
                    if (profile.isPartner)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _Chip(
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
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
            Row(
              children: [
                _Count(
                  value: counts.followers,
                  label: l10n.citizenFollowers,
                ),
                const SizedBox(width: 16),
                _Count(
                  value: counts.following,
                  label: l10n.citizenFollowing,
                ),
              ],
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
                  _Chip(
                    label: (r == 'investor'
                            ? l10n.citizenPartner
                            : r.replaceAll('Foxer', ' Foxer'))
                        .toUpperCase(),
                    color: r == 'investor'
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                for (final s in profile.specializations)
                  _Chip(label: s, color: AppColors.textMuted, soft: true),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (isMe)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                label: Text(l10n.profileEdit),
                onPressed: () => context.push(RouteNames.profileEdit),
              ),
            )
          else
            Row(
              children: [
                FollowButton(userId: profile.id),
                if (onMessage != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(l10n.citizenMessage),
                    onPressed: onMessage,
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.citizenProgression,
                  style: AppTypography.label(),
                ),
              ),
              Text(
                l10n.citizenXp(
                  profile.xp,
                  profile.nextLevelXp,
                  (profile.progress * 100).round(),
                ),
                style: AppTypography.label(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: profile.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceRaised,
              color: AppColors.accent,
            ),
          ),
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
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.body(size: 12)),
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
              style: AppTypography.body(weight: FontWeight.w800),
            ),
            TextSpan(text: label, style: AppTypography.body(size: 13)),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.soft = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool soft;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: soft ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.label(color: color),
            ),
          ],
        ),
      );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.profile});

  final CitizenProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget tile(IconData icon, Color color, String label, String value) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.display(size: 20)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(),
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
          '${profile.stamps.length}',
        ),
        const SizedBox(width: 8),
        tile(
          Icons.workspace_premium_outlined,
          AppColors.roleVenue,
          l10n.citizenStatBadges,
          '${profile.badges.length}',
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

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.profile,
    required this.selected,
    required this.onSelect,
  });

  final CitizenProfile profile;
  final _Tab selected;
  final ValueChanged<_Tab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <(_Tab, String)>[
      (_Tab.stamps, '${l10n.citizenTabStamps} (${profile.stamps.length})'),
      (_Tab.badges, '${l10n.citizenTabBadges} (${profile.badges.length})'),
      (_Tab.activity, '${l10n.citizenTabActivity} (${profile.posts.length})'),
      if (profile.offerings.isNotEmpty)
        (_Tab.offerings, l10n.citizenTabOfferings),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (tab, label) in tabs)
              InkWell(
                onTap: () => onSelect(tab),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == selected
                            ? AppColors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.body(
                      weight: FontWeight.w700,
                      color: tab == selected
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.display(size: 15)),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? AppColors.border),
        ),
        child: child,
      );
}

class _StampsTab extends StatelessWidget {
  const _StampsTab({required this.stamps});

  final List<CitizenStamp> stamps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    if (stamps.isEmpty) {
      return _Empty(
        icon: Icons.verified_outlined,
        title: l10n.citizenNoStamps,
        body: l10n.citizenNoStampsBody,
      );
    }
    return Column(
      children: [
        for (final s in stamps) ...[
          _Card(
            borderColor: AppColors.warning.withValues(alpha: 0.25),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceRaised,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: s.imageUrl == null
                        ? const Icon(
                            Icons.verified_outlined,
                            color: AppColors.warning,
                          )
                        : NetworkImageBox(
                            url: s.imageUrl!,
                            width: 44,
                            height: 44,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.place ?? s.eventName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(weight: FontWeight.w700),
                      ),
                      Text(
                        [
                          s.eventName,
                          if (s.date != null)
                            DateFormat.yMMMd(locale).format(s.date!.toLocal()),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _Chip(label: '+${s.xp} XP', color: AppColors.accent),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

Color _rarityColor(String rarity) => switch (rarity) {
      'legendary' => AppColors.warning,
      'epic' => AppColors.roleVenue,
      'rare' => AppColors.roleTalent,
      _ => AppColors.textSecondary,
    };

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({required this.badges});

  final List<CitizenBadge> badges;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    if (badges.isEmpty) {
      return _Empty(
        icon: Icons.military_tech_outlined,
        title: l10n.citizenNoBadges,
        body: l10n.citizenNoBadgesBody,
      );
    }
    return Column(
      children: [
        for (final b in badges) ...[
          _Card(
            borderColor: _rarityColor(b.rarity).withValues(alpha: 0.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _rarityColor(b.rarity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.military_tech_outlined,
                    color: _rarityColor(b.rarity),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            b.name,
                            style: AppTypography.body(weight: FontWeight.w700),
                          ),
                          _Chip(
                            label: b.rarity.toUpperCase(),
                            color: _rarityColor(b.rarity),
                          ),
                        ],
                      ),
                      if (b.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            b.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      if (b.earnedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.citizenUnlocked(
                              DateFormat.yMMMd(locale)
                                  .format(b.earnedAt!.toLocal()),
                            ),
                            style: AppTypography.label(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.posts});

  final List<CitizenPost> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    if (posts.isEmpty) {
      return _Empty(
        icon: Icons.chat_bubble_outline_rounded,
        title: l10n.citizenNoPosts,
        body: l10n.citizenNoPostsBody,
      );
    }
    return Column(
      children: [
        for (final p in posts) ...[
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.createdAt != null)
                  Text(
                    DateFormat.yMMMd(locale).format(p.createdAt!.toLocal()),
                    style: AppTypography.label(),
                  ),
                if (p.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(p.content, style: AppTypography.body()),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text('${p.likes}', style: AppTypography.label()),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text('${p.comments}', style: AppTypography.label()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _OfferingsTab extends StatelessWidget {
  const _OfferingsTab({required this.items});

  final List<CitizenOffering> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String heading(String kind) => switch (kind) {
          'venue' => l10n.citizenVenues,
          'service' => l10n.citizenServices,
          _ => l10n.citizenGear,
        };
    IconData iconFor(String kind) => switch (kind) {
          'venue' => Icons.domain_outlined,
          'service' => Icons.stars_outlined,
          _ => Icons.devices_other_outlined,
        };

    final kinds = [
      for (final k in const ['venue', 'service', 'asset'])
        if (items.any((i) => i.kind == k)) k,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final k in kinds) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              heading(k).toUpperCase(),
              style: AppTypography.label(),
            ),
          ),
          for (final i in items.where((i) => i.kind == k)) ...[
            _Card(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: i.imageUrl == null
                          ? ColoredBox(
                              color: AppColors.surfaceRaised,
                              child: Icon(
                                iconFor(k),
                                color: AppColors.textMuted,
                              ),
                            )
                          : NetworkImageBox(
                              url: i.imageUrl!,
                              width: 56,
                              height: 56,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(weight: FontWeight.w700),
                        ),
                        if (i.detail != null)
                          Text(
                            i.detail!.replaceAll('_', ' '),
                            style: AppTypography.body(
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}
