import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/follow/follow_button.dart';
import 'package:flutter_template/shared/foxers/foxer_profile.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// A Foxer: who they are, how they are rated, what they offer, and two ways
/// in: message them, or send a Match request for their kind of event.
class FoxerProfilePage extends ConsumerWidget {
  const FoxerProfilePage({required this.item, super.key});

  /// The row that was tapped; it names the Foxer while the rest loads.
  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(foxerProfileProvider(item));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(item.title, style: AppTypography.display()),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.foxerLoadFailed,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              TextButton(
                onPressed: () => ref.invalidate(foxerProfileProvider(item)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (profile) => _Loaded(item: item, profile: profile),
      ),
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.item, required this.profile});

  final CatalogItem item;
  final FoxerProfile profile;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  bool _opening = false;

  Future<void> _message() async {
    final l10n = context.l10n;
    final profile = widget.profile;
    if (profile.isSample) {
      showTopToast(context, l10n.messageSampleFoxer);
      return;
    }
    setState(() => _opening = true);
    try {
      final id =
          await ref.read(messagesRepositoryProvider).startWithUser(profile.id);
      ref.invalidate(conversationsProvider);
      if (mounted) unawaited(context.push(RouteNames.chat(id)));
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.messageStartFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _openOffer(CatalogItem offer) {
    switch (offer.kind) {
      case CatalogKind.events:
        unawaited(context.push(RouteNames.eventDetail, extra: offer));
      case CatalogKind.venues:
        unawaited(context.push(RouteNames.venueDetail, extra: offer));
      case CatalogKind.gear:
      case CatalogKind.services:
      case CatalogKind.foxers:
        // Gear and service pages are not built yet; a Match request covers
        // asking for them.
        showTopToast(context, context.l10n.comingSoonDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final profile = widget.profile;
    final role = foxerRoleLabel(l10n, profile.roles);
    final initial = profile.name.isEmpty ? '?' : profile.name[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            AvatarImage(
              url: profile.imageUrl,
              radius: 36,
              fallback: Text(initial, style: AppTypography.display(size: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: AppTypography.display(size: 22),
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  if (role != null)
                    Text(
                      role,
                      style: AppTypography.body(
                        color: AppColors.roleLabel,
                        weight: FontWeight.w600,
                      ),
                    ),
                  if (profile.place.isNotEmpty)
                    Text(
                      profile.place,
                      style: AppTypography.body(size: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              profile.rating == null
                  ? l10n.searchNew
                  : '${profile.rating!.toStringAsFixed(1)} · '
                      '${l10n.foxerReviews(profile.reviewCount)}',
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
          ],
        ),
        // A sample row is not a real account, so there is no one to follow.
        if (!profile.isSample) ...[
          const SizedBox(height: 12),
          FollowButton(userId: profile.id),
        ],
        if (profile.isSample) ...[
          const SizedBox(height: 8),
          Text(
            l10n.foxerSampleNote.toUpperCase(),
            style: AppTypography.label(),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push(
                    RouteNames.match,
                    extra: widget.item,
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                  ),
                  child: Text(
                    l10n.foxerMatchMe,
                    style: AppTypography.display(color: AppColors.onAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _opening ? null : _message,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  side: const BorderSide(color: AppColors.borderStrong),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(l10n.foxerMessage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(l10n.foxerOffers, style: AppTypography.display(size: 18)),
        const SizedBox(height: 12),
        if (profile.offers.isEmpty)
          Text(
            l10n.foxerNoOffers,
            style: AppTypography.body(color: AppColors.textMuted),
          )
        else
          for (final offer in profile.offers)
            _OfferRow(
              offer: offer,
              kindLabel: _kindLabel(l10n, offer.kind),
              price: catalogPriceLabel(
                l10n,
                offer,
                locale: locale,
                formatter: money,
              ),
              onTap: () => _openOffer(offer),
            ),
      ],
    );
  }

  static String _kindLabel(AppLocalizations l10n, CatalogKind kind) =>
      switch (kind) {
        CatalogKind.events => l10n.searchEvents,
        CatalogKind.venues => l10n.searchVenues,
        CatalogKind.gear => l10n.searchGear,
        CatalogKind.services => l10n.searchServices,
        CatalogKind.foxers => l10n.searchFoxers,
      };
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.offer,
    required this.kindLabel,
    required this.price,
    required this.onTap,
  });

  final CatalogItem offer;
  final String kindLabel;
  final String? price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PhotoBox(url: offer.imageUrl, width: 64, height: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kindLabel.toUpperCase(),
                      style: AppTypography.label(color: AppColors.accent),
                    ),
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(size: 15),
                    ),
                    if (price != null)
                      Text(price!, style: AppTypography.body(size: 13)),
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
