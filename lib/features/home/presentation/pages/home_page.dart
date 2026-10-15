import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/area_sheet.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Home: your next night first, then where to look, then picks.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final upcomingTickets = ref.watch(upcomingTicketsProvider);
    final ticket = upcomingTickets.value?.firstOrNull;
    final area = ref.watch(areaFilterProvider);
    final picksQuery = CatalogQuery(
      CatalogKind.venues,
      limit: 8,
      city: area.city,
      lat: area.lat,
      lng: area.lng,
    );
    final foxersQuery = CatalogQuery(
      CatalogKind.foxers,
      limit: 8,
      city: area.city,
    );
    final picks = ref.watch(catalogProvider(picksQuery));
    final foxers = ref.watch(catalogProvider(foxersQuery));
    final areaSource = ref.watch(areaProvider.select((a) => a.source));
    final unread = ref.watch(notificationInboxProvider).value?.unreadCount ?? 0;

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
              ..invalidate(catalogProvider(picksQuery))
              ..invalidate(catalogProvider(foxersQuery));
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
              const SizedBox(height: 14),
              _HomeSearchBar(
                label: l10n.homeSearchPlanning,
                onTap: () => context.go(RouteNames.search),
              ),
              const SizedBox(height: 12),
              _EventTypeChips(),
              if (upcomingTickets.hasError)
                _InlineLoadError(
                  message: l10n.apiLoadFailed,
                  retryLabel: l10n.retry,
                  onRetry: () => ref.invalidate(upcomingTicketsProvider),
                )
              else if (ticket != null)
                _NextNight(ticket: ticket),
              const SizedBox(height: 22),
              _SectionTitle(
                title: l10n.homeVenuesNear,
                action: l10n.seeAll,
                onAction: () =>
                    context.go(RouteNames.searchFor(CatalogKind.venues.name)),
              ),
              const SizedBox(height: 12),
              _Picks(
                formatter: ref.watch(moneyFormatterProvider),
                state: picks,
                onRetry: () => ref.invalidate(catalogProvider(picksQuery)),
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: l10n.homeFoxersForNight,
                action: l10n.seeAll,
                onAction: () =>
                    context.go(RouteNames.searchFor(CatalogKind.foxers.name)),
              ),
              const SizedBox(height: 12),
              _Foxers(
                state: foxers,
                onRetry: () => ref.invalidate(catalogProvider(foxersQuery)),
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

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
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
                  size: 19,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EventTypeChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (l10n.homeEventWedding, CatalogKind.events),
      (l10n.homeEventBirthday, CatalogKind.events),
      (l10n.homeEventCorporate, CatalogKind.events),
      (l10n.homeEventSocial, CatalogKind.events),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => InkWell(
          borderRadius: AppRadius.brPill,
          onTap: () => context.go(
            RouteNames.searchFor(options[index].$2.name),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Text(
              options[index].$1,
              style: AppTypography.body(
                size: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
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
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(size: 20),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              action,
              style: AppTypography.body(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Picks extends StatelessWidget {
  const _Picks({
    required this.state,
    required this.onRetry,
    required this.formatter,
  });

  final MoneyFormatter formatter;

  final AsyncValue<CatalogPage> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return state.when(
      loading: () => const SizedBox(
        height: 190,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (_, __) => _InlineLoadError(
        message: l10n.apiLoadFailed,
        retryLabel: l10n.retry,
        onRetry: onRetry,
      ),
      data: (page) => _buildItems(context, page.items, l10n, locale),
    );
  }

  Widget _buildItems(
    BuildContext context,
    List<CatalogItem> items,
    AppLocalizations l10n,
    String locale,
  ) {
    if (items.isEmpty) {
      return _EmptyRow(
        icon: Icons.storefront_outlined,
        message: l10n.homeEmptyVenues,
        actionLabel: l10n.homeEmptyVenuesAction,
        onAction: () => context.go(RouteNames.searchFor('venues')),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final price = catalogPriceLabel(
            l10n,
            item,
            locale: locale,
            formatter: formatter,
          );
          return InkWell(
            onTap: () => context.push(
              item.kind == CatalogKind.events
                  ? RouteNames.eventDetail
                  : RouteNames.venueDetail,
              extra: item,
            ),
            borderRadius: AppRadius.brMd,
            child: SizedBox(
              width: 168,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A Column that aligns to the start gives its children loose
                  // width, so without this the photo shrinks to its icon.
                  SizedBox(
                    width: double.infinity,
                    child:
                        PhotoBox(url: item.imageUrl, height: 120, radius: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 15),
                  ),
                  if (price != null)
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(),
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

/// An empty list that still says what to do next.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// "Foxers for your night": one row per Foxer, with a button to message them.
class _Foxers extends StatelessWidget {
  const _Foxers({required this.state, required this.onRetry});

  final AsyncValue<CatalogPage> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return state.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (_, __) => _InlineLoadError(
        message: l10n.apiLoadFailed,
        retryLabel: l10n.retry,
        onRetry: onRetry,
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return _EmptyRow(
            icon: Icons.groups_outlined,
            message: l10n.homeEmptyFoxers,
            actionLabel: l10n.homeEmptyFoxersAction,
            onAction: () => context.push(RouteNames.roles),
          );
        }
        return Column(
          children: [
            for (final item in page.items.take(3)) ...[
              _FoxerRow(item: item),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _FoxerRow extends ConsumerWidget {
  const _FoxerRow({required this.item});

  final CatalogItem item;

  Future<void> _message(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (item.isSample) {
      showTopToast(context, l10n.messageSampleFoxer);
      return;
    }
    try {
      final id =
          await ref.read(messagesRepositoryProvider).startWithUser(item.id);
      ref.invalidate(conversationsProvider);
      if (context.mounted) unawaited(context.push(RouteNames.chat(id)));
    } on Object catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.messageStartFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = foxerRoleLabel(l10n, item.roles);
    final rating = item.rating;
    final initial = item.title.isEmpty ? '?' : item.title[0].toUpperCase();

    return InkWell(
      onTap: () => context.push(RouteNames.foxer, extra: item),
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceRaised,
                  backgroundImage: item.imageUrl == null
                      ? null
                      : NetworkImage(resolveAssetUrl(item.imageUrl!)),
                  child: item.imageUrl == null
                      ? Text(initial, style: AppTypography.display())
                      : null,
                ),
                if (item.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(size: 15),
                        ),
                      ),
                      if (item.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  if (role != null || rating != null)
                    Text(
                      [
                        if (role != null) role,
                        if (rating != null) rating.toStringAsFixed(1),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.roleLabel,
                        weight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.homeMessageFoxer(item.title),
              onPressed: () => _message(context, ref),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(
                  size: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      );
}
