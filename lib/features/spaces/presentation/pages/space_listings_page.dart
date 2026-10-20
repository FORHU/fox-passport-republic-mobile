import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

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
        actions: const [SpaceSwitchButton()],
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

  static String? statusLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        'draft' => l10n.listingStatusDraft,
        'pending' => l10n.listingStatusPending,
        'available' || 'published' => l10n.listingStatusLive,
        'rejected' => l10n.listingStatusRejected,
        'archived' => l10n.listingStatusArchived,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final label = statusLabel(context.l10n, item.status);
    final live = item.status == 'available' || item.status == 'published';
    final color = live
        ? AppColors.success
        : item.status == 'rejected'
            ? AppColors.error
            : AppColors.textMuted;

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
