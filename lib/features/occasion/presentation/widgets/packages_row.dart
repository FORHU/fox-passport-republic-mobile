import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart'
    show catalogPriceLabel;
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// A row of ready-made event packages: photo, name and price. Shared by the
/// Occasion page and Home. Tapping one opens its page.
class PackagesRow extends ConsumerWidget {
  const PackagesRow({required this.items, super.key});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final formatter = ref.watch(moneyFormatterProvider);
    return SizedBox(
      height: 212,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          final price = (item.price ?? 0) > 0
              ? catalogPriceLabel(
                  l10n,
                  item,
                  locale: locale,
                  formatter: formatter,
                )
              : null;
          return InkWell(
            borderRadius: AppRadius.brMd,
            onTap: () => context.push(RouteNames.eventDetail, extra: item),
            child: SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PhotoBox(
                      url: item.imageUrl,
                      height: 128,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price ?? l10n.occasionAskPrice,
                    style: AppTypography.body(
                      size: 13,
                      color: price == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
