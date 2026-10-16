import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Read-only details for an event whose organizer explicitly published it.
class ScheduledEventDetailPage extends ConsumerWidget {
  const ScheduledEventDetailPage({required this.item, super.key});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final formatter = ref.watch(moneyFormatterProvider);
    final date = item.eventStartAt == null
        ? '—'
        : DateFormat('EEEE d MMMM y · jm', locale).format(item.eventStartAt!);
    final price = catalogPriceLabel(
      l10n,
      item,
      locale: locale,
      formatter: formatter,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l10n.searchEventDetails)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(item.title, style: AppTypography.display(size: 28)),
          if (item.category != null) ...[
            const SizedBox(height: 8),
            Text(
              categoryLabel(item.category!),
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
          _EventFact(label: l10n.searchEventDate, value: date),
          if (item.city != null && item.city!.isNotEmpty)
            _EventFact(label: l10n.searchEventLocation, value: item.city!),
          if (item.capacity != null)
            _EventFact(
              label: l10n.searchEventGuests,
              value: l10n.guestsCount(item.capacity!),
            ),
          _EventFact(label: l10n.searchEventPrice, value: price ?? '—'),
        ],
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
