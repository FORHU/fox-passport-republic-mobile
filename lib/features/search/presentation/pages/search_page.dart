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
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Search: one box, one switch for what you are looking for, compact rows.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    this.initialKind = CatalogKind.venues,
    this.initialCity,
    super.key,
  });

  /// What the switch starts on; Home's tiles deep-link here.
  final CatalogKind initialKind;

  /// Narrow to this city, e.g. from a pin on the Map.
  final String? initialCity;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  late CatalogKind _kind = widget.initialKind;
  late String? _city = widget.initialCity;
  String _query = '';
  num? _minPrice;
  num? _maxPrice;
  int? _minCapacity;
  DateTime? _fromDate;
  DateTime? _toDate;
  late String _sortBy =
      widget.initialKind == CatalogKind.events ? 'date_asc' : '';
  Timer? _debounce;

  /// Kept local only for explicit mock-mode demos.
  final Set<String> _saved = {};

  @override
  void didUpdateWidget(SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shell keeps this page alive, so a new deep link arrives as an update.
    if (oldWidget.initialKind != widget.initialKind ||
        oldWidget.initialCity != widget.initialCity) {
      setState(() {
        _kind = widget.initialKind;
        _city = widget.initialCity;
      });
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

  CatalogQuery get _catalogQuery => CatalogQuery(
        _kind,
        query: _query,
        city: _city,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minCapacity: _minCapacity,
        fromDate: _fromDate,
        toDate: _toDate,
        sortBy: _sortBy.isEmpty ? null : _sortBy,
      );

  /// Anything narrowing the list: words, a city, a range or dates.
  bool get _hasFilters =>
      _query.isNotEmpty ||
      _city != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _minCapacity != null ||
      _fromDate != null ||
      _toDate != null;

  void _clearFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _city = null;
      _minPrice = null;
      _maxPrice = null;
      _minCapacity = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _openFilters() async {
    final filters = await showModalBottomSheet<_SearchFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FilterSheet(
        kind: _kind,
        initial: _SearchFilters(
          city: _city,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          minCapacity: _minCapacity,
          fromDate: _fromDate,
          toDate: _toDate,
          sortBy: _sortBy,
        ),
      ),
    );
    if (filters == null || !mounted) return;
    setState(() {
      _city = filters.city;
      _minPrice = filters.minPrice;
      _maxPrice = filters.maxPrice;
      _minCapacity = filters.minCapacity;
      _fromDate = filters.fromDate;
      _toDate = filters.toDate;
      _sortBy = filters.sortBy;
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
    final results = ref.watch(catalogProvider(_catalogQuery));

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
                    onFilters: _openFilters,
                    filtersLabel: l10n.searchFilters,
                    showFilters: _kind == CatalogKind.events ||
                        _kind == CatalogKind.venues,
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
                      _sortBy = _kind == CatalogKind.events ? 'date_asc' : '';
                    }),
                    options: [
                      for (final k in _topKinds)
                        SegmentOption(k, _kindLabel(l10n, k)),
                    ],
                  ),
                ),
                if (_city != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        avatar: const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        label: Text(_city!),
                        onDeleted: () => setState(() => _city = null),
                      ),
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
                    error: (_, __) => AppStateView(
                      kind: AppStateKind.error,
                      title: l10n.apiLoadFailed,
                      actionLabel: l10n.retry,
                      onAction: () =>
                          ref.invalidate(catalogProvider(_catalogQuery)),
                    ),
                    data: (page) => _Results(
                      formatter: formatter,
                      page: page,
                      kindLabel: _kindLabel(l10n, _kind),
                      query: _query,
                      locale: Localizations.localeOf(context).toString(),
                      saved: AppConfig.instance.useMock
                          ? _saved
                          : favorites.asData?.value ?? const {},
                      favoritesFailed:
                          favorites.hasError && !AppConfig.instance.useMock,
                      favoritesLoading:
                          favorites.isLoading && !AppConfig.instance.useMock,
                      onToggleSaved: _toggleFavorite,
                      onClear: _hasFilters ? _clearFilters : null,
                      onOpen: (item) => switch (item.kind) {
                        CatalogKind.venues =>
                          context.push(RouteNames.venueDetail, extra: item),
                        CatalogKind.events => context.push(
                            RouteNames.scheduledEventDetail,
                            extra: item,
                          ),
                        CatalogKind.foxers =>
                          context.push(RouteNames.foxer, extra: item),
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

class _SearchFilters {
  const _SearchFilters({
    required this.sortBy,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.minCapacity,
    this.fromDate,
    this.toDate,
  });

  final String? city;
  final num? minPrice;
  final num? maxPrice;
  final int? minCapacity;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String sortBy;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.kind, required this.initial});

  final CatalogKind kind;
  final _SearchFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final _city = TextEditingController(text: widget.initial.city ?? '');
  late final _minPrice =
      TextEditingController(text: widget.initial.minPrice?.toString() ?? '');
  late final _maxPrice =
      TextEditingController(text: widget.initial.maxPrice?.toString() ?? '');
  late final _minCapacity = TextEditingController(
    text: widget.initial.minCapacity?.toString() ?? '',
  );
  late DateTime? _fromDate = widget.initial.fromDate;
  late DateTime? _toDate = widget.initial.toDate;
  late String _sortBy = widget.initial.sortBy;
  String? _error;

  @override
  void dispose() {
    _city.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _minCapacity.dispose();
    super.dispose();
  }

  Future<void> _chooseDates() async {
    final now = DateTime.now();
    final initialRange = _fromDate != null && _toDate != null
        ? DateTimeRange(
            start: _fromDate!,
            end: _toDate!.subtract(const Duration(days: 1)),
          )
        : null;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3, now.month, now.day),
      initialDateRange: initialRange,
    );
    if (range == null) return;
    setState(() {
      _fromDate = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      _toDate = DateTime(
        range.end.year,
        range.end.month,
        range.end.day + 1,
      );
    });
  }

  void _apply() {
    final l10n = context.l10n;
    final minPrice = _minPrice.text.trim().isEmpty
        ? null
        : num.tryParse(_minPrice.text.trim());
    final maxPrice = _maxPrice.text.trim().isEmpty
        ? null
        : num.tryParse(_maxPrice.text.trim());
    final minCapacity = _minCapacity.text.trim().isEmpty
        ? null
        : int.tryParse(_minCapacity.text.trim());
    if ((_minPrice.text.trim().isNotEmpty && minPrice == null) ||
        (_maxPrice.text.trim().isNotEmpty && maxPrice == null) ||
        (_minCapacity.text.trim().isNotEmpty && minCapacity == null) ||
        (minPrice != null && minPrice < 0) ||
        (maxPrice != null && maxPrice < 0) ||
        (minCapacity != null && minCapacity < 1) ||
        (minPrice != null && maxPrice != null && minPrice > maxPrice)) {
      setState(() => _error = l10n.searchInvalidFilter);
      return;
    }

    Navigator.of(context).pop(
      _SearchFilters(
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        minPrice: minPrice,
        maxPrice: maxPrice,
        minCapacity: minCapacity,
        fromDate: _fromDate,
        toDate: _toDate,
        sortBy: _sortBy,
      ),
    );
  }

  void _clear() {
    Navigator.of(context).pop(
      _SearchFilters(
        sortBy: widget.kind == CatalogKind.events ? 'date_asc' : '',
      ),
    );
  }

  String _sortLabel(AppLocalizations l10n, String value) => switch (value) {
        'price_asc' => l10n.searchSortPriceLow,
        'price_desc' => l10n.searchSortPriceHigh,
        'date_desc' => l10n.searchSortDateLatest,
        'date_asc' => l10n.searchSortDateSoonest,
        _ => l10n.searchSortRecommended,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEvent = widget.kind == CatalogKind.events;
    final sortOptions = isEvent
        ? const ['date_asc', 'date_desc', 'price_asc', 'price_desc']
        : const ['', 'price_asc', 'price_desc'];
    final dateFormat = DateFormat.yMMMd();
    final dateLabel = _fromDate != null && _toDate != null
        ? '${dateFormat.format(_fromDate!)} – '
            '${dateFormat.format(_toDate!.subtract(const Duration(days: 1)))}'
        : l10n.searchChooseDates;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        top: 12,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.searchFilters, style: AppTypography.display(size: 22)),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.searchFilterCity),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.searchFilterMinPrice,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.searchFilterMaxPrice,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _minCapacity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.searchFilterMinCapacity,
              ),
            ),
            if (isEvent) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _chooseDates,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(dateLabel),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: InputDecoration(labelText: l10n.searchSortBy),
              items: [
                for (final option in sortOptions)
                  DropdownMenuItem(
                    value: option,
                    child: Text(_sortLabel(l10n, option)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sortBy = value);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.body(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _clear,
                    child: Text(l10n.searchClearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.searchApplyFilters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onFilters,
    required this.filtersLabel,
    required this.showFilters,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilters;
  final String filtersLabel;
  final bool showFilters;

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
          if (showFilters)
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
    required this.locale,
    required this.saved,
    required this.favoritesFailed,
    required this.favoritesLoading,
    required this.onToggleSaved,
    required this.onOpen,
    this.onClear,
  });

  /// Clears whatever is narrowing the list; null when nothing is.
  final VoidCallback? onClear;
  final CatalogPage page;
  final String kindLabel;
  final String query;
  final String locale;
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
      return AppStateView(
        kind: AppStateKind.notFound,
        title: query.isEmpty
            ? l10n.searchNothingHere
            : l10n.searchNoMatches(query),
        message: onClear == null ? null : l10n.searchTryFewerFilters,
        actionLabel: onClear == null ? null : l10n.searchClearFilters,
        onAction: onClear,
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
          subtitle: catalogSubtitle(l10n, item, locale: locale),
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
              const Icon(
                Icons.map_outlined,
                size: 18,
                color: AppColors.onLightSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.display(
                  size: 15,
                  color: AppColors.onLightSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
