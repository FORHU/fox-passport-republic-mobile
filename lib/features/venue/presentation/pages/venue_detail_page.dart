import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:flutter_template/features/venue/data/venue_repository.dart';
import 'package:flutter_template/features/venue/domain/venue_detail.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/location_card.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// One venue: photos, what it holds and costs, what is included, and the
/// rules, with "Book now" pinned to the bottom.
class VenueDetailPage extends ConsumerWidget {
  const VenueDetailPage({required this.item, super.key});

  /// The row the citizen tapped; it names the venue while the rest loads.
  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(venueDetailProvider(item));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.title, style: AppTypography.display(size: 18)),
                      const SizedBox(height: 8),
                      Text(
                        l10n.venueLoadFailed,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(venueDetailProvider(item)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (venue) => _Loaded(item: item, venue: venue),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.item, required this.venue});

  final CatalogItem item;
  final VenueDetail venue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);

    final priced = CatalogItem(
      id: item.id,
      kind: CatalogKind.venues,
      title: venue.name,
      price: venue.price,
      currency: venue.currency,
      billingRate: venue.billingRate,
    );
    final priceLabel = catalogPriceLabel(
      l10n,
      priced,
      locale: locale,
      formatter: money,
    );
    final category = venue.spaceTypes.isNotEmpty
        ? spaceTypeLabel(l10n, venue.spaceTypes.first)
        : venue.category == null
            ? null
            : spaceTypeLabel(l10n, venue.category!);

    // What is included: the named inclusions, else the tech and staff lists.
    final included = venue.inclusions.isNotEmpty
        ? venue.inclusions
        : [...venue.techAv, ...venue.staffing];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Gallery(
                urls: venue.imageUrls.isEmpty
                    ? [if (item.imageUrl != null) item.imageUrl!]
                    : venue.imageUrls,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null)
                      Text(
                        category.toUpperCase(),
                        style: AppTypography.label(color: AppColors.accent),
                      ),
                    const SizedBox(height: 4),
                    Text(venue.name, style: AppTypography.display(size: 26)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        if (venue.place.isNotEmpty)
                          _Meta(Icons.place_outlined, venue.place),
                        if (venue.capacity != null)
                          _Meta(
                            Icons.groups_outlined,
                            l10n.venueUpTo(venue.capacity!),
                          ),
                        if (venue.hostName != null)
                          _Meta(
                            Icons.person_outline_rounded,
                            l10n.eventHostedBy(venue.hostName!),
                          ),
                      ],
                    ),
                    if (venue.address != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        venue.address!,
                        style: AppTypography.body(size: 13),
                      ),
                    ],
                    if (venue.isSample) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.venueSampleNote.toUpperCase(),
                        style: AppTypography.label(),
                      ),
                    ],
                    if (venue.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        venue.description!,
                        style: AppTypography.body(),
                      ),
                    ],
                    LocationCard(
                      title: l10n.searchEventLocation,
                      place: venue.place,
                      lat: venue.lat,
                      lng: venue.lng,
                    ),
                    _Chips(title: l10n.venueIncluded, values: included),
                    _Chips(title: l10n.venueAmenities, values: venue.amenities),
                    _Chips(
                      title: l10n.venueFacilities,
                      values: venue.facilities,
                    ),
                    if (venue.policies.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.venueRules,
                        style: AppTypography.display(size: 18),
                      ),
                      const SizedBox(height: 10),
                      for (final rule in venue.policies)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rule,
                                  style: AppTypography.body(size: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (venue.hasGoodToKnow) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.venueGoodToKnow,
                        style: AppTypography.display(size: 18),
                      ),
                      const SizedBox(height: 10),
                      if (venue.parking != null)
                        _Fact(l10n.venueParking, venue.parking!),
                      if (venue.accessibility != null)
                        _Fact(l10n.venueAccessibility, venue.accessibility!),
                      if (venue.entrance != null)
                        _Fact(l10n.venueEntrance, venue.entrance!),
                    ],
                    if (!venue.isSample) ReviewsSection(listingId: venue.id),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: priceLabel == null
                      ? const SizedBox.shrink()
                      : Text(
                          priceLabel,
                          style: AppTypography.display(size: 18),
                        ),
                ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      RouteNames.book,
                      extra: CatalogItem(
                        id: venue.id,
                        kind: CatalogKind.venues,
                        title: venue.name,
                        city: venue.city,
                        capacity: venue.capacity,
                        price: venue.price,
                        currency: venue.currency,
                        billingRate: venue.billingRate,
                        imageUrl: venue.imageUrls.isEmpty
                            ? item.imageUrl
                            : venue.imageUrls.first,
                        isSample: venue.isSample,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      // The theme makes buttons full width; a Row cannot hold
                      // that, so size it here.
                      minimumSize: const Size(140, 52),
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                    child: Text(
                      l10n.venueBookNow,
                      style: AppTypography.display(color: AppColors.onAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Swipeable photos with the back button on top; one placeholder when there
/// are none.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls});

  final List<String> urls;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned.fill(
            child: urls.length <= 1
                ? SizedBox(
                    width: double.infinity,
                    child: PhotoBox(
                      url: urls.isEmpty ? null : urls.first,
                      height: 260,
                      radius: 0,
                    ),
                  )
                : PageView.builder(
                    itemCount: urls.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => SizedBox(
                      width: double.infinity,
                      child: PhotoBox(url: urls[i], height: 260, radius: 0),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: AppColors.canvas.withValues(alpha: 0.7),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: context.l10n.bookBack,
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < urls.length; i++)
                    Container(
                      width: i == _page ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.accent
                            : AppColors.textPrimary.withValues(alpha: 0.5),
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(child: Text(text, style: AppTypography.body(size: 13))),
        ],
      );
}

class _Chips extends StatelessWidget {
  const _Chips({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.display(size: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brPill,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    v,
                    style: AppTypography.body(
                      size: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTypography.label()),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.body(size: 13)),
          ],
        ),
      );
}
