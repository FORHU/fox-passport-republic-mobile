import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/presentation/widgets/category_labels.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// "Everything you can book": every category under Occasions, People, Gear
/// and Venues, each with its count, and a field to find one. A category with
/// nothing in it says "None yet" here (Home hides it).
class AllCategoriesPage extends ConsumerStatefulWidget {
  const AllCategoriesPage({super.key});

  @override
  ConsumerState<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends ConsumerState<AllCategoriesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      l10n.allCategoriesTitle,
                      style: AppTypography.display(size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: l10n.allCategoriesFind,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: categories.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => AppStateView(
                  kind: AppStateKind.error,
                  title: l10n.apiLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(categoriesProvider),
                ),
                data: (list) => _Groups(
                  categories: list,
                  query: _query,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.name,
    required this.label,
    required this.count,
    required this.icon,
    required this.open,
  });

  final String name;
  final String label;
  final int count;
  final IconData icon;
  final String open;
}

class _Groups extends StatelessWidget {
  const _Groups({
    required this.categories,
    required this.query,
    required this.l10n,
  });

  final List<CategorySummary> categories;
  final String query;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    bool matches(String label) =>
        query.isEmpty || label.toLowerCase().contains(query.toLowerCase());

    // Occasions are always listed, even before the API knows about them.
    final occasions = [
      for (final o in Occasion.values)
        if (matches(occasionLabel(l10n, o)))
          _Entry(
            name: o.name,
            label: occasionLabel(l10n, o),
            count: categories
                    .where((c) => c.name == o.name)
                    .map((c) => c.count)
                    .firstOrNull ??
                0,
            icon: o.icon,
            open: RouteNames.occasion(o.name),
          ),
    ];

    List<_Entry> group(int Function(CategorySummary) count, CatalogKind kind) =>
        [
          for (final c in categories)
            if (Occasion.fromName(c.name) == null &&
                count(c) > 0 &&
                matches(categoryLabel(l10n, c.name)))
              _Entry(
                name: c.name,
                label: categoryLabel(l10n, c.name),
                count: count(c),
                icon: categoryIcon(c.name),
                open: RouteNames.searchFor(kind.name),
              ),
        ]..sort((a, b) => b.count.compareTo(a.count));

    final sections = <(String, List<_Entry>)>[
      (l10n.allCategoriesOccasions, occasions),
      (
        l10n.allCategoriesPeople,
        group((c) => c.services, CatalogKind.services)
      ),
      (l10n.allCategoriesGear, group((c) => c.assets, CatalogKind.gear)),
      (l10n.allCategoriesVenues, group((c) => c.venues, CatalogKind.venues)),
    ];

    final visible = [
      for (final s in sections)
        if (s.$2.isNotEmpty) s,
    ];
    if (visible.isEmpty) {
      return Center(
        child: Text(
          l10n.searchNothingHere,
          style: AppTypography.body(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        for (final s in visible) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
            child: Text(s.$1.toUpperCase(), style: AppTypography.label()),
          ),
          for (final e in s.$2)
            InkWell(
              borderRadius: AppRadius.brMd,
              onTap: () => context.go(e.open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Icon(e.icon, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.label, style: AppTypography.body())),
                    Text(
                      e.count > 0 ? '${e.count}' : l10n.allCategoriesNone,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
