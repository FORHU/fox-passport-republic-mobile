import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The Venue space's Venues tab: every venue the person runs, with where it
/// stands, and a way to add another. Tapping one opens its hub.
class VenuesPage extends ConsumerWidget {
  const VenuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (items) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(myVenuesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Room under the last card for the Add venue button.
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    l10n.listingsVenuesEmpty,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                )
              else
                for (final venue in items) ...[
                  VenueCard(
                    venue: venue,
                    onTap: () =>
                        context.push(RouteNames.spaceVenueHub(venue.id)),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A venue: its photo, name, town and status.
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PhotoBox(url: venue.imageUrl, width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(size: 15),
                    ),
                    if (venue.city != null)
                      Text(venue.city!, style: AppTypography.body(size: 12)),
                    if (label != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
