import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/data/last_occasion.dart';
import 'package:flutter_template/features/home/domain/home_categories.dart';
import 'package:flutter_template/features/home/presentation/widgets/category_labels.dart';
import 'package:flutter_template/features/home/presentation/widgets/occasion_showcase.dart';
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
              const SizedBox(height: 16),
              _HomeSearch(onTap: () => context.go(RouteNames.search)),
              const SizedBox(height: 22),
              Text(
                last == null ? l10n.homePlanning : l10n.homePlanNew,
                style: AppTypography.display(size: 20),
              ),
              const SizedBox(height: 12),
              OccasionShowcase(
                tiles: tiles,
                more: moreCategories(categories),
                city: area.city,
                continuing: last,
                onOccasion: openOccasion,
                onAll: () => unawaited(context.push(RouteNames.allCategories)),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// A search bar that opens the Search tab: the app's main job, one tap from
/// the first screen.
class _HomeSearch extends StatelessWidget {
  const _HomeSearch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hint = context.l10n.homeSearchHint;
    return Semantics(
      button: true,
      label: hint,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brPill,
        child: InkWell(
          borderRadius: AppRadius.brPill,
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(),
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
