import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/bids_repository.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/open_slot.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Events that are looking for a service or gear, with a way to apply for a
/// spot with one of the person's own services or gear.
class OpenSlotsPage extends ConsumerWidget {
  const OpenSlotsPage({super.key});

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    OpenSlotEvent event,
    OpenSlot slot,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(bidsRepositoryProvider);
    try {
      final listings = await ref.read(
        slot.isGear ? myAssetsProvider.future : myServicesProvider.future,
      );
      if (!context.mounted) return;
      if (listings.isEmpty) {
        showTopToast(
          context,
          slot.isGear ? l10n.openSlotsNoGear : l10n.openSlotsNoService,
        );
        return;
      }
      final draft = await showModalBottomSheet<BidDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        builder: (_) =>
            _ApplyForm(event: event, slot: slot, listings: listings),
      );
      if (draft == null || !context.mounted) return;
      await repo.submit(draft);
      if (context.mounted) showTopToast(context, l10n.openSlotsApplied);
    } on Object catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.openSlotsFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final async = ref.watch(openSlotsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.openSlotsTitle, style: AppTypography.display()),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(openSlotsProvider),
        ),
        data: (events) => events.isEmpty
            ? AppStateView(
                title: l10n.openSlotsEmpty,
                message: l10n.openSlotsEmptyBody,
                icon: Icons.event_available_outlined,
              )
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () => ref.refresh(openSlotsProvider.future),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final e = events[i];
                    final when = e.startAt == null
                        ? null
                        : DateFormat.MMMd(locale).format(e.startAt!.toLocal());
                    final line =
                        [when, e.city, e.host].whereType<String>().join(' · ');
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: AppTypography.display()),
                          if (line.isNotEmpty)
                            Text(line, style: AppTypography.label()),
                          for (final s in e.slots) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.description ??
                                            (s.isGear
                                                ? l10n.openSlotsAnyGear
                                                : l10n.openSlotsAnySlot),
                                        style: AppTypography.body(),
                                      ),
                                      if (s.price > 0)
                                        Text(
                                          money.format(
                                            s.price,
                                            s.currency,
                                            locale: locale,
                                          ),
                                          style: AppTypography.label(
                                            color: AppColors.accent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: () => _apply(context, ref, e, s),
                                  child: Text(l10n.openSlotsApply),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _ApplyForm extends StatefulWidget {
  const _ApplyForm({
    required this.event,
    required this.slot,
    required this.listings,
  });

  final OpenSlotEvent event;
  final OpenSlot slot;

  /// The person's own services, or their gear when the spot is for gear.
  final List<SpaceListing> listings;

  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  late final _price = TextEditingController(
    text: widget.slot.price > 0 ? '${widget.slot.price}' : '',
  );
  final _message = TextEditingController();
  late String _listingId = widget.listings.first.id;

  @override
  void dispose() {
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  num? get _amount => num.tryParse(_price.text.trim());

  bool get _valid => (_amount ?? -1) >= 0 && _price.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.openSlotsApplyTo(widget.event.name),
              style: AppTypography.display(size: 18),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _listingId,
              decoration: InputDecoration(
                labelText: widget.slot.isGear
                    ? l10n.openSlotsGear
                    : l10n.openSlotsService,
              ),
              items: [
                for (final s in widget.listings)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (id) => setState(() => _listingId = id ?? _listingId),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.openSlotsPrice(widget.slot.currency),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.openSlotsPitch),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _valid
                    ? () => Navigator.of(context).pop(
                          BidDraft(
                            eventId: widget.event.id,
                            slotId: widget.slot.id,
                            listingId: _listingId,
                            isGear: widget.slot.isGear,
                            price: _amount!,
                            message: _message.text,
                          ),
                        )
                    : null,
                child: Text(l10n.openSlotsSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
