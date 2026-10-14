import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/favorites/data/favorites_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Search: one box, one switch for what you are looking for, compact rows.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({this.initialKind = CatalogKind.venues, super.key});

  /// What the switch starts on; Home's tiles deep-link here.
  final CatalogKind initialKind;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  late CatalogKind _kind = widget.initialKind;
  String _query = '';
  Timer? _debounce;

  /// Kept local only for explicit mock-mode demos.
  final Set<String> _saved = {};

  @override
  void didUpdateWidget(SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shell keeps this page alive, so a new deep link arrives as an update.
    if (oldWidget.initialKind != widget.initialKind) {
      setState(() => _kind = widget.initialKind);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  /// The three choices at the top. Gear and services are things Foxers
  /// supply, so they sit under Foxers rather than beside it.
  static const List<CatalogKind> _topKinds = [
    CatalogKind.events,
    CatalogKind.venues,
    CatalogKind.foxers,
  ];
  static const List<CatalogKind> _peopleKinds = [
    CatalogKind.foxers,
    CatalogKind.gear,
    CatalogKind.services,
  ];

  static bool _isPeopleGroup(CatalogKind kind) => _peopleKinds.contains(kind);

  static CatalogKind _group(CatalogKind kind) =>
      _isPeopleGroup(kind) ? CatalogKind.foxers : kind;

  String _scopeLabel(AppLocalizations l10n, CatalogKind kind) => switch (kind) {
        CatalogKind.gear => l10n.searchGear,
        CatalogKind.services => l10n.searchServices,
        _ => l10n.searchPeople,
      };

  String _kindLabel(AppLocalizations l10n, CatalogKind kind) => switch (kind) {
        CatalogKind.events => l10n.searchEvents,
        CatalogKind.venues => l10n.searchVenues,
        CatalogKind.foxers => l10n.searchFoxers,
        CatalogKind.gear => l10n.searchGear,
        CatalogKind.services => l10n.searchServices,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favorites = ref.watch(favoriteIdsProvider);
    final formatter = ref.watch(moneyFormatterProvider);
    final results = ref.watch(
      catalogProvider(CatalogQuery(_kind, query: _query)),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SearchField(
                    controller: _controller,
                    hint: l10n.searchHint,
                    onChanged: _onQuery,
                    onFilters: () =>
                        showTopToast(context, l10n.comingSoonFilters),
                    filtersLabel: l10n.searchFilters,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SegmentedPills<CatalogKind>(
                    value: _group(_kind),
                    onChanged: (k) => setState(() {
                      // Back to Foxers lands on whichever of its three kinds
                      // was last open.
                      _kind = k == CatalogKind.foxers && _isPeopleGroup(_kind)
                          ? _kind
                          : k;
                    }),
                    options: [
                      for (final k in _topKinds)
                        SegmentOption(k, _kindLabel(l10n, k)),
                    ],
                  ),
                ),
                if (_isPeopleGroup(_kind))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        for (final k in _peopleKinds) ...[
                          _ScopeChip(
                            label: _scopeLabel(l10n, k),
                            selected: _kind == k,
                            onTap: () => setState(() => _kind = k),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: results.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                    error: (_, __) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.apiLoadFailed,
                            style: AppTypography.body(),
                          ),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              catalogProvider(
                                CatalogQuery(_kind, query: _query),
                              ),
                            ),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                    data: (page) => _Results(
                      formatter: formatter,
                      page: page,
                      kindLabel: _kindLabel(l10n, _kind),
                      query: _query,
                      saved: AppConfig.instance.useMock
                          ? _saved
                          : favorites.asData?.value ?? const {},
                      favoritesFailed:
                          favorites.hasError && !AppConfig.instance.useMock,
                      favoritesLoading:
                          favorites.isLoading && !AppConfig.instance.useMock,
                      onToggleSaved: _toggleFavorite,
                      onOpen: (item) => switch (item.kind) {
                        CatalogKind.venues =>
                          context.push(RouteNames.venueDetail, extra: item),
                        CatalogKind.events =>
                          context.push(RouteNames.eventDetail, extra: item),
                        _ => showTopToast(context, l10n.comingSoonDetails),
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: _MapPill(
                  label: l10n.searchMap,
                  onTap: () => showTopToast(context, l10n.comingSoonMap),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(CatalogItem item) async {
    if (AppConfig.instance.useMock) {
      setState(() {
        if (!_saved.add(item.id)) _saved.remove(item.id);
      });
      return;
    }

    final l10n = context.l10n;
    if (ref.read(authControllerProvider).user == null) {
      showTopToast(context, l10n.signInToContinue);
      return;
    }

    final saved =
        ref.read(favoriteIdsProvider).asData?.value ?? const <String>{};
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      if (saved.contains(item.id)) {
        await repository.remove(item);
      } else {
        await repository.add(item);
      }
      ref.invalidate(favoriteIdsProvider);
    } on AppException catch (error) {
      if (mounted) showTopToast(context, error.message);
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onFilters,
    required this.filtersLabel,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilters;
  final String filtersLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.accent,
              style: AppTypography.body(
                color: AppColors.textPrimary,
                size: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.body(
                  color: AppColors.textMuted,
                  size: 15,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            tooltip: filtersLabel,
            onPressed: onFilters,
            icon: const Icon(
              Icons.tune_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.formatter,
    required this.page,
    required this.kindLabel,
    required this.query,
    required this.saved,
    required this.favoritesFailed,
    required this.favoritesLoading,
    required this.onToggleSaved,
    required this.onOpen,
  });

  final CatalogPage page;
  final String kindLabel;
  final String query;
  final Set<String> saved;
  final bool favoritesFailed;
  final bool favoritesLoading;
  final ValueChanged<CatalogItem> onToggleSaved;
  final ValueChanged<CatalogItem> onOpen;
  final MoneyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (page.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.searchNoMatches(query),
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toString();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: page.items.length + 1 + (favoritesFailed ? 1 : 0),
      separatorBuilder: (_, i) => i == 0
          ? const SizedBox(height: 4)
          : const Divider(color: AppColors.border, height: 24),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${page.total} ${kindLabel.toUpperCase()}',
            style: AppTypography.label(),
          );
        }
        if (favoritesFailed && index == 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.apiLoadFailed,
              style: AppTypography.label(color: AppColors.warning),
            ),
          );
        }
        final itemIndex = index - 1 - (favoritesFailed ? 1 : 0);
        final item = page.items[itemIndex];
        return _CatalogCard(
          item: item,
          kindLabel: kindLabel,
          subtitle: catalogSubtitle(l10n, item),
          price: catalogPriceLabel(
            l10n,
            item,
            locale: locale,
            formatter: formatter,
          ),
          saved: saved.contains(item.id),
          canFavorite: item.kind == CatalogKind.events ||
              item.kind == CatalogKind.venues,
          favoriteEnabled: !favoritesLoading,
          onToggleSaved: () => onToggleSaved(item),
          onTap: () => onOpen(item),
        );
      },
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.kindLabel,
    required this.subtitle,
    required this.price,
    required this.saved,
    required this.canFavorite,
    required this.favoriteEnabled,
    required this.onToggleSaved,
    required this.onTap,
  });

  final CatalogItem item;
  final String kindLabel;
  final String subtitle;
  final String? price;
  final bool saved;
  final bool canFavorite;
  final bool favoriteEnabled;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = item.rating;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoBox(url: item.imageUrl, height: 160, radius: 18),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: AppRadius.brPill,
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Text(
                        item.tags.isNotEmpty
                            ? spaceTypeLabel(context.l10n, item.tags.first)
                            : (item.category?.isNotEmpty ?? false)
                                ? categoryLabel(item.category!)
                                : kindLabel,
                        style:
                            AppTypography.label(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  if (canFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: AppColors.canvas,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: favoriteEnabled ? onToggleSaved : null,
                          tooltip: saved
                              ? context.l10n.searchRemoveSavedItem
                              : context.l10n.searchSaveItem,
                          icon: Icon(
                            saved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: saved
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
              ),
              if (rating != null) ...[
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 17,
                ),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTypography.display(size: 12),
                ),
              ] else
                Text(
                  context.l10n.searchNew,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    size: 12,
                  ),
                ),
              ),
              if (price case final priceLabel?) ...[
                const SizedBox(width: 8),
                Text(priceLabel, style: AppTypography.display(size: 13)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentTintBg : Colors.transparent,
            borderRadius: AppRadius.brPill,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderStrong,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body(
              size: 13,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: AppRadius.brPill,
      elevation: 6,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  size: 18, color: AppColors.onLightSurface,),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.display(
                    size: 15, color: AppColors.onLightSurface,),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
