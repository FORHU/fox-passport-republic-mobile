import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/venue_studio_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/service_area_map.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/studio_chrome.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/studio_fields.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Creates a venue, or edits one the person already has, in steps: basics,
/// location, photos, what is included, pricing and a final review.
class VenueStudioPage extends ConsumerWidget {
  const VenueStudioPage({this.venueId, super.key});

  /// The venue to edit; null to add a new one.
  final String? venueId;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required bool submit,
  }) async {
    final l10n = context.l10n;
    final controller = ref.read(venueStudioProvider(venueId).notifier);
    final live = ref.read(venueStudioProvider(venueId)).live;
    final ok = await controller.save(submit: submit);
    if (!context.mounted) return;
    if (!ok) {
      final error = ref.read(venueStudioProvider(venueId)).error;
      showTopToast(
        context,
        error == 'overlap' ? l10n.studioOverlapRefused : l10n.studioSaveFailed,
      );
      return;
    }
    ref.invalidate(myVenuesProvider);
    showTopToast(
      context,
      live
          ? l10n.studioSavedChanges
          : submit
              ? l10n.studioSubmitted
              : l10n.studioSavedDraft,
    );
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(venueStudioProvider(venueId));
    final controller = ref.read(venueStudioProvider(venueId).notifier);
    final step = state.step;
    final last = step == StudioStep.review;

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
        onAction: () => ref.invalidate(venueStudioProvider(venueId)),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (state.live) _LiveNote(text: l10n.studioLiveNote),
          switch (step) {
            StudioStep.basics => StudioCard(
                child: _BasicsStep(state: state, ref: ref, id: venueId),
              ),
            StudioStep.location =>
              _LocationStep(state: state, ref: ref, id: venueId),
            StudioStep.photos =>
              _PhotosStep(state: state, ref: ref, id: venueId),
            StudioStep.details =>
              _DetailsStep(state: state, ref: ref, id: venueId),
            StudioStep.pricing => StudioCard(
                child: _PricingStep(state: state, ref: ref, id: venueId),
              ),
            StudioStep.review => StudioCard(child: _ReviewStep(state: state)),
          },
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          venueId == null ? l10n.studioTitleNew : l10n.studioTitleEdit,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: Column(
        children: [
          if (!state.loading && !state.loadFailed)
            StudioHeader(
              current: step.index,
              total: StudioStep.values.length,
              title: _stepLabel(l10n, step),
              onSelect: (i) => controller.goTo(StudioStep.values[i]),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: state.loading || state.loadFailed
          ? null
          : StudioBar(
              child: last
                  ? _FinalActions(
                      state: state,
                      onBack: controller.back,
                      onDraft: () => _save(context, ref, submit: false),
                      onSubmit: () => _save(context, ref, submit: true),
                    )
                  : Row(
                      children: [
                        if (step != StudioStep.basics) ...[
                          StudioBackButton(onPressed: controller.back),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: AppButton(
                            label: l10n.studioNext,
                            onPressed: controller.next,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

String _stepLabel(AppLocalizations l10n, StudioStep step) => switch (step) {
      StudioStep.basics => l10n.studioStepBasics,
      StudioStep.location => l10n.studioStepLocation,
      StudioStep.photos => l10n.studioStepPhotos,
      StudioStep.details => l10n.studioStepDetails,
      StudioStep.pricing => l10n.studioStepPricing,
      StudioStep.review => l10n.studioStepReview,
    };

class _LiveNote extends StatelessWidget {
  const _LiveNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.warning),
        ),
        child: Text(text, style: AppTypography.body(size: 13)),
      );
}

class _FinalActions extends StatelessWidget {
  const _FinalActions({
    required this.state,
    required this.onBack,
    required this.onDraft,
    required this.onSubmit,
  });

  final VenueStudioState state;
  final VoidCallback onBack;
  final VoidCallback onDraft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final back = OutlinedButton(
      onPressed: onBack,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      child: Text(l10n.studioBack),
    );
    // A live venue only ever keeps its changes; it never goes back to draft.
    if (state.live) {
      return Row(
        children: [
          back,
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: l10n.studioSaveChanges,
              isLoading: state.saving,
              onPressed: state.draft.readyToSubmit && state.overlapping.isEmpty
                  ? onSubmit
                  : null,
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
          label: l10n.studioSubmit,
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
                child: Text(l10n.studioSaveDraft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -- Steps ------------------------------------------------------------------

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({required this.state, required this.ref, required this.id});

  final VenueStudioState state;
  final WidgetRef ref;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = state.draft;
    final edit = ref.read(venueStudioProvider(id).notifier).edit;
    final categories = {
      'indoor': l10n.studioCategoryIndoor,
      'outdoor': l10n.studioCategoryOutdoor,
      'hotel': l10n.studioCategoryHotel,
      'beach_resort': l10n.studioCategoryBeachResort,
      'garden': l10n.studioCategoryGarden,
      'mix': l10n.studioCategoryMix,
      'other': l10n.studioCategoryOther,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioField(
          label: l10n.studioName,
          value: d.name,
          onChanged: (v) => edit((x) => x.copyWith(name: v)),
        ),
        StudioField(
          label: l10n.studioDescription,
          value: d.description,
          maxLines: 4,
          onChanged: (v) => edit((x) => x.copyWith(description: v)),
        ),
        StudioField(
          label: l10n.studioCapacity,
          value: d.capacity?.toString() ?? '',
          number: true,
          onChanged: (v) {
            final n = int.tryParse(v);
            edit(
              (x) => n == null
                  ? x.copyWith(clearCapacity: true)
                  : x.copyWith(capacity: n),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(l10n.studioCategory, style: AppTypography.label()),
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
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.state,
    required this.ref,
    required this.id,
  });

  final VenueStudioState state;
  final WidgetRef ref;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = state.draft;
    final studio = ref.read(venueStudioProvider(id).notifier);
    final edit = studio.edit;
    final overlapping = state.overlapping;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioField(
                label: l10n.studioAddress,
                value: d.address,
                onChanged: (v) => edit((x) => x.copyWith(address: v)),
              ),
              PlaceFields(
                country: d.country,
                state: d.state,
                city: d.city,
                countries: state.countries,
                states: state.states,
                cities: state.cities,
                locating: state.locating,
                locateProblem: state.locateProblem,
                onCountryText: (v) => edit((x) => x.copyWith(country: v)),
                onStateText: (v) => edit((x) => x.copyWith(state: v)),
                onCityText: studio.pickCity,
                onPickCountry: studio.pickCountry,
                onPickState: studio.pickState,
                onUseMyLocation: studio.useMyLocation,
              ),
            ],
          ),
        ),
        StudioCard(
          title: l10n.studioServiceArea,
          hint: l10n.studioServiceAreaHint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceAreaMap(
                center: d.center,
                radiusMeters: d.radiusMeters,
                neighbours: state.neighbours,
                onPin: (p) => edit((x) => x.copyWith(center: p)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(l10n.studioRadius, style: AppTypography.label()),
                  Expanded(
                    child: Slider(
                      value: d.radiusMeters.clamp(100, 2000).toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      activeColor: AppColors.accent,
                      onChanged: (v) =>
                          edit((x) => x.copyWith(radiusMeters: v)),
                    ),
                  ),
                  Text(l10n.studioRadiusValue(d.radiusMeters.round())),
                ],
              ),
              if (d.center == null)
                Text(
                  l10n.studioNoPin,
                  style:
                      AppTypography.body(size: 13, color: AppColors.textMuted),
                ),
              if (overlapping.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.studioOverlap(overlapping.join(', ')),
                    style:
                        AppTypography.body(size: 13, color: AppColors.warning),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({required this.state, required this.ref, required this.id});

  final VenueStudioState state;
  final WidgetRef ref;
  final String? id;

  Future<void> _add(WidgetRef ref) async {
    final photo = await ref.read(photoPickerProvider).pick();
    if (photo == null) return;
    await ref.read(venueStudioProvider(id).notifier).addPhoto(photo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photos = state.draft.photos;
    final controller = ref.read(venueStudioProvider(id).notifier);
    return StudioCard(
      title: l10n.studioPhotoCount(photos.length, 5),
      hint: l10n.studioPhotosHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              // Three to a row, whatever the screen.
              final size = (box.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    Stack(
                      children: [
                        PhotoBox(
                          url: photos[i].url,
                          width: size,
                          height: size,
                          radius: 12,
                        ),
                        if (i == 0)
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: AppRadius.brPill,
                              ),
                              child: Text(
                                l10n.studioCover,
                                style: AppTypography.label(
                                  color: AppColors.onAccent,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton.filled(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                controller.removePhoto(photos[i].fileId),
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                        ),
                      ],
                    ),
                  if (photos.length < 5)
                    InkWell(
                      onTap: state.uploading ? null : () => _add(ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderStrong),
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
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.studioAddPhoto,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.label(),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (state.error == 'photo')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                state.errorDetail == null
                    ? l10n.studioPhotoFailed
                    : l10n.studioPhotoFailedWhy(state.errorDetail!),
                style: AppTypography.body(size: 13, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// What a venue can offer. Hosts pick from these or add their own, which is
/// what the web does with its resource palette.
const _presets = <String, List<String>>{
  'spaceType': ['Main hall', 'Garden', 'Rooftop', 'Poolside', 'Function room'],
  'amenities': ['Wi-Fi', 'Parking', 'Air conditioning', 'Restrooms', 'Kitchen'],
  'techAv': ['Sound system', 'Projector', 'Microphones', 'Stage lighting'],
  'staffing': ['Security', 'Ushers', 'Cleaning crew', 'Event coordinator'],
  'policies': ['No smoking', 'No outside alcohol', 'Quiet after 10pm'],
};

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.state,
    required this.ref,
    required this.id,
  });

  final VenueStudioState state;
  final WidgetRef ref;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = state.draft;
    final edit = ref.read(venueStudioProvider(id).notifier).edit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          title: l10n.studioSpaceType,
          presets: _presets['spaceType']!,
          chosen: d.spaceType,
          onChanged: (v) => edit((x) => x.copyWith(spaceType: v)),
        ),
        _Group(
          title: l10n.studioAmenities,
          presets: _presets['amenities']!,
          chosen: d.amenities,
          onChanged: (v) => edit((x) => x.copyWith(amenities: v)),
        ),
        _Group(
          title: l10n.studioTechAv,
          presets: _presets['techAv']!,
          chosen: d.techAv,
          onChanged: (v) => edit((x) => x.copyWith(techAv: v)),
        ),
        _Group(
          title: l10n.studioStaffing,
          presets: _presets['staffing']!,
          chosen: d.staffing,
          onChanged: (v) => edit((x) => x.copyWith(staffing: v)),
        ),
        _Group(
          title: l10n.studioPolicies,
          presets: _presets['policies']!,
          chosen: d.policies,
          onChanged: (v) => edit((x) => x.copyWith(policies: v)),
        ),
      ],
    );
  }
}

class _Group extends StatefulWidget {
  const _Group({
    required this.title,
    required this.presets,
    required this.chosen,
    required this.onChanged,
  });

  final String title;
  final List<String> presets;
  final List<String> chosen;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String item) {
    final has = widget.chosen.contains(item);
    widget.onChanged([
      for (final c in widget.chosen)
        if (c != item) c,
      if (!has) item,
    ]);
  }

  void _addCustom() {
    final text = _custom.text.trim();
    if (text.isEmpty) return;
    _custom.clear();
    if (!widget.chosen.contains(text)) {
      widget.onChanged([...widget.chosen, text]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Presets first, then anything the host typed (or the web saved).
    final items = [
      ...widget.presets,
      for (final c in widget.chosen)
        if (!widget.presets.contains(c)) c,
    ];
    return StudioCard(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                FilterChip(
                  label: Text(item),
                  selected: widget.chosen.contains(item),
                  onSelected: (_) => _toggle(item),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _custom,
            decoration: InputDecoration(
              hintText: l10n.studioAddCustom,
              suffixIcon: IconButton(
                onPressed: _addCustom,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            onSubmitted: (_) => _addCustom(),
          ),
        ],
      ),
    );
  }
}

class _PricingStep extends StatelessWidget {
  const _PricingStep({
    required this.state,
    required this.ref,
    required this.id,
  });

  final VenueStudioState state;
  final WidgetRef ref;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = state.draft;
    final edit = ref.read(venueStudioProvider(id).notifier).edit;
    final rates = {
      'hourly': l10n.studioRateHourly,
      'daily': l10n.studioRateDaily,
      'weekly': l10n.studioRateWeekly,
      'monthly': l10n.studioRateMonthly,
      'yearly': l10n.studioRateYearly,
      'one_time': l10n.studioRateOneTime,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioField(
          label: l10n.studioPrice,
          value: d.price?.toString() ?? '',
          number: true,
          onChanged: (v) {
            final n = double.tryParse(v);
            edit(
              (x) => n == null
                  ? x.copyWith(clearPrice: true)
                  : x.copyWith(price: n),
            );
          },
        ),
        Text(l10n.studioBillingRate, style: AppTypography.label()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in rates.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: d.billingRate == entry.key,
                onSelected: (_) =>
                    edit((x) => x.copyWith(billingRate: entry.key)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StudioField(
          label: l10n.studioExtraGuest,
          value: d.extraGuestRate?.toString() ?? '',
          number: true,
          onChanged: (v) {
            final n = double.tryParse(v);
            if (n != null) edit((x) => x.copyWith(extraGuestRate: n));
          },
        ),
        if (state.policies.isNotEmpty) ...[
          Text(l10n.studioCancellation, style: AppTypography.label()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final policy in state.policies)
                ChoiceChip(
                  label: Text(policy.name),
                  selected: d.cancellationPolicyId == policy.id,
                  onSelected: (_) =>
                      edit((x) => x.copyWith(cancellationPolicyId: policy.id)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final VenueStudioState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final missing = state.draft.missing;
    final labels = {
      'name': l10n.studioMissingName,
      'category': l10n.studioMissingCategory,
      'description': l10n.studioMissingDescription,
      'capacity': l10n.studioMissingCapacity,
      'address': l10n.studioMissingAddress,
      'location': l10n.studioMissingLocation,
      'photos': l10n.studioMissingPhotos,
      'price': l10n.studioMissingPrice,
    };
    final overlapping = state.overlapping;
    if (missing.isEmpty && overlapping.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 8),
          Text(l10n.studioReviewReady, style: AppTypography.display()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missing.isNotEmpty) ...[
          Text(
            l10n.studioReviewMissing,
            style: AppTypography.display(),
          ),
          const SizedBox(height: 8),
          for (final key in missing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(labels[key] ?? key),
                ],
              ),
            ),
        ],
        if (overlapping.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.studioOverlap(overlapping.join(', ')),
              style: AppTypography.body(size: 13, color: AppColors.warning),
            ),
          ),
      ],
    );
  }
}
