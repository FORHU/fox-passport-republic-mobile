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
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/shared/widgets/post_media.dart';
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
  const CitizenProfilePage({
    required this.userId,
    this.onMessage,
    this.activityBuilder,
    this.ownerSection,
    super.key,
  });

  /// The person's id or username.
  final String userId;
  final MessageCitizen? onMessage;

  /// The Activity tab. The route passes the Republic feed of their posts, so
  /// this page does not reach into the Republic. Without it the tab lists the
  /// posts that came with the profile.
  final Widget Function(BuildContext context, CitizenProfile profile)?
      activityBuilder;

  /// Shown under the profile card, and only on your own profile: your email,
  /// followers, ID check and Sign out.
  final Widget? ownerSection;

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

    final media = MediaQuery.of(context);
    return MediaQuery(
      // A phone set to a very large font would still overflow the cards, so
      // the text here grows only a little.
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.1),
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.textPrimary,
          // Your own page says what it is; someone else's is named by the card.
          title: widget.ownerSection == null
              ? null
              : Text(l10n.profile, style: AppTypography.display(size: 18)),
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
            onAction: () =>
                ref.invalidate(citizenProfileProvider(widget.userId)),
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
                if (profile.id == me && widget.ownerSection != null) ...[
                  const SizedBox(height: 12),
                  widget.ownerSection!,
                ],
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
                  _Tab.stamps => _StampsTab(
                      stamps: profile.stamps,
                      showXp: profile.id == me,
                    ),
                  _Tab.badges => _BadgesTab(badges: profile.badges),
                  _Tab.activity =>
                    widget.activityBuilder?.call(context, profile) ??
                        _ActivityTab(profile: profile),
                  _Tab.offerings => _OfferingsTab(items: profile.offerings),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _Fit on BuildContext {
  /// 1.0 on a 360 dp phone, smaller on a narrower one and a little larger on
  /// a wide one, so the profile fits whatever screen it is on.
  double get fit => (MediaQuery.sizeOf(this).width / 360).clamp(0.82, 1.15);
}

/// Captions and chips: the mono label at a smaller size, with less spacing
/// between letters than the default, so they take less room. Follows the
/// screen width.
TextStyle _tiny(BuildContext context, {Color color = AppColors.textMuted}) =>
    AppTypography.label(color: color).copyWith(
      fontSize: 9.5 * context.fit,
      letterSpacing: 0.5 * context.fit,
    );

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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64 * context.fit,
                    height: 64 * context.fit,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withValues(alpha: 0.45)],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.5),
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
                                    size: 24 * context.fit,
                                    color: accent,
                                  ),
                                ),
                              ),
                            )
                          : NetworkImageBox(
                              url: profile.imageUrl!,
                              width: 59 * context.fit,
                              height: 59 * context.fit,
                            ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: profile.isPartner
                            ? AppColors.warning
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: profile.isPartner
                              ? AppColors.warning
                              : AppColors.accentTintBorder,
                        ),
                      ),
                      child: Text(
                        l10n.citizenLevelChip(profile.level),
                        style: _tiny(
                          context,
                          color: profile.isPartner
                              ? AppColors.onAccent
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
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
            Wrap(
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
                    style: _tiny(context),
                  ),
                ),
                Text(
                  l10n.citizenXp(
                    profile.xp,
                    profile.nextLevelXp,
                    (profile.progress * 100).round(),
                  ),
                  style: _tiny(context, color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: profile.progress,
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: soft ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11 * context.fit, color: color),
              const SizedBox(width: 3),
            ],
            Text(label, style: _tiny(context, color: color)),
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
                  style: _tiny(context),
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
      (_Tab.activity, '${l10n.citizenTabActivity} (${profile.postCount})'),
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
                      size: 12 * context.fit,
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
  const _StampsTab({required this.stamps, required this.showXp});

  final List<CitizenStamp> stamps;

  /// Earned XP is private to the owner.
  final bool showXp;

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
                if (showXp)
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
  const _ActivityTab({required this.profile});

  final CitizenProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final posts = profile.posts;
    if (posts.isEmpty) {
      return _Empty(
        icon: Icons.chat_bubble_outline_rounded,
        title: l10n.citizenNoPosts,
        body: l10n.citizenNoPostsBody,
      );
    }
    final initial = profile.name.isEmpty
        ? '?'
        : profile.name.characters.first.toUpperCase();
    // Like the feed: each post is a full-width card, photos edge to edge.
    return Column(
      children: [
        for (final p in posts) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      AvatarImage(
                        url: profile.imageUrl,
                        radius: 18,
                        fallback: Text(
                          initial,
                          style: AppTypography.display(
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(
                                weight: FontWeight.w700,
                              ),
                            ),
                            if (p.createdAt != null)
                              Text(
                                DateFormat.yMMMd(locale)
                                    .format(p.createdAt!.toLocal()),
                                style: AppTypography.body(
                                  size: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Text(p.content, style: AppTypography.body()),
                  ),
                if (p.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PostMedia(urls: p.mediaUrls),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text('${p.likes}', style: _tiny(context)),
                      const Spacer(),
                      Text(
                        l10n.citizenComments(p.comments),
                        style: _tiny(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
