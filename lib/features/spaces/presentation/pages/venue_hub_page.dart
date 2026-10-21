import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// One venue and what the person can do with it: edit its details, see and
/// close its days, and see how guests see it.
class VenueHubPage extends ConsumerWidget {
  const VenueHubPage({required this.venueId, super.key});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final venues = ref.watch(myVenuesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(),
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
        data: (items) {
          final venue = items.where((v) => v.id == venueId).firstOrNull;
          if (venue == null) {
            return AppStateView(
              kind: AppStateKind.notFound,
              title: l10n.apiLoadFailed,
            );
          }
          return _Hub(
            venue: venue,
            onEdit: () =>
                context.push(RouteNames.spaceVenueStudioEdit(venueId)),
            onAvailability: () => context.go(
              '${RouteNames.spaceVenueCalendar}?venue=${venue.id}',
            ),
            onPublic: () => context.push(
              RouteNames.venueDetail,
              extra: CatalogItem(
                id: venue.id,
                kind: CatalogKind.venues,
                title: venue.name,
                city: venue.city,
                imageUrl: venue.imageUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({
    required this.venue,
    required this.onEdit,
    required this.onAvailability,
    required this.onPublic,
  });

  final SpaceListing venue;
  final VoidCallback onEdit;
  final VoidCallback onAvailability;
  final VoidCallback onPublic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = listingStatusLabel(l10n, venue.status);
    final color = listingStatusColor(venue.status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        ClipRRect(
          borderRadius: AppRadius.brCard,
          child: PhotoBox(
            url: venue.imageUrl,
            width: double.infinity,
            height: 200,
          ),
        ),
        const SizedBox(height: 14),
        Text(venue.name, style: AppTypography.display(size: 24)),
        if (venue.city != null)
          Text(venue.city!, style: AppTypography.body(size: 13)),
        if (label != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.brPill,
              ),
              child: Text(label, style: AppTypography.label(color: color)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _HubRow(
          icon: Icons.edit_outlined,
          title: l10n.venueHubEdit,
          hint: l10n.venueHubEditHint,
          onTap: onEdit,
        ),
        const SizedBox(height: 8),
        _HubRow(
          icon: Icons.calendar_month_outlined,
          title: l10n.venueHubAvailability,
          hint: l10n.venueHubAvailabilityHint,
          onTap: onAvailability,
        ),
        const SizedBox(height: 8),
        _HubRow(
          icon: Icons.visibility_outlined,
          title: l10n.venueHubPublic,
          hint: l10n.venueHubPublicHint,
          onTap: onPublic,
        ),
      ],
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.display(size: 15)),
                  Text(hint, style: AppTypography.body(size: 12)),
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
    );
  }
}
