import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/domain/listing_draft.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_labels.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/studio_chrome.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart'
    show catalogPriceLabel;
import 'package:flutter_template/shared/catalog/listing_header.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A gear or service listing as guests will see it, built from what is in the
/// form right now (mobile#539). It makes no calls and books nothing; going
/// back returns to the form as it was.
class ListingPreviewPage extends ConsumerWidget {
  const ListingPreviewPage({
    required this.kind,
    required this.draft,
    super.key,
  });

  final ProviderKind kind;
  final ListingDraft draft;

  /// The draft as the catalog row the booking page would get, so the rate is
  /// worded the way guests read it.
  CatalogItem _asItem(String title) => CatalogItem(
        id: '',
        kind: kind.isGear ? CatalogKind.gear : CatalogKind.services,
        title: title,
        city: draft.city.trim().isEmpty ? null : draft.city.trim(),
        price: draft.price,
        currency: draft.currency,
        billingRate: draft.billingRate,
        imageUrl: draft.photos.isEmpty ? null : draft.photos.first.url,
        category: draft.category,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final catalog = ref.watch(providerSpecialtiesProvider).value;

    final name = draft.name.trim();
    final item = _asItem(name.isEmpty ? l10n.listingPreviewUntitled : name);
    final rate =
        catalogPriceLabel(l10n, item, locale: locale, formatter: money);
    final code = draft.category;
    String? category;
    if (code != null) {
      category = listingCategoryLabel(l10n, code);
      for (final s in catalog ?? const <ProviderSpecialty>[]) {
        // The name alone, as the booking page shows it, not "Group · name".
        if (s.slug == code) category = s.name;
      }
    }
    final place = [draft.city, draft.state, draft.country]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(', ');
    final description = draft.description.trim();
    final morePhotos = draft.photos.skip(1).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListingHeader(
              title: item.title,
              imageUrl: item.imageUrl,
              category: category,
              onBack: () => Navigator.of(context).pop(),
              subtitle: [
                if (item.city != null) item.city!,
                if (rate != null) rate,
              ].join(' · '),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Banner(text: l10n.listingPreviewBanner),
                  _Heading(l10n.listingPreviewAbout),
                  Text(
                    description.isEmpty
                        ? l10n.listingPreviewNoDescription
                        : description,
                    style: AppTypography.body(
                      color: description.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  _Heading(l10n.listingWhere),
                  Text(
                    place.isEmpty ? l10n.listingPreviewNoPlace : place,
                    style: AppTypography.body(
                      color: place.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (!kind.isGear && draft.willingToTravel) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.listingPreviewTravels,
                      style: AppTypography.body(color: AppColors.accent),
                    ),
                  ],
                  if (kind.isGear) ...[
                    _Heading(l10n.listingCondition),
                    Text(
                      '${listingConditionLabel(l10n, draft.condition)} · '
                      '${l10n.listingPreviewAvailable(draft.quantity)}',
                      style: AppTypography.body(),
                    ),
                  ],
                  if (morePhotos.isNotEmpty) ...[
                    _Heading(l10n.listingPreviewPhotos),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: morePhotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => PhotoBox(
                          url: morePhotos[i].url,
                          width: 96,
                          height: 96,
                          radius: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StudioBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.listingPreviewBookOff,
              textAlign: TextAlign.center,
              style: AppTypography.body(size: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            AppButton(label: l10n.itemBookBook, onPressed: null),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentTintBg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.accentTintBorder),
        ),
        child: Text(text, style: AppTypography.body(size: 13)),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(text, style: AppTypography.display(size: 18)),
      );
}
