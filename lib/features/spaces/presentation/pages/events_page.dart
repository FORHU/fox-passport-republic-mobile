import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_filters.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The Event space's first screen: what the person does most, what needs them
/// (venue invitations, and events in review, declined or unfinished), and every
/// event they run, with a search and status filters for finding one among many.
/// Tapping an event opens its page.
class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  final _search = TextEditingController();
  String _query = '';

  /// The status group being shown; null shows them all.
  String? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// What can be done with an event: edit it, or see the page guests see.
  Future<void> _openEvent(BuildContext context, SpaceListing event) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                event.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.esEditEvent),
              onTap: () {
                Navigator.of(sheet).pop();
                unawaited(
                  context.push(RouteNames.spaceEventStudioEdit(event.id)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: Text(l10n.esViewPublic),
              onTap: () {
                Navigator.of(sheet).pop();
                unawaited(
                  context.push(
                    RouteNames.eventDetail,
                    extra: CatalogItem(
                      id: event.id,
                      kind: CatalogKind.events,
                      title: event.name,
                      city: event.city,
                      imageUrl: event.imageUrl,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(myEventsProvider);
    final invites = ref.watch(partnersWaitingProvider(PartnerSide.eventFoxer));
    final partners = ref.watch(partnersProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          l10n.spaceTabEvents,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      body: events.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(myEventsProvider),
        ),
        data: (all) {
          // A filter for a group that has since emptied must not hide
          // everything.
          final counts = <String, int>{};
          for (final e in all) {
            counts[e.group] = (counts[e.group] ?? 0) + 1;
          }
          final group = counts.containsKey(_group) ? _group : null;
          final shown = [
            for (final e in all)
              if ((group == null || e.group == group) && e.matches(_query)) e,
          ];
          final inReview = counts['pending'] ?? 0;
          final declined = counts['rejected'] ?? 0;
          final drafts = counts['draft'] ?? 0;
          final somethingToDo =
              invites > 0 || inReview > 0 || declined > 0 || drafts > 0;

          void showGroup(String g) => setState(() => _group = g);

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref
                ..invalidate(partnersProvider)
                ..invalidate(myEventsProvider);
              try {
                await ref.read(myEventsProvider.future);
              } on Object {
                // The page shows its own error state with a retry.
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: QuickActionTile(
                                icon: Icons.qr_code_scanner_rounded,
                                label: l10n.venueQuickCheckIn,
                                onTap: () =>
                                    context.go(RouteNames.spaceEventCheckIn),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: QuickActionTile(
                                icon: Icons.handshake_outlined,
                                label: l10n.partnersOpenRow,
                                badge: invites,
                                onTap: () =>
                                    context.push(RouteNames.spaceEventPartners),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: QuickActionTile(
                                icon: Icons.add_circle_outline_rounded,
                                label: l10n.eventsNewOnWeb,
                                onTap: () => context.push(
                                  RouteNames.spaceEventStudio,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      HomeSectionHeader(title: l10n.overviewAttention),
                      if (partners.hasValue && !somethingToDo)
                        AllClearCard(text: l10n.overviewAllClear),
                      if (invites > 0)
                        AttentionRow(
                          icon: Icons.mail_outline_rounded,
                          color: AppColors.warning,
                          text: l10n.eventsInvitesWaiting(invites),
                          onTap: () =>
                              context.push(RouteNames.spaceEventPartners),
                        ),
                      if (declined > 0)
                        AttentionRow(
                          icon: Icons.error_outline_rounded,
                          color: AppColors.error,
                          text: l10n.eventsDeclined(declined),
                          onTap: () => showGroup('rejected'),
                        ),
                      if (inReview > 0)
                        AttentionRow(
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.textSecondary,
                          text: l10n.eventsInReview(inReview),
                          onTap: () => showGroup('pending'),
                        ),
                      if (drafts > 0)
                        AttentionRow(
                          icon: Icons.edit_note_rounded,
                          color: AppColors.textSecondary,
                          text: l10n.eventsDrafts(drafts),
                          onTap: () => showGroup('draft'),
                        ),
                      HomeSectionHeader(title: l10n.spaceTabEvents),
                      if (all.isNotEmpty) ...[
                        ListingSearchField(
                          controller: _search,
                          hint: l10n.eventsSearchHint,
                          onChanged: (v) => setState(() => _query = v),
                          onClear: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ]),
                  ),
                ),
                if (all.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListingFilterBar(
                          counts: counts,
                          total: all.length,
                          selected: group,
                          onSelected: (g) => setState(() => _group = g),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            shown.length == all.length
                                ? l10n.eventsCount(all.length)
                                : l10n.eventsCountOf(shown.length, all.length),
                            style: AppTypography.label(),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (shown.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 16,
                      ),
                      child: Text(
                        all.isEmpty
                            ? l10n.listingsEventsEmpty
                            : l10n.eventsNoMatch,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => ListingCard(
                        listing: shown[i],
                        onTap: () => _openEvent(context, shown[i]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
