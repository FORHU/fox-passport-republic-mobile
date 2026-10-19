import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/favorites/data/favorites_repository.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Details of an event whose organizer explicitly published it.
///
/// These are events another citizen already booked and chose to make public,
/// so there is nothing to buy here. A citizen can save it, or start planning
/// their own on the matching occasion page, where packages are bookable.
class ScheduledEventDetailPage extends ConsumerStatefulWidget {
  const ScheduledEventDetailPage({required this.item, super.key});

  final CatalogItem item;

  @override
  ConsumerState<ScheduledEventDetailPage> createState() =>
      _ScheduledEventDetailPageState();
}

class _ScheduledEventDetailPageState
    extends ConsumerState<ScheduledEventDetailPage> {
  // Mock mode has no favorites endpoint, so the toggle only lives here.
  bool _mockSaved = false;

  CatalogItem get _item => widget.item;

  /// The occasion page matching this event's category, or the full list when
  /// the category is not one of the known occasions.
  String get _planRoute {
    final occasion = Occasion.fromName(_item.category?.trim().toLowerCase());
    return occasion == null
        ? RouteNames.allCategories
        : RouteNames.occasion(occasion.name);
  }

  Future<void> _toggleSaved(bool saved) async {
    if (AppConfig.instance.useMock) {
      setState(() => _mockSaved = !_mockSaved);
      return;
    }
    if (ref.read(authControllerProvider).user == null) {
      showTopToast(context, context.l10n.signInToContinue);
      return;
    }
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      if (saved) {
        await repository.remove(_item);
      } else {
        await repository.add(_item);
      }
      ref.invalidate(favoriteIdsProvider);
    } on AppException catch (error) {
      if (mounted) showTopToast(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final formatter = ref.watch(moneyFormatterProvider);
    final saved = AppConfig.instance.useMock
        ? _mockSaved
        : ref.watch(favoriteIdsProvider).asData?.value.contains(_item.id) ??
            false;
    final date = _item.eventStartAt == null
        ? '—'
        : DateFormat('EEEE d MMMM y · jm', locale).format(_item.eventStartAt!);
    final price = catalogPriceLabel(
      l10n,
      _item,
      locale: locale,
      formatter: formatter,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.searchEventDetails),
        actions: [
          IconButton(
            tooltip: saved ? l10n.searchRemoveSavedItem : l10n.searchSaveItem,
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
            onPressed: () => _toggleSaved(saved),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_item.title, style: AppTypography.display(size: 28)),
          if (_item.category != null) ...[
            const SizedBox(height: 8),
            Text(
              categoryLabel(_item.category!),
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
          _EventFact(label: l10n.searchEventDate, value: date),
          if (_item.city != null && _item.city!.isNotEmpty)
            _EventFact(label: l10n.searchEventLocation, value: _item.city!),
          if (_item.capacity != null)
            _EventFact(
              label: l10n.searchEventGuests,
              value: l10n.guestsCount(_item.capacity!),
            ),
          _EventFact(label: l10n.searchEventPrice, value: price ?? '—'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.searchEventPlanHint,
                textAlign: TextAlign.center,
                style: AppTypography.body(size: 12),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.searchEventPlanLikeThis,
                icon: Icons.auto_awesome_outlined,
                onPressed: () => context.push(_planRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventFact extends StatelessWidget {
  const _EventFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.label()),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.body()),
          ],
        ),
      );
}
