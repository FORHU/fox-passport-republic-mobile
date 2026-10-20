import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/presentation/widgets/section_title.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/skeleton.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Venues to browse, in the chosen city: photo, name, where and how many it
/// holds, and the price. A placeholder while they load; nothing when there are
/// none or the call fails, so Home never shows an empty box.
class HomeVenues extends ConsumerWidget {
  const HomeVenues({required this.city, required this.onSeeAll, super.key});

  final String? city;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final venues = ref.watch(
      catalogProvider(CatalogQuery(CatalogKind.venues, limit: 6, city: city)),
    );
    final title = city == null || city!.isEmpty
        ? l10n.homeVenuesTitle
        : l10n.homeVenuesTitleIn(city!);

    return venues.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: SkeletonPulse(
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 112)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 112)),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (page) => page.items.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeSectionTitle(
                    title: title,
                    action: l10n.seeAll,
                    onAction: onSeeAll,
                  ),
                  const SizedBox(height: 4),
                  _VenueCards(items: page.items),
                ],
              ),
            ),
    );
  }
}

class _VenueCards extends ConsumerWidget {
  const _VenueCards({required this.items});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final formatter = ref.watch(moneyFormatterProvider);
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          final where = catalogSubtitle(l10n, item, locale: locale);
          final price = catalogPriceLabel(
            l10n,
            item,
            locale: locale,
            formatter: formatter,
          );
          return InkWell(
            borderRadius: AppRadius.brMd,
            onTap: () => context.push(RouteNames.venueDetail, extra: item),
            child: SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PhotoBox(url: item.imageUrl, height: 112),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 14),
                  ),
                  if (where.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(size: 12),
                    ),
                  ],
                  if (price != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.accent,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
