import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The order the status filters come in: what is live first, then what is
/// still waiting on something.
const _groupOrder = ['live', 'pending', 'draft', 'rejected', 'archived'];

String _groupLabel(AppLocalizations l10n, String group) => switch (group) {
      'live' => l10n.listingStatusLive,
      'pending' => l10n.listingStatusPending,
      'rejected' => l10n.listingStatusRejected,
      'archived' => l10n.listingStatusArchived,
      _ => l10n.listingStatusDraft,
    };

/// The Venue space's Venues tab: every venue the person runs, with where it
/// stands, a search and status filters for finding one among many, and a way
/// to add another. Tapping one opens its hub.
class VenuesPage extends ConsumerStatefulWidget {
  const VenuesPage({super.key});

  @override
  ConsumerState<VenuesPage> createState() => _VenuesPageState();
}

class _VenuesPageState extends ConsumerState<VenuesPage> {
  final _search = TextEditingController();
  String _query = '';

  /// The status group being shown; null shows them all.
  String? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venues = ref.watch(myVenuesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          l10n.spaceTabVenues,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.spaceVenueStudio),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.venueAddVenue),
      ),
      body: venues.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(myVenuesProvider),
        ),
        data: (all) {
          // A filter for a group that has since emptied must not hide
          // everything.
          final counts = <String, int>{};
          for (final v in all) {
            counts[v.group] = (counts[v.group] ?? 0) + 1;
          }
          final group = counts.containsKey(_group) ? _group : null;
          final shown = [
            for (final v in all)
              if ((group == null || v.group == group) && v.matches(_query)) v,
          ];

          return Column(
            children: [
              if (all.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.venuesSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.venuesSearchClear,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                if (counts.length > 1)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: l10n.venuesFilterAll(all.length),
                          selected: group == null,
                          onTap: () => setState(() => _group = null),
                        ),
                        for (final g in _groupOrder)
                          if (counts.containsKey(g))
                            _FilterChip(
                              label: '${_groupLabel(l10n, g)} ${counts[g]}',
                              selected: group == g,
                              onTap: () => setState(() => _group = g),
                            ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      shown.length == all.length
                          ? l10n.venuesCount(all.length)
                          : l10n.venuesCountOf(shown.length, all.length),
                      style: AppTypography.label(),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.refresh(myVenuesProvider.future),
                  child: shown.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 16,
                              ),
                              child: Text(
                                all.isEmpty
                                    ? l10n.listingsVenuesEmpty
                                    : l10n.venuesNoMatch,
                                textAlign: TextAlign.center,
                                style: AppTypography.body(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // Room under the last row for the Add venue button.
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => VenueCard(
                            venue: shown[i],
                            onTap: () => context
                                .push(RouteNames.spaceVenueHub(shown[i].id)),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.accent,
          labelStyle: AppTypography.label(
            color: selected ? AppColors.onAccent : AppColors.textPrimary,
          ),
        ),
      );
}

/// A venue in a compact row: its photo, name, and its town and status on one
/// line, so many of them fit on the screen.
class VenueCard extends StatelessWidget {
  const VenueCard({required this.venue, required this.onTap, super.key});

  final SpaceListing venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = listingStatusLabel(context.l10n, venue.status);
    final color = listingStatusColor(venue.status);
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PhotoBox(url: venue.imageUrl, width: 52, height: 52, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(size: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (venue.city != null)
                          Flexible(
                            child: Text(
                              venue.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(size: 12),
                            ),
                          ),
                        if (label != null) ...[
                          if (venue.city != null) const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: AppRadius.brPill,
                            ),
                            child: Text(
                              label,
                              style: AppTypography.label(color: color),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
