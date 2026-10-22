import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/event_detail.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/event_studio_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_picker_sheet.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/studio_fields.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Refuses typing that would take a text over [max] words, as the web does.
class WordLimitFormatter extends TextInputFormatter {
  const WordLimitFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      countWords(newValue.text) > max ? oldValue : newValue;
}

/// Creates an event, or edits one the person already has, in steps: basics,
/// location, photos, the core package and a final review. It follows the
/// web's event builder, so an event made on either behaves the same on the
/// other.
class EventStudioPage extends ConsumerWidget {
  const EventStudioPage({this.eventId, super.key});

  /// The event to edit; null to start a new one.
  final String? eventId;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required bool submit,
  }) async {
    final l10n = context.l10n;
    final outcome = await ref
        .read(eventStudioProvider(eventId).notifier)
        .save(submit: submit);
    if (!context.mounted) return;
    final state = ref.read(eventStudioProvider(eventId));
    switch (outcome) {
      case SaveOutcome.blocked:
        if (state.error == 'title') showTopToast(context, l10n.esNeedsTitle);
      case SaveOutcome.failed:
        showTopToast(
          context,
          state.errorDetail?.isNotEmpty ?? false
              ? state.errorDetail!
              : l10n.esSaveFailed,
        );
      case SaveOutcome.partial:
        ref.invalidate(myEventsProvider);
        showTopToast(context, l10n.esPartial);
      case SaveOutcome.saved:
        ref.invalidate(myEventsProvider);
        showTopToast(
          context,
          state.status == 'draft' ? l10n.esSavedDraft : l10n.esSavedChanges,
        );
      case SaveOutcome.submitted:
        ref.invalidate(myEventsProvider);
        showTopToast(context, l10n.esSubmitted);
        if (context.canPop()) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(eventId));
    final controller = ref.read(eventStudioProvider(eventId).notifier);
    final step = state.step;
    final last = step == EventStep.review;

    Widget body;
    if (state.loading) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    } else if (state.loadFailed) {
      body = AppStateView(
        kind: AppStateKind.error,
        title: l10n.apiLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(eventStudioProvider(eventId)),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          switch (step) {
            EventStep.basics => _BasicsStep(id: eventId),
            EventStep.location => _LocationStep(id: eventId),
            EventStep.photos => _PhotosStep(id: eventId),
            EventStep.package => _PackageStep(id: eventId),
            EventStep.review => _ReviewStep(id: eventId),
          },
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          eventId == null ? l10n.esTitleNew : l10n.esTitleEdit,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: Column(
        children: [
          _StepBar(step: step, onTap: controller.goTo),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: state.loading || state.loadFailed
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: last
                    ? _FinalActions(
                        id: eventId,
                        onBack: controller.back,
                        onDraft: () => _save(context, ref, submit: false),
                        onSubmit: () => _save(context, ref, submit: true),
                      )
                    : Row(
                        children: [
                          if (step != EventStep.basics)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: OutlinedButton(
                                onPressed: controller.back,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                ),
                                child: Text(l10n.studioBack),
                              ),
                            ),
                          Expanded(
                            child: AppButton(
                              label: l10n.studioNext,
                              onPressed: controller.next,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}

String _stepLabel(AppLocalizations l10n, EventStep step) => switch (step) {
      EventStep.basics => l10n.esStepBasics,
      EventStep.location => l10n.esStepLocation,
      EventStep.photos => l10n.esStepPhotos,
      EventStep.package => l10n.esStepPackage,
      EventStep.review => l10n.esStepReview,
    };

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.onTap});

  final EventStep step;
  final ValueChanged<EventStep> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final s in EventStep.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${s.index + 1}  ${_stepLabel(l10n, s)}'),
                selected: s == step,
                onSelected: (_) => onTap(s),
                selectedColor: AppColors.accent,
                labelStyle: AppTypography.label(
                  color: s == step ? AppColors.onAccent : AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The last step's buttons. A draft (or a new event) can be saved or sent for
/// review; an event already sent can only have its changes saved.
class _FinalActions extends ConsumerWidget {
  const _FinalActions({
    required this.id,
    required this.onBack,
    required this.onDraft,
    required this.onSubmit,
  });

  final String? id;
  final VoidCallback onBack;
  final VoidCallback onDraft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(id));
    final isDraft = state.isNew || state.status == 'draft';
    final back = OutlinedButton(
      onPressed: onBack,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      child: Text(l10n.studioBack),
    );
    if (!isDraft) {
      return Row(
        children: [
          back,
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: l10n.esSaveChanges,
              isLoading: state.saving,
              onPressed: onDraft,
            ),
          ),
        ],
      );
    }
    // Three buttons side by side do not fit a phone: the main one gets a row
    // of its own, with Back and Save as draft below it.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: l10n.esSubmit,
          isLoading: state.saving,
          onPressed: state.canSubmit ? onSubmit : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: back),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: state.saving ? null : onDraft,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(l10n.esSaveDraft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -- Steps -------------------------------------------------------------------

class _BasicsStep extends ConsumerWidget {
  const _BasicsStep({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(id));
    final d = state.draft;
    final edit = ref.read(eventStudioProvider(id).notifier).edit;
    final categories = {
      'Corporate': l10n.esCatCorporate,
      'Birthday': l10n.esCatBirthday,
      'Wedding': l10n.esCatWedding,
      'Social': l10n.esCatSocial,
      'Other': l10n.esCatOther,
    };
    final words = d.words;
    final countColor = words >= maxEventWords
        ? AppColors.error
        : words >= 450
            ? AppColors.warning
            : words >= recommendedEventWords
                ? AppColors.accent
                : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioField(
          label: l10n.esTitle,
          value: d.title,
          onChanged: (v) => edit((x) => x.copyWith(title: v)),
        ),
        Text(l10n.esCategory, style: AppTypography.label()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in categories.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: d.category == entry.key,
                onSelected: (_) => edit((x) => x.copyWith(category: entry.key)),
              ),
          ],
        ),
        if (d.category == 'Other') ...[
          const SizedBox(height: 12),
          StudioField(
            label: l10n.esCatOtherHint,
            value: d.categoryOther,
            onChanged: (v) => edit((x) => x.copyWith(categoryOther: v)),
          ),
        ] else
          const SizedBox(height: 16),
        Row(
          children: [
            Text(l10n.esDescription, style: AppTypography.label()),
            const Spacer(),
            Text(
              [
                l10n.esWordCount(words),
                if (words > 0 && words < recommendedEventWords)
                  l10n.esWordsToGo(recommendedEventWords - words),
              ].join(' · '),
              style: AppTypography.label(color: countColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StudioField(
          label: l10n.esDescription,
          value: d.description,
          maxLines: 6,
          formatters: const [WordLimitFormatter(maxEventWords)],
          onChanged: (v) => edit((x) => x.copyWith(description: v)),
        ),
        StudioField(
          label: l10n.esAttendees,
          value: d.maxAttendees > 0 ? '${d.maxAttendees}' : '',
          number: true,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => edit(
            (x) => x.copyWith(maxAttendees: int.tryParse(v) ?? 0),
          ),
        ),
        if (state.policies.isNotEmpty) ...[
          Text(l10n.esPolicy, style: AppTypography.label()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final policy in state.policies)
                ChoiceChip(
                  label: Text(policy.name),
                  selected: d.cancellationPolicyId == policy.id,
                  onSelected: (_) => edit(
                    (x) => x.copyWith(cancellationPolicyId: policy.id),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LocationStep extends ConsumerWidget {
  const _LocationStep({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(id));
    final studio = ref.read(eventStudioProvider(id).notifier);
    final d = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.esLocationHint,
          style: AppTypography.body(size: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        PlaceFields(
          country: d.country,
          state: d.state,
          city: d.city,
          countries: state.countries,
          states: state.states,
          cities: state.cities,
          locating: state.locating,
          locateProblem: state.locateProblem,
          onCountryText: (v) => studio.edit((x) => x.copyWith(country: v)),
          onStateText: (v) => studio.edit((x) => x.copyWith(state: v)),
          onCityText: studio.pickCity,
          onPickCountry: studio.pickCountry,
          onPickState: studio.pickState,
          onUseMyLocation: studio.useMyLocation,
        ),
      ],
    );
  }
}

class _PhotosStep extends ConsumerWidget {
  const _PhotosStep({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(id));
    final studio = ref.read(eventStudioProvider(id).notifier);
    final photos = state.draft.photos;

    Future<void> add() async {
      final photo = await ref.read(photoPickerProvider).pick();
      if (photo == null) return;
      await studio.addPhoto(photo);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.esPhotosHint,
          style: AppTypography.body(size: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final photo in photos)
              Stack(
                children: [
                  PhotoBox(url: photo.url, width: 104, height: 104),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => studio.removePhoto(photo.fileId),
                      icon: const Icon(Icons.close_rounded, size: 16),
                    ),
                  ),
                ],
              ),
            if (photos.length < maxEventPhotos)
              InkWell(
                onTap: state.uploading ? null : add,
                borderRadius: AppRadius.brCard,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brCard,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: state.uploading
                      ? const CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_a_photo_outlined),
                            const SizedBox(height: 4),
                            Text(
                              l10n.studioAddPhoto,
                              style: AppTypography.label(),
                            ),
                          ],
                        ),
                ),
              ),
          ],
        ),
        if (state.error == 'photo')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.errorDetail == null
                  ? l10n.esPhotoFailed
                  : l10n.studioPhotoFailedWhy(state.errorDetail!),
              style: AppTypography.body(size: 13, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class _PackageStep extends ConsumerWidget {
  const _PackageStep({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(id));
    final studio = ref.read(eventStudioProvider(id).notifier);
    final money = ref.watch(moneyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    String fmt(num v) => money.format(v, kBaseCurrency, locale: locale);

    final d = state.draft;
    final venue = d.venue;
    final others = [
      for (final i in d.items)
        if (!i.isVenue) i,
    ];
    final totals = d.totals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.esPackageTitle, style: AppTypography.display()),
        const SizedBox(height: 4),
        Text(
          l10n.esPackageHint,
          style: AppTypography.body(size: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Text(l10n.esVenueSlot, style: AppTypography.label()),
        const SizedBox(height: 8),
        if (venue == null)
          OutlinedButton.icon(
            onPressed: () => showPackagePicker(
              context,
              studioId: id,
            ),
            icon: const Icon(Icons.apartment_rounded, size: 18),
            label: Text(l10n.esChooseVenue),
          )
        else
          _ItemTile(
            item: venue,
            price: fmt(venue.price),
            listed: venue.agreedPrice == null ? null : fmt(venue.cost),
            onTap: () => _editItem(context, id, venue.id),
          ),
        const SizedBox(height: 20),
        if (others.isEmpty)
          Text(
            l10n.esPackageEmpty,
            style: AppTypography.body(size: 13, color: AppColors.textMuted),
          )
        else
          for (final item in others) ...[
            _ItemTile(
              item: item,
              price: fmt(item.price),
              listed: item.agreedPrice == null ? null : fmt(item.cost),
              onTap: () => _editItem(context, id, item.id),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showPackagePicker(
            context,
            studioId: id,
            start: ResourceBucket.talent,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.esAdd),
        ),
        const SizedBox(height: 24),
        _Breakdown(
          venue: fmt(totals.venue),
          talent: fmt(totals.talent),
          services: fmt(totals.services),
          total: fmt(totals.base),
          suggested: fmt(totals.suggested),
          margin: d.marginPct,
          onMargin: studio.setMargin,
        ),
      ],
    );
  }
}

Future<void> _editItem(BuildContext context, String? id, String itemId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _EditItemSheet(studioId: id, itemId: itemId),
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.price,
    required this.listed,
    required this.onTap,
  });

  final PackageItem item;
  final String price;

  /// The listed price, shown when a different one was agreed.
  final String? listed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.canvas,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              PhotoBox(url: item.imageUrl, width: 48, height: 48, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(),
                    ),
                    if (item.isOptional)
                      Text(l10n.esOptional, style: AppTypography.label()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: AppTypography.body(size: 13)),
                  if (listed != null)
                    Text(
                      l10n.esListed(listed!),
                      style: AppTypography.label(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Changes what was agreed for one item, whether it is optional, or takes it
/// out of the package.
class _EditItemSheet extends ConsumerWidget {
  const _EditItemSheet({required this.studioId, required this.itemId});

  final String? studioId;
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(studioId));
    final studio = ref.read(eventStudioProvider(studioId).notifier);
    final money = ref.watch(moneyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final item = state.draft.items.where((i) => i.id == itemId).firstOrNull;
    // Taken out (here or elsewhere): nothing left to edit.
    if (item == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.esEditItem(item.name),
            style: AppTypography.display(size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.esListed(
              money.format(item.cost, kBaseCurrency, locale: locale),
            ),
            style: AppTypography.body(size: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          StudioField(
            label: l10n.esAgreedPrice,
            value: item.agreedPrice == null ? '' : _plain(item.agreedPrice!),
            number: true,
            onChanged: (v) {
              final price = double.tryParse(v);
              if (price == null || price < 0) {
                studio.updateItem(itemId, clearPrice: true);
              } else {
                studio.updateItem(itemId, agreedPrice: price);
              }
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.esOptional),
            value: item.isOptional,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => studio.updateItem(itemId, isOptional: v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  studio.removeItem(itemId);
                  Navigator.of(context).pop();
                },
                child: Text(
                  l10n.esRemove,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                child: Text(l10n.esDone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A price without a pointless ".0".
  static String _plain(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.venue,
    required this.talent,
    required this.services,
    required this.total,
    required this.suggested,
    required this.margin,
    required this.onMargin,
  });

  final String venue;
  final String talent;
  final String services;
  final String total;
  final String suggested;
  final int margin;
  final ValueChanged<int> onMargin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget line(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: bold ? AppTypography.body() : AppTypography.label(),
                ),
              ),
              Text(
                value,
                style: bold
                    ? AppTypography.display(size: 15)
                    : AppTypography.body(size: 13),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(l10n.esCostVenue, venue),
          line(l10n.esCostTalent, talent),
          line(l10n.esCostServices, services),
          const Divider(height: 20),
          line(l10n.esCostTotal, total, bold: true),
          const SizedBox(height: 12),
          Text(l10n.esMargin, style: AppTypography.label()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final pct in const [0, 10, 20, 30, 40])
                ChoiceChip(
                  label: Text('$pct%'),
                  selected: margin == pct,
                  onSelected: (_) => onMargin(pct),
                  selectedColor: AppColors.accent,
                  labelStyle: AppTypography.label(
                    color: margin == pct
                        ? AppColors.onAccent
                        : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          line(l10n.esSuggested, suggested, bold: true),
        ],
      ),
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(eventStudioProvider(id));
    final d = state.draft;

    final labels = {
      'title': l10n.esReadyTitle,
      'category': l10n.esReadyCategory,
      'venue': l10n.esReadyVenue,
      'gallery': l10n.esReadyGallery,
      'description': l10n.esReadyDescription,
    };

    Widget row(String label, {required bool met, required bool required}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: met
                    ? AppColors.success
                    : required
                        ? AppColors.warning
                        : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
              Text(
                required ? l10n.esRequired : l10n.esRecommended,
                style: AppTypography.label(),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.esScore(d.score), style: AppTypography.display(size: 18)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: d.score / 100,
          color: AppColors.accent,
          backgroundColor: AppColors.border,
          minHeight: 4,
        ),
        const SizedBox(height: 12),
        for (final line in d.readiness)
          row(
            labels[line.id] ?? line.id,
            met: line.met,
            required: line.required,
          ),
        // A category of Other also needs the host's own words.
        if (d.category == 'Other')
          row(
            l10n.esReadyOther,
            met: !d.categoryOtherMissing,
            required: true,
          ),
        if (!state.isNew && state.status != 'draft')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l10n.esNotDraft,
              style: AppTypography.body(size: 13, color: AppColors.warning),
            ),
          ),
        if (state.problems.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.esPartial,
            style: AppTypography.body(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          for (final p in state.problems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                p.message.isEmpty
                    ? p.name
                    : l10n.esProblemLine(p.name, p.message),
                style: AppTypography.body(size: 13, color: AppColors.error),
              ),
            ),
        ],
      ],
    );
  }
}
