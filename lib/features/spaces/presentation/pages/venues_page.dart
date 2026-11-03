import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_filters.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

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
      appBar: SpaceAppBar(title: l10n.spaceTabVenues),
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
                  child: ListingSearchField(
                    controller: _search,
                    hint: l10n.venuesSearchHint,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                ListingFilterBar(
                  counts: counts,
                  total: all.length,
                  selected: group,
                  onSelected: (g) => setState(() => _group = g),
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
                          itemBuilder: (context, i) => ListingCard(
                            listing: shown[i],
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
