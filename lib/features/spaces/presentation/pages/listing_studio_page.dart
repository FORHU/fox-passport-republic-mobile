import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/listing_draft.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/listing_studio_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/studio_chrome.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/studio_fields.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Adds a service or a piece of gear, or edits one the person already has.
/// One scrolling form: what it is, the price, where it is and its photos.
class ListingStudioPage extends ConsumerWidget {
  const ListingStudioPage({required this.kind, this.listingId, super.key});

  final ProviderKind kind;

  /// The listing to edit; null to add a new one.
  final String? listingId;

  ListingTarget get _target => (kind: kind, id: listingId);

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required bool submit,
  }) async {
    final l10n = context.l10n;
    final live = ref.read(listingStudioProvider(_target)).live;
    final ok = await ref
        .read(listingStudioProvider(_target).notifier)
        .save(submit: submit);
    if (!context.mounted) return;
    if (!ok) {
      showTopToast(
        context,
        ref.read(listingStudioProvider(_target)).errorDetail ??
            l10n.studioSaveFailed,
      );
      return;
    }
    ref.invalidate(kind.isGear ? myAssetsProvider : myServicesProvider);
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
    final state = ref.watch(listingStudioProvider(_target));
    final controller = ref.read(listingStudioProvider(_target).notifier);

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
        onAction: () => ref.invalidate(listingStudioProvider(_target)),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (state.live) _LiveNote(text: l10n.listingLiveNote),
          _BasicsCard(kind: kind, state: state, controller: controller),
          _PriceCard(kind: kind, state: state, controller: controller),
          _PlaceCard(kind: kind, state: state, controller: controller),
          _PhotosCard(
            state: state,
            controller: controller,
            canChange: listingId == null,
          ),
        ],
      );
    }

    final ready = state.draft.isComplete(kind);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          listingId != null
              ? l10n.listingTitleEdit
              : kind.isGear
                  ? l10n.listingTitleNewGear
                  : l10n.listingTitleNewService,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: body,
      bottomNavigationBar: state.loading || state.loadFailed
          ? null
          : StudioBar(
              child: state.live
                  ? AppButton(
                      label: l10n.studioSaveChanges,
                      isLoading: state.saving,
                      onPressed: ready
                          ? () => _save(context, ref, submit: true)
                          : null,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          label: l10n.studioSubmit,
                          isLoading: state.saving,
                          onPressed: ready
                              ? () => _save(context, ref, submit: true)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: ready && !state.saving
                              ? () => _save(context, ref, submit: false)
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(l10n.studioSaveDraft),
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _LiveNote extends StatelessWidget {
  const _LiveNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentTintBg,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.accentTintBorder),
        ),
        child: Text(text, style: AppTypography.body(size: 13)),
      );
}

String categoryLabel(AppLocalizations l10n, String code) => switch (code) {
      'design' => l10n.listingCatDesign,
      'catering' => l10n.listingCatCatering,
      'service_staff' => l10n.listingCatStaff,
      'photography' => l10n.listingCatPhotography,
      'videography' => l10n.listingCatVideography,
      'dj' => l10n.listingCatDj,
      'live_band' => l10n.listingCatLiveBand,
      'mc' => l10n.listingCatMc,
      'furnitures' => l10n.listingCatFurniture,
      'sound_system' => l10n.listingCatSound,
      'decorations' => l10n.listingCatDecorations,
      'equipment' => l10n.listingCatEquipment,
      _ => l10n.listingCatOther,
    };

String _rateLabel(AppLocalizations l10n, String code) => switch (code) {
      'hourly' => l10n.listingRateHourly,
      'daily' => l10n.listingRateDaily,
      'weekly' => l10n.listingRateWeekly,
      'monthly' => l10n.listingRateMonthly,
      'yearly' => l10n.listingRateYearly,
      _ => l10n.listingRateOneTime,
    };

String _conditionLabel(AppLocalizations l10n, String code) => switch (code) {
      'new' => l10n.listingConditionNew,
      'fair' => l10n.listingConditionFair,
      'refurbished' => l10n.listingConditionRefurbished,
      _ => l10n.listingConditionGood,
    };

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String Function(String) labelOf;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(labelOf(o))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}

class _BasicsCard extends ConsumerWidget {
  const _BasicsCard({
    required this.kind,
    required this.state,
    required this.controller,
  });

  final ProviderKind kind;
  final ListingStudioState state;
  final ListingStudioController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = state.draft;
    final roles = ref.watch(heldRolesProvider);
    // A service goes under the categories the person is approved for.
    final categories = kind.isGear
        ? gearCategories
        : [
            for (final c in serviceCategories)
              if (c == d.category ||
                  (performerCategories.contains(c)
                      ? roles.contains('performerFoxer')
                      : roles.contains('serviceFoxer')))
                c,
          ];
    return StudioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Dropdown(
            label: l10n.listingCategory,
            value: d.category,
            options: categories,
            labelOf: (c) => categoryLabel(l10n, c),
            onChanged: (v) => controller.edit((x) => x.copyWith(category: v)),
          ),
          StudioField(
            label: l10n.listingName,
            value: d.name,
            onChanged: (v) => controller.edit((x) => x.copyWith(name: v)),
          ),
          StudioField(
            label: l10n.listingDescription,
            value: d.description,
            maxLines: 4,
            onChanged: (v) =>
                controller.edit((x) => x.copyWith(description: v)),
          ),
          if (!kind.isGear)
            // The card behind it has a colour, so the tile needs its own
            // Material to paint its splash on.
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.listingTravel),
                value: d.willingToTravel,
                activeThumbColor: AppColors.accent,
                onChanged: (v) =>
                    controller.edit((x) => x.copyWith(willingToTravel: v)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.kind,
    required this.state,
    required this.controller,
  });

  final ProviderKind kind;
  final ListingStudioState state;
  final ListingStudioController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = state.draft;
    return StudioCard(
      title: l10n.listingPriceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioField(
            label: l10n.listingPrice(d.currency),
            value: d.price?.toString() ?? '',
            number: true,
            onChanged: (v) {
              final n = num.tryParse(v.trim());
              controller.edit(
                (x) => n == null
                    ? x.copyWith(clearPrice: true)
                    : x.copyWith(price: n),
              );
            },
          ),
          _Dropdown(
            label: l10n.listingBilling,
            value: d.billingRate,
            options: billingRates,
            labelOf: (r) => _rateLabel(l10n, r),
            onChanged: (v) =>
                controller.edit((x) => x.copyWith(billingRate: v)),
          ),
          if (kind.isGear) ...[
            StudioField(
              label: l10n.listingQuantity,
              value: '${d.quantity}',
              number: true,
              onChanged: (v) {
                final n = int.tryParse(v.trim());
                if (n != null && n >= 1) {
                  controller.edit((x) => x.copyWith(quantity: n));
                }
              },
            ),
            _Dropdown(
              label: l10n.listingCondition,
              value: d.condition,
              options: gearConditions,
              labelOf: (c) => _conditionLabel(l10n, c),
              onChanged: (v) =>
                  controller.edit((x) => x.copyWith(condition: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.kind,
    required this.state,
    required this.controller,
  });

  final ProviderKind kind;
  final ListingStudioState state;
  final ListingStudioController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = state.draft;
    return StudioCard(
      title: l10n.listingWhere,
      hint: kind.isGear ? l10n.listingWhereGearHint : null,
      child: PlaceFields(
        country: d.country,
        state: d.state,
        city: d.city,
        countries: state.countries,
        states: state.states,
        cities: state.cities,
        locating: state.locating,
        locateProblem: state.locateProblem,
        onCountryText: (v) => controller.edit((x) => x.copyWith(country: v)),
        onStateText: (v) => controller.edit((x) => x.copyWith(state: v)),
        onCityText: controller.pickCity,
        onPickCountry: controller.pickCountry,
        onPickState: controller.pickState,
        onUseMyLocation: controller.useMyLocation,
      ),
    );
  }
}

class _PhotosCard extends ConsumerWidget {
  const _PhotosCard({
    required this.state,
    required this.controller,
    required this.canChange,
  });

  final ListingStudioState state;
  final ListingStudioController controller;

  /// False when editing: the API cannot change a saved listing's photos.
  final bool canChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final photos = state.draft.photos;
    return StudioCard(
      title: l10n.studioPhotoCount(photos.length, 5),
      hint: canChange ? l10n.studioPhotosHint : l10n.listingPhotosLocked,
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
                        if (canChange)
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
                  if (canChange && photos.length < 5)
                    InkWell(
                      onTap: state.uploading
                          ? null
                          : () async {
                              final photo =
                                  await ref.read(photoPickerProvider).pick();
                              if (photo != null) {
                                await controller.addPhoto(photo);
                              }
                            },
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
