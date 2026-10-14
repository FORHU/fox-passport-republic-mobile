import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// "Show prices in": automatic (from where you are) or one of the currencies
/// the API can convert to.
Future<void> showCurrencySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CurrencySheet(),
  );
}

class _CurrencySheet extends ConsumerWidget {
  const _CurrencySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chosen = ref.watch(currencyChoiceProvider);
    final shown = ref.watch(displayCurrencyProvider);
    final located = ref.watch(locationCurrencyProvider);
    final available =
        ref.watch(fxRatesProvider).value?.currencies ?? kSupportedCurrencies;
    final controller = ref.read(currencyChoiceProvider.notifier);
    final locale = Localizations.localeOf(context).toString();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Text(l10n.currencyTitle, style: AppTypography.display(size: 18)),
            const SizedBox(height: 12),
            _Option(
              title: l10n.currencyAuto,
              subtitle: located == null
                  ? l10n.currencyAutoHint
                  : '${l10n.currencyAutoHint} · $located',
              selected: chosen == null,
              onTap: () async {
                await controller.useAutomatic();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            for (final code in available) ...[
              const SizedBox(height: 8),
              _Option(
                title: code,
                subtitle: _symbol(code, locale),
                selected: chosen == code,
                onTap: () async {
                  await controller.choose(code);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
            if (chosen == null) ...[
              const SizedBox(height: 12),
              Text(
                '${l10n.currencyBasedOnLocation}: $shown',
                style: AppTypography.body(size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _symbol(String code, String locale) =>
      NumberFormat.simpleCurrency(name: code, locale: locale).currencySymbol;
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.brSm,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.display(size: 15)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.body(size: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
