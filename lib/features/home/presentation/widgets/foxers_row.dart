import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/presentation/widgets/section_title.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/skeleton.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Foxers who can plan or run an event, in the chosen city: a round photo,
/// name, where, and rating. Opens their profile, where Match me lives. A
/// placeholder while they load; nothing when there are none or it fails.
class HomeFoxers extends ConsumerWidget {
  const HomeFoxers({required this.city, required this.onSeeAll, super.key});

  final String? city;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final foxers = ref.watch(
      catalogProvider(CatalogQuery(CatalogKind.foxers, limit: 8, city: city)),
    );

    return foxers.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: SkeletonPulse(
          child: Row(
            children: [
              SkeletonBox(width: 72, height: 72),
              SizedBox(width: 12),
              SkeletonBox(width: 72, height: 72),
              SizedBox(width: 12),
              SkeletonBox(width: 72, height: 72),
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
                    title: l10n.homeFoxersTitle,
                    action: l10n.seeAll,
                    onAction: onSeeAll,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: page.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _FoxerCard(item: page.items[i]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FoxerCard extends StatelessWidget {
  const _FoxerCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final where = item.city;
    final rating = item.rating;
    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: () => context.push(RouteNames.foxer, extra: item),
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoBox(url: item.imageUrl, width: 112, height: 96),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(size: 14),
            ),
            if (where != null && where.isNotEmpty)
              Text(
                where,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(size: 12),
              ),
            if (rating != null && rating > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppTypography.body(size: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
