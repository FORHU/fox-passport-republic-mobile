import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/domain/home_categories.dart';
import 'package:flutter_template/features/home/presentation/widgets/category_labels.dart';
import 'package:flutter_template/features/occasion/data/packages_repository.dart';
import 'package:flutter_template/features/occasion/presentation/widgets/plan_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart'
    show catalogPriceLabel;
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/area_sheet.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/occasion_colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Planning by occasion: one page with three ways in, in this order. Ready
/// made packages, a Foxer who plans it, or put it together yourself. There is
/// no question sheet up front; date and guests are optional chips.
class OccasionPage extends ConsumerStatefulWidget {
  const OccasionPage({required this.occasion, super.key});

  final Occasion occasion;

  @override
  ConsumerState<OccasionPage> createState() => _OccasionPageState();
}

class _OccasionPageState extends ConsumerState<OccasionPage> {
  PlanChoice _plan = const PlanChoice();

  Future<void> _openPlan() async {
    final choice = await showPlanSheet(context, initial: _plan);
    if (choice != null && mounted) setState(() => _plan = choice);
  }

  /// Search, carrying what has been chosen so far.
  String _search(String kind, {String? city}) => RouteNames.searchFor(
        kind,
        city: city,
        minCapacity: _plan.guests?.minCapacity,
        date: _plan.date,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final occasion = widget.occasion;
    final area = ref.watch(areaFilterProvider);
    final city = area.city;
    final label = occasionLabel(l10n, occasion);
    final packages = ref.watch(
      packagesProvider((category: occasion.name, city: city)),
    );
    final categories = ref.watch(categoriesProvider).asData?.value;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => _refresh(occasion.name, city),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      city == null || city.isEmpty
                          ? l10n.occasionTitle(label)
                          : l10n.occasionTitleIn(label, city),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(size: 20),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.search,
                    onPressed: () => context.go(RouteNames.searchFor('events')),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Chips: dashed lime until set.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PlanChip(
                      label: _plan.date == null
                          ? l10n.planAddDate
                          : DateFormat.MMMd(locale).format(_plan.date!),
                      set: _plan.date != null,
                      icon: Icons.event_outlined,
                      onTap: _openPlan,
                    ),
                    const SizedBox(width: 8),
                    _PlanChip(
                      label: _plan.guests == null
                          ? l10n.planGuests
                          : switch (_plan.guests!) {
                              GuestRange.upTo20 => l10n.guestsUpTo20,
                              GuestRange.to50 => l10n.guests20to50,
                              GuestRange.to100 => l10n.guests50to100,
                              GuestRange.over100 => l10n.guests100plus,
                            },
                      set: _plan.guests != null,
                      icon: Icons.groups_outlined,
                      onTap: _openPlan,
                    ),
                    const SizedBox(width: 8),
                    _PlanChip(
                      label: city == null || city.isEmpty
                          ? l10n.homeLocationChoose
                          : city,
                      set: true,
                      plain: true,
                      icon: Icons.location_on_outlined,
                      onTap: () => showAreaSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...packages.when(
                loading: () => const [_PackagesSkeleton()],
                error: (_, __) => [_NoPackages(label: label, city: city)],
                data: (items) => items.isEmpty
                    ? [_NoPackages(label: label, city: city)]
                    : [
                        Text(
                          l10n.occasionPackages,
                          style: AppTypography.display(size: 18),
                        ),
                        const SizedBox(height: 12),
                        _PackagesRow(items: items),
                      ],
              ),
              const SizedBox(height: 24),
              _PlannerCard(
                onTap: () => context.go(_search('foxers', city: city)),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.occasionYourself,
                style: AppTypography.display(size: 18),
              ),
              const SizedBox(height: 12),
              ..._yourself(l10n, categories, city),
            ],
          ),
        ),
      ),
    );
  }

  /// Pull to refresh holds the spinner until the new packages have arrived.
  Future<void> _refresh(String category, String? city) async {
    final key = (category: category, city: city);
    ref
      ..invalidate(packagesProvider(key))
      ..invalidate(categoriesProvider);
    try {
      await ref.read(packagesProvider(key).future);
    } on Object {
      // The packages area shows its own empty state.
    }
  }

  /// Category rows: venues, then services and gear, each with its count.
  List<Widget> _yourself(
    AppLocalizations l10n,
    List<CategorySummary>? categories,
    String? city,
  ) {
    final rows = singleBookings(categories, limit: 6);
    if (rows.isEmpty) {
      return [
        Text(
          l10n.occasionNoneHere,
          style: AppTypography.body(color: AppColors.textMuted),
        ),
      ];
    }
    return [
      for (final r in rows)
        _CategoryRow(
          icon: categoryIcon(r.category),
          label: categoryLabel(l10n, r.category),
          count: r.count,
          noneLabel: l10n.occasionNoneHere,
          onTap: () => context.go(_search(r.kind.name)),
        ),
    ];
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.set,
    required this.icon,
    required this.onTap,
    this.plain = false,
  });

  final String label;
  final bool set;
  final bool plain;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lime = !set && !plain;
    return InkWell(
      borderRadius: AppRadius.brPill,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brPill,
          border: Border.all(
            color: lime ? AppColors.accent : AppColors.borderStrong,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: lime ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.body(
                size: 13,
                weight: FontWeight.w600,
                color: lime ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackagesRow extends ConsumerWidget {
  const _PackagesRow({required this.items});

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

class _NoPackages extends StatelessWidget {
  const _NoPackages({required this.label, required this.city});

  final String label;
  final String? city;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text(
      city == null || city!.isEmpty
          ? l10n.occasionNoPackages(label.toLowerCase())
          : l10n.occasionNoPackagesIn(label.toLowerCase(), city!),
      style: AppTypography.body(color: AppColors.textMuted),
    );
  }
}

class _PackagesSkeleton extends StatelessWidget {
  const _PackagesSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box() => Expanded(
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
            ),
          ),
        );
    return Row(
      children: [box(), const SizedBox(width: 12), box()],
    );
  }
}

/// "Have a Foxer plan it": a card with the Foxer pink border.
class _PlannerCard extends StatelessWidget {
  const _PlannerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: OccasionColors.plannerBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: AppColors.roleTalent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.occasionPlanner,
                      style: AppTypography.display(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.occasionPlannerBody,
                      style: AppTypography.body(
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.occasionFindPlanner,
                style: AppTypography.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.noneLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final String noneLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: onTap,
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
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.body())),
            Text(
              count > 0 ? '$count' : noneLabel,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
