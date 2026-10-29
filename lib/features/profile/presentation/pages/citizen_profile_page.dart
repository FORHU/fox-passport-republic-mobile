import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/blocks/confirm_block.dart';
import 'package:flutter_template/shared/citizens/citizen_hero.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/citizens/citizen_widgets.dart';
import 'package:flutter_template/shared/reports/file_report.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/shared/widgets/post_media.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Opens a chat with the person. Passed in by the route, so this page does not
/// reach into Messages.
typedef MessageCitizen = Future<void> Function(
  BuildContext context,
  CitizenProfile profile,
);

/// Someone's public profile, laid out as on the web: a hero card with their
/// photo, level, roles and a Follow button; the level bar; four counts; then
/// tabs for stamps, badges, posts and what they list.
class CitizenProfilePage extends ConsumerStatefulWidget {
  const CitizenProfilePage({
    required this.userId,
    this.onMessage,
    this.activityBuilder,
    this.title,
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

  /// The top bar's title. Your own page says "Profile"; someone else's is
  /// named by the card.
  final String? title;

  @override
  ConsumerState<CitizenProfilePage> createState() => _CitizenProfilePageState();
}

class _CitizenProfilePageState extends ConsumerState<CitizenProfilePage> {
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
          title: widget.title == null
              ? null
              : Text(widget.title!, style: AppTypography.display(size: 18)),
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
        body: CitizenProfileView(
          userId: widget.userId,
          onMessage: widget.onMessage,
          activityBuilder: widget.activityBuilder,
        ),
      ),
    );
  }
}

/// A tab only you see on your own profile, such as your match requests.
class CitizenExtraTab {
  const CitizenExtraTab({required this.label, required this.builder});

  final String label;
  final WidgetBuilder builder;
}

/// Level, XP and counts the caller knows better than the public profile does.
/// The Passport has the real level curve and the full stamp and badge lists.
class CitizenOverrides {
  const CitizenOverrides({
    required this.level,
    required this.xp,
    required this.progress,
    required this.xpText,
    required this.stamps,
    required this.badges,
  });

  final int level;
  final int xp;
  final double progress;
  final String xpText;
  final int stamps;
  final int badges;
}

/// What is in a profile, without a page around it: the card, the counts and
/// the tabs. The profile page puts it under a top bar; the Passport puts it
/// under its own.
class CitizenProfileView extends ConsumerStatefulWidget {
  const CitizenProfileView({
    required this.userId,
    this.onMessage,
    this.activityBuilder,
    this.extraTabs = const [],
    this.overrides,
    super.key,
  });

  final String userId;
  final MessageCitizen? onMessage;
  final Widget Function(BuildContext context, CitizenProfile profile)?
      activityBuilder;

  /// Added after the usual tabs, on your own profile only.
  final List<CitizenExtraTab> extraTabs;
  final CitizenOverrides? overrides;

  @override
  ConsumerState<CitizenProfileView> createState() => _CitizenProfileViewState();
}

class _CitizenProfileViewState extends ConsumerState<CitizenProfileView> {
  int _tab = 0;

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
      child: async.when(
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
        data: (loaded) {
          final o = widget.overrides;
          final profile =
              o == null ? loaded : loaded.copyWith(level: o.level, xp: o.xp);
          final isMe = profile.id == me;
          final stampCount = o?.stamps ?? profile.stamps.length;
          final badgeCount = o?.badges ?? profile.badges.length;
          final tabs = <(String, WidgetBuilder)>[
            (
              '${l10n.citizenTabStamps} ($stampCount)',
              (_) => _StampsTab(stamps: profile.stamps, showXp: isMe),
            ),
            (
              '${l10n.citizenTabBadges} ($badgeCount)',
              (_) => _BadgesTab(badges: profile.badges),
            ),
            (
              '${l10n.citizenTabActivity} (${profile.postCount})',
              (c) =>
                  widget.activityBuilder?.call(c, profile) ??
                  _ActivityTab(profile: profile),
            ),
            if (profile.offerings.isNotEmpty)
              (
                l10n.citizenTabOfferings,
                (_) => _OfferingsTab(items: profile.offerings),
              ),
            if (isMe)
              for (final t in widget.extraTabs) (t.label, t.builder),
          ];
          final index = _tab.clamp(0, tabs.length - 1);

          return RefreshIndicator(
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
                CitizenHero(
                  profile: profile,
                  isMe: isMe,
                  progress: o?.progress,
                  xpText: o?.xpText,
                  onMessage: widget.onMessage == null
                      ? null
                      : () => unawaited(_message(profile)),
                ),
                const SizedBox(height: 12),
                CitizenStats(
                  profile: profile,
                  stampCount: o?.stamps,
                  badgeCount: o?.badges,
                ),
                const SizedBox(height: 16),
                _TabBar(
                  labels: [for (final t in tabs) t.$1],
                  selected: index,
                  onSelect: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 12),
                tabs[index].$2(context),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected
                            ? AppColors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: AppTypography.body(
                      size: 12 * context.fit,
                      weight: FontWeight.w700,
                      color: i == selected
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
                  CitizenChip(label: '+${s.xp} XP', color: AppColors.accent),
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
                          CitizenChip(
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
                      Text('${p.likes}', style: citizenTiny(context)),
                      const Spacer(),
                      Text(
                        l10n.citizenComments(p.comments),
                        style: citizenTiny(context),
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
