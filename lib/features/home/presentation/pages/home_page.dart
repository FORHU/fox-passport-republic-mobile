import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/data/last_occasion.dart';
import 'package:flutter_template/features/home/domain/home_categories.dart';
import 'package:flutter_template/features/home/presentation/widgets/category_labels.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/area_sheet.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/skeleton.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/occasion_colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Home: where you are, your next booking if you have one, then what you are
/// planning, built from `GET /categories`. Sections with nothing to show are
/// left out, heading included; Home never draws an error or an empty box.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final upcomingTickets = ref.watch(upcomingTicketsProvider);
    final ticket = upcomingTickets.value?.firstOrNull;
    final area = ref.watch(areaFilterProvider);
    final categories = ref.watch(categoriesProvider).asData?.value;
    final last = ref.watch(lastOccasionProvider);
    final areaSource = ref.watch(areaProvider.select((a) => a.source));
    final unread = ref.watch(notificationInboxProvider).value?.unreadCount ?? 0;

    // The start of today, not "now": the query is a provider key, and a key
    // that changes every build would make Home rebuild without end.
    final now = DateTime.now();
    final soonQuery = CatalogQuery(
      CatalogKind.events,
      limit: 6,
      city: area.city,
      fromDate: DateTime(now.year, now.month, now.day),
      sortBy: 'date_asc',
    );
    final soon = ref.watch(catalogProvider(soonQuery));

    final tiles = occasionTiles(categories, preferred: last);
    final oneThing = singleBookings(categories);

    void openOccasion(Occasion occasion) {
      unawaited(ref.read(lastOccasionProvider.notifier).remember(occasion));
      unawaited(context.push(RouteNames.occasion(occasion.name)));
    }

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
              ..invalidate(categoriesProvider)
              ..invalidate(catalogProvider(soonQuery));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(
                // With the device position the label is the city it is in
                // (never the profile's); "Near you" when that is unknown.
                city: areaSource == AreaSource.device && area.hasPoint
                    ? (area.label ?? l10n.homeNearYou)
                    : area.label ?? ticket?.city,
                unread: unread,
              ),
              // An upcoming booking, if there is one. Failing or empty means
              // no strip and no error.
              if (ticket != null) _NextNight(ticket: ticket),
              if (last != null) ...[
                const SizedBox(height: 16),
                _ContinueCard(
                  occasion: last,
                  count: categories
                      ?.where((c) => Occasion.fromName(c.name) == last)
                      .firstOrNull
                      ?.count,
                  onTap: () => openOccasion(last),
                ),
              ],
              const SizedBox(height: 22),
              Text(
                last == null ? l10n.homePlanning : l10n.homePlanNew,
                style: AppTypography.display(size: 20),
              ),
              const SizedBox(height: 12),
              _OccasionGrid(
                tiles: tiles,
                more: moreCategories(categories),
                onOccasion: openOccasion,
                onAll: () => unawaited(context.push(RouteNames.allCategories)),
              ),
              if (oneThing.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(l10n.homeBookOne, style: AppTypography.display(size: 20)),
                const SizedBox(height: 12),
                _OneThingRow(
                  items: oneThing,
                  onTap: (item) =>
                      context.go(RouteNames.searchFor(item.kind.name)),
                ),
              ],
              ...soon.when(
                loading: () => [
                  const SizedBox(height: 24),
                  const _SoonSkeleton(),
                ],
                error: (_, __) => const <Widget>[],
                data: (page) => page.items.isEmpty
                    ? const <Widget>[]
                    : [
                        const SizedBox(height: 24),
                        _SectionTitle(
                          title: l10n.homeHappeningSoon,
                          action: l10n.seeAll,
                          onAction: () =>
                              context.go(RouteNames.searchFor('events')),
                        ),
                        const SizedBox(height: 12),
                        _SoonRow(items: page.items),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.city, required this.unread});

  final String? city;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: () => showAreaSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accent,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      city?.isNotEmpty == true
                          ? city!
                          : l10n.homeLocationChoose,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(size: 15),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.notifications_none_rounded,
          tooltip: l10n.notifications,
          badge: unread,
          onTap: () => context.push(RouteNames.notifications),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Unread count shown as a lime bubble; hidden at 0.
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 22, color: AppColors.textSecondary),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    size: 10,
                    color: AppColors.onAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextNight extends StatelessWidget {
  const _NextNight({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat('EEE d MMM', locale).format(ticket.startAt);
    final days = ticket.daysUntil();
    final when = switch (days) {
      <= 0 => l10n.ticketToday,
      1 => l10n.ticketTomorrow,
      _ => l10n.ticketInDays(days),
    };
    final textColor = AppColors.onAccent.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: AppColors.accent,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: () => context.go(RouteNames.tickets),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        when.toUpperCase(),
                        style: AppTypography.label(color: textColor),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${ticket.eventName} · $date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          size: 15,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onAccent,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    l10n.homeOpenTicket,
                    style: AppTypography.display(
                      size: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Continue: birthday": what they last opened, one tap back to it.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.occasion,
    required this.count,
    required this.onTap,
  });

  final Occasion occasion;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = occasion.style;
    return Material(
      color: style.background,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: style.border),
          ),
          child: Row(
            children: [
              Icon(occasion.icon, color: style.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeContinue(
                        occasionLabel(l10n, occasion).toLowerCase(),
                      ),
                      style: AppTypography.display(size: 15),
                    ),
                    if (count != null)
                      Text(
                        l10n.homeIdeas(count!),
                        style: AppTypography.body(
                          size: 12,
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
        ),
      ),
    );
  }
}

/// The 3 x 2 grid: the occasions, then the dashed "All" tile.
class _OccasionGrid extends StatelessWidget {
  const _OccasionGrid({
    required this.tiles,
    required this.more,
    required this.onOccasion,
    required this.onAll,
  });

  final List<OccasionTileData> tiles;
  final int more;
  final ValueChanged<Occasion> onOccasion;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cells = <Widget>[
      for (final t in tiles)
        _OccasionTile(
          label: occasionLabel(l10n, t.occasion),
          sub: t.count == null ? null : l10n.homeIdeas(t.count!),
          style: t.occasion.style,
          icon: t.occasion.icon,
          onTap: () => onOccasion(t.occasion),
        ),
      _OccasionTile(
        label: l10n.occasionAll,
        sub: more > 0 ? l10n.homeMoreCount(more) : null,
        style: OccasionColors.other,
        icon: Icons.grid_view_rounded,
        dashed: true,
        onTap: onAll,
      ),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.98,
      children: cells,
    );
  }
}

class _OccasionTile extends StatelessWidget {
  const _OccasionTile({
    required this.label,
    required this.style,
    required this.icon,
    required this.onTap,
    this.sub,
    this.dashed = false,
  });

  final String label;
  final String? sub;
  final OccasionStyle style;
  final IconData icon;
  final bool dashed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: sub == null ? label : '$label, $sub',
      child: Material(
        color: dashed ? Colors.transparent : style.background,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: CustomPaint(
            painter: dashed ? _DashedBorder(style.border) : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: dashed
                  ? null
                  : BoxDecoration(
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: style.border),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: style.icon, size: 26),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(size: 15),
                      ),
                      if (sub != null)
                        Text(
                          sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(12),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

class _OneThingRow extends StatelessWidget {
  const _OneThingRow({required this.items, required this.onTap});

  final List<SingleBooking> items;
  final ValueChanged<SingleBooking> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final item = items[i];
          final label = categoryLabel(l10n, item.category);
          return Semantics(
            button: true,
            label: label,
            child: InkWell(
              borderRadius: AppRadius.brMd,
              onTap: () => onTap(item),
              child: SizedBox(
                width: 68,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Icon(
                        categoryIcon(item.category),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(size: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: AppTypography.display(size: 20)),
        ),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(action, style: AppTypography.body()),
          ),
        ),
      ],
    );
  }
}

/// Public events with a date badge.
class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.items});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          final start = item.eventStartAt;
          return InkWell(
            borderRadius: AppRadius.brMd,
            onTap: () => context.push(
              RouteNames.scheduledEventDetail,
              extra: item,
            ),
            child: SizedBox(
              width: 176,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 96,
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: start == null
                        ? const Icon(
                            Icons.event_outlined,
                            color: AppColors.textFaint,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat.MMM(locale)
                                      .format(start)
                                      .toUpperCase(),
                                  style: AppTypography.label(
                                    color: AppColors.accent,
                                  ),
                                ),
                                Text(
                                  '${start.day}',
                                  style: AppTypography.display(size: 20),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 15),
                  ),
                  if (item.city != null && item.city!.isNotEmpty)
                    Text(
                      item.city!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pulsing boxes in the shape of the "happening soon" row while it loads.
class _SoonSkeleton extends StatelessWidget {
  const _SoonSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 180, height: 22),
          SizedBox(height: 14),
          // Two cards share the width, so a narrow phone cannot overflow.
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 96)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 96)),
            ],
          ),
        ],
      ),
    );
  }
}
