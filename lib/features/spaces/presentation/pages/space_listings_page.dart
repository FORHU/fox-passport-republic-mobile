import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

enum ListingKind { venues, events }

/// What you have listed: your venues in the Venue space, your events in the
/// Event space. Creating and editing them is on the web.
class SpaceListingsPage extends ConsumerWidget {
  const SpaceListingsPage({required this.kind, super.key});

  final ListingKind kind;

  FutureProvider<List<SpaceListing>> get _provider =>
      kind == ListingKind.venues ? myVenuesProvider : myEventsProvider;

  Future<void> _manageOnWeb(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp(
      kind == ListingKind.venues
          ? '/creator-dashboard/venues'
          : '/creator-dashboard/events',
    );
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final listings = ref.watch(_provider);
    final venues = kind == ListingKind.venues;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          venues ? l10n.spaceTabVenues : l10n.spaceTabEvents,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      body: listings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(_provider),
        ),
        data: (items) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(_provider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (!venues) ...[
                const _PartnersLink(),
                const SizedBox(height: 12),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    venues
                        ? l10n.listingsVenuesEmpty
                        : l10n.listingsEventsEmpty,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                )
              else
                for (final item in items) ...[
                  _ListingCard(item: item),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 8),
              SecondaryButton(
                label: l10n.spaceManageOnWeb,
                icon: Icons.open_in_new_rounded,
                onPressed: () => _manageOnWeb(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item});

  final SpaceListing item;

  @override
  Widget build(BuildContext context) {
    final label = listingStatusLabel(context.l10n, item.status);
    final color = listingStatusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          PhotoBox(url: item.imageUrl, width: 64, height: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
                if (item.city != null)
                  Text(item.city!, style: AppTypography.body(size: 12)),
              ],
            ),
          ),
          if (label != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.brPill,
              ),
              child: Text(label, style: AppTypography.label(color: color)),
            ),
        ],
      ),
    );
  }
}

/// Opens the venues the person's events can run at.
class _PartnersLink extends StatelessWidget {
  const _PartnersLink();

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push(RouteNames.spaceEventPartners),
        borderRadius: AppRadius.brCard,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.handshake_outlined, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.partnersOpenRow,
                  style: AppTypography.body(),
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
