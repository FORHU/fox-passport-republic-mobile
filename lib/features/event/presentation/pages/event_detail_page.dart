import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/event/data/event_repository.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/widgets/location_card.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// One event package. The citizen sees what it is made of, switches off the
/// optional parts they do not want (the price follows), then picks a date.
class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({required this.item, super.key});

  /// The row the citizen tapped; it names the event while the rest loads.
  final CatalogItem item;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  /// Optional items switched off.
  final Set<String> _excluded = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(eventPackageProvider(widget.item));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => _Failed(
          title: widget.item.title,
          message: l10n.eventLoadFailed,
          retry: l10n.retry,
          onRetry: () => ref.invalidate(eventPackageProvider(widget.item)),
        ),
        data: (package) => _Loaded(
          item: widget.item,
          package: package,
          excluded: _excluded,
          onToggle: (id, {required included}) => setState(() {
            if (included) {
              _excluded.remove(id);
            } else {
              _excluded.add(id);
            }
          }),
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.title,
    required this.message,
    required this.retry,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.display(size: 18)),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                  TextButton(onPressed: onRetry, child: Text(retry)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.item,
    required this.package,
    required this.excluded,
    required this.onToggle,
  });

  final CatalogItem item;
  final EventPackage package;
  final Set<String> excluded;
  final void Function(String id, {required bool included}) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final quote = package.quote(excluded);
    final bookable = package.isPriced && !package.isFull;
    final place = [package.city, package.state]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .join(', ');
    final category = package.category;
    final required = package.items.where((i) => !i.isOptional).toList();
    final optional = package.optionalItems;

    String format(num amount) =>
        money.format(amount, package.currency, locale: locale);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PhotoBox(
                      url: package.imageUrl ?? item.imageUrl,
                      height: 240,
                      radius: 0,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: AppColors.canvas.withValues(alpha: 0.7),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: l10n.bookBack,
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null && category.isNotEmpty)
                      Text(
                        categoryLabel(category).toUpperCase(),
                        style: AppTypography.label(color: AppColors.accent),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      package.name.isEmpty ? item.title : package.name,
                      style: AppTypography.display(size: 26),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (place.isNotEmpty)
                          _Meta(icon: Icons.place_outlined, text: place),
                        if (package.hostName != null)
                          _Meta(
                            icon: Icons.person_outline_rounded,
                            text: l10n.eventHostedBy(package.hostName!),
                          ),
                        if (package.spotsLeft != null && !package.isFull)
                          _Meta(
                            icon: Icons.event_seat_outlined,
                            text: l10n.eventSpotsLeft(package.spotsLeft!),
                          ),
                      ],
                    ),
                    if (package.isSample) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.eventSampleNote.toUpperCase(),
                        style: AppTypography.label(),
                      ),
                    ],
                    if (package.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        package.description!,
                        style: AppTypography.body(),
                      ),
                    ],
                    LocationCard(
                      lines: [place],
                      lat: package.lat,
                      lng: package.lng,
                      query: [package.name, place]
                          .where((p) => p.isNotEmpty)
                          .join(', '),
                    ),
                    if (package.items.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.eventIncluded,
                        style: AppTypography.display(size: 18),
                      ),
                      const SizedBox(height: 12),
                      for (final it in required)
                        _ItemRow(
                          item: it,
                          included: true,
                          price: null,
                          trailing: Text(
                            l10n.eventIncludedLabel.toUpperCase(),
                            style: AppTypography.label(),
                          ),
                        ),
                      if (optional.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.eventOptionalHint,
                          style: AppTypography.body(size: 12),
                        ),
                        const SizedBox(height: 8),
                        for (final it in optional)
                          _ItemRow(
                            item: it,
                            included: !excluded.contains(it.id),
                            price: format(it.price),
                            trailing: Switch(
                              value: !excluded.contains(it.id),
                              activeThumbColor: AppColors.onAccent,
                              activeTrackColor: AppColors.accent,
                              onChanged: (v) => onToggle(it.id, included: v),
                            ),
                          ),
                      ],
                    ],
                    if (package.isFull) ...[
                      const SizedBox(height: 16),
                      _Notice(text: l10n.eventFull),
                    ] else if (!package.isPriced) ...[
                      const SizedBox(height: 16),
                      _Notice(text: l10n.eventNotPriced),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          total: package.isPriced ? format(quote.total) : null,
          note: excluded.isEmpty
              ? null
              : l10n.eventRemoved(
                  package.optionalItems
                      .where((i) => excluded.contains(i.id))
                      .length,
                ),
          cta: l10n.eventBook,
          onTap: bookable
              ? () => context.push(
                    RouteNames.book,
                    extra: EventBookingArgs(
                      item: item,
                      package: package,
                      excluded: {...excluded},
                    ),
                  )
              : null,
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: AppTypography.body(size: 13))),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.included,
    required this.price,
    required this.trailing,
  });

  final PackageItem item;
  final bool included;
  final String? price;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.kind) {
      PackageItemKind.venue => Icons.apartment_rounded,
      PackageItemKind.gear => Icons.speaker_outlined,
      PackageItemKind.service => Icons.room_service_outlined,
    };
    final color = included ? AppColors.textPrimary : AppColors.textFaint;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: included ? AppColors.accent : color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 14, color: color).copyWith(
                    decoration: included ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (price != null)
                  Text(price!, style: AppTypography.body(size: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(size: 13, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.total,
    required this.cta,
    required this.onTap,
    this.note,
  });

  final String? total;
  final String? note;
  final String cta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (total != null)
                    Text(total!, style: AppTypography.display(size: 18)),
                  if (note != null)
                    Text(note!, style: AppTypography.body(size: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  // The theme makes buttons full width, which a Row
                  // cannot hold.
                  minimumSize: const Size(140, 52),
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.brPill),
                ),
                child: Text(
                  cta,
                  style: AppTypography.display(color: AppColors.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
