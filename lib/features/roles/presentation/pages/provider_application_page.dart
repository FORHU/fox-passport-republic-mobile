import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/domain/provider_application.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/domain/work_links.dart';
import 'package:flutter_template/features/roles/presentation/controllers/provider_application_controller.dart';
import 'package:flutter_template/features/roles/presentation/widgets/apply_wizard.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/features/roles/presentation/widgets/experience_field.dart';
import 'package:flutter_template/features/roles/presentation/widgets/suggest_specialty.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Applying to be a Provider, in four steps (mobile#487): business,
/// categories, a line and photos per category, documents; then review and
/// send. The layout follows the "Become a Provider" designs.
class ProviderApplicationPage extends ConsumerWidget {
  const ProviderApplicationPage({super.key});

  void _leave(BuildContext context, WidgetRef ref) {
    if (ref.read(providerApplicationProvider).step == ProviderApplyStep.sent) {
      ref.read(providerApplicationProvider.notifier).reset();
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.roles);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerApplicationProvider);
    final controller = ref.read(providerApplicationProvider.notifier);
    final step = state.step;
    final leaves =
        step == ProviderApplyStep.intro || step == ProviderApplyStep.sent;
    return PopScope(
      canPop: leaves,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          controller.back();
        } else if (step == ProviderApplyStep.sent) {
          controller.reset();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: switch (step) {
            ProviderApplyStep.intro => _Intro(
                onClose: () => _leave(context, ref),
                onStart: controller.next,
              ),
            ProviderApplyStep.business => const _BusinessStep(),
            ProviderApplyStep.categories => const _CategoriesStep(),
            ProviderApplyStep.details => const _DetailsStep(),
            ProviderApplyStep.documents => const _DocumentsStep(),
            ProviderApplyStep.review => const _ReviewStep(),
            ProviderApplyStep.sent => _Sent(onDone: () => _leave(context, ref)),
          },
        ),
      ),
    );
  }
}

/// The names the catalog gives each slug, once it has loaded.
Map<String, String> _names(WidgetRef ref) => {
      for (final s in ref.watch(providerSpecialtiesProvider).value ??
          const <ProviderSpecialty>[])
        s.slug: s.name,
    };

// ---------------------------------------------------------------- step 1

class _BusinessStep extends ConsumerWidget {
  const _BusinessStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(providerApplicationProvider.select((s) => s.draft));
    final locate = ref.watch(
      providerApplicationProvider.select(
        (s) => (
          busy: s.locating,
          problem: s.locateProblem,
          count: s.locatedCount,
        ),
      ),
    );
    final c = ref.read(providerApplicationProvider.notifier);
    return ApplyScreen(
      header: const _StepHeader(1),
      footerBorder: false,
      footer: [
        AppButton(
          label: l10n.provApplyNextCategories,
          onPressed: d.businessDone ? c.next : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyStepBusiness),
        ApplyField(
          label: l10n.roleApplyBusiness,
          help: l10n.provApplyBusinessNameHelp,
          child: TextFormField(
            initialValue: d.businessName,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => c.edit((x) => x.copyWith(businessName: v)),
          ),
        ),
        ApplyField(
          label: l10n.provApplyBasedIn,
          child: TextFormField(
            // A new key when the location fills it, so the text shows.
            key: ValueKey('basedIn-${locate.count}'),
            initialValue: d.basedIn,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l10n.provApplyBasedInHint,
              helperText: switch (locate.problem) {
                LocateOutcome.denied => l10n.areaLocationDenied,
                LocateOutcome.serviceOff => l10n.areaLocationOff,
                LocateOutcome.failed => l10n.provApplyLocateFailed,
                _ => null,
              },
              helperMaxLines: 3,
              helperStyle: AppTypography.body(
                size: 12,
                color: AppColors.warning,
              ),
              suffixIcon: locate.busy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: l10n.studioUseMyLocation,
                      onPressed: c.useMyLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      color: AppColors.accent,
                    ),
            ),
            onChanged: c.setBasedIn,
          ),
        ),
        ApplyField(
          label: l10n.provApplyTravel,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final range in TravelRange.values)
                ApplyPill(
                  label: switch (range) {
                    TravelRange.city => l10n.provApplyTravelCity,
                    TravelRange.province => l10n.provApplyTravelProvince,
                    TravelRange.anywhere => l10n.provApplyTravelAnywhere,
                  },
                  selected: d.travelRange == range,
                  onTap: () => c.edit((x) => x.copyWith(travelRange: range)),
                ),
            ],
          ),
        ),
        // Up to 30, or a CV-backed claim up to 50 (mobile#535).
        ApplyYearsOfExperience(
          label: l10n.provApplyYears,
          experience: d.experience,
          claiming: d.claimingExperience,
          cv: d.experienceCv,
          onExperienceChanged: (v) => c.edit((x) => x.copyWith(experience: v)),
          onClaimingChanged: (v) =>
              c.edit((x) => x.copyWith(claimingExperience: v)),
          onCvPicked: (p) => c.edit((x) => x.copyWith(experienceCv: p)),
          onCvRemoved: () => c.edit((x) => x.copyWith(clearExperienceCv: true)),
        ),
        ApplyField(
          label: l10n.provApplyLinks,
          help: l10n.provApplyLinksHelp,
          child: Column(
            children: [
              for (final kind in WorkLinkKind.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WorkLinkField(
                    kind: kind,
                    value: d.links[kind] ?? '',
                    problem: d.linkProblems[kind],
                    onChanged: (v) => c.edit(
                      (x) => x.copyWith(links: {...x.links, kind: v}),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One place a Provider shows their work: its icon and a field for the link
/// (mobile#519).
class _WorkLinkField extends StatelessWidget {
  const _WorkLinkField({
    required this.kind,
    required this.value,
    required this.problem,
    required this.onChanged,
  });

  final WorkLinkKind kind;
  final String value;
  final WorkLinkProblem? problem;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (name, hint, icon) = switch (kind) {
      WorkLinkKind.facebook => (
          l10n.provLinkFacebook,
          l10n.provLinkFacebookHint,
          FontAwesomeIcons.facebook,
        ),
      WorkLinkKind.instagram => (
          l10n.provLinkInstagram,
          l10n.provLinkInstagramHint,
          FontAwesomeIcons.instagram,
        ),
      WorkLinkKind.tiktok => (
          l10n.provLinkTiktok,
          l10n.provLinkTiktokHint,
          FontAwesomeIcons.tiktok,
        ),
      WorkLinkKind.youtube => (
          l10n.provLinkYoutube,
          l10n.provLinkYoutubeHint,
          FontAwesomeIcons.youtube,
        ),
      WorkLinkKind.website => (
          l10n.provLinkWebsite,
          l10n.provLinkWebsiteHint,
          FontAwesomeIcons.globe,
        ),
    };
    return TextFormField(
      key: Key('work-link-${kind.name}'),
      initialValue: value,
      keyboardType: TextInputType.url,
      autocorrect: false,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: name,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: SizedBox(
          width: 48,
          child: Center(
            child: FaIcon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        errorText: switch (problem) {
          WorkLinkProblem.invalid => l10n.provLinkInvalid,
          WorkLinkProblem.wrongSite => l10n.provLinkWrongSite(name),
          null => null,
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- step 2

class _CategoriesStep extends ConsumerWidget {
  const _CategoriesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(providerApplicationProvider.select((s) => s.draft));
    final c = ref.read(providerApplicationProvider.notifier);
    final names = _names(ref);
    final main = d.mainSpecialty;
    return ApplyScreen(
      header: const _StepHeader(2),
      footer: [
        Text(
          d.specializations.isEmpty || main == null
              ? l10n.provApplyNothingPicked
              : l10n.provApplyPickedSummary(
                  d.specializations.length,
                  names[main] ?? main,
                ),
          style: AppTypography.body(size: 13),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: d.categoriesDone
              ? l10n.provApplyNextDetails
              : l10n.provApplyPickOne,
          onPressed: d.categoriesDone ? c.next : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyCategoriesTitle, l10n.provApplyCategoriesBody),
        ref.watch(providerSpecialtiesProvider).when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => AppStateView(
                kind: AppStateKind.error,
                title: l10n.apiLoadFailed,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(providerSpecialtiesProvider),
              ),
              data: (list) {
                Widget cards(List<ProviderSpecialty> items) => LayoutBuilder(
                      builder: (context, box) {
                        final width = (box.maxWidth - 8) / 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in items)
                              SizedBox(
                                width: width,
                                child: ApplyCategoryCard(
                                  name: s.name,
                                  picked: d.specializations.contains(s.slug),
                                  isMain: main == s.slug,
                                  onTap: () => c.toggle(s.slug),
                                  onMakeMain: () => c.makeMain(s.slug),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                final groups = groupSpecialties(list);
                // An API from before main categories (api#503): one list.
                if (groups.every((g) => g.$1 == null)) return cards(list);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (group, items) in groups)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GroupHeading(
                              group: group,
                              total: items.length,
                              picked: items
                                  .where(
                                    (s) => d.specializations.contains(s.slug),
                                  )
                                  .length,
                            ),
                            const SizedBox(height: 10),
                            cards(items),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        const SizedBox(height: 18),
        const SuggestSpecialty(),
      ],
    );
  }
}

/// A main category's heading (api#503): an icon, its name, and how many of
/// its subcategories are picked. Not tappable: only the subcategories under it
/// are picked, which is what tells the two apart.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({
    required this.group,
    required this.total,
    required this.picked,
  });

  /// Null for the specialties that have no main category.
  final ProviderSpecialtyGroup? group;
  final int total;
  final int picked;

  static IconData _icon(String? name) => switch (name) {
        'speaker' => Icons.speaker_outlined,
        'photo_camera' => Icons.photo_camera_outlined,
        'music_note' => Icons.music_note_outlined,
        'restaurant' => Icons.restaurant_outlined,
        'celebration' => Icons.celebration_outlined,
        'chair' => Icons.chair_outlined,
        'support_agent' => Icons.support_agent_outlined,
        'face' => Icons.face_outlined,
        'directions_car' => Icons.directions_car_outlined,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = group?.name ?? l10n.provApplyGroupOther;
    return Semantics(
      header: true,
      label: l10n.provApplyGroupSemantics(name, picked),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon(group?.icon),
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  applyEyebrow(l10n.provApplyGroupEyebrow),
                  const SizedBox(height: 2),
                  Text(name, style: AppTypography.display(size: 17)),
                ],
              ),
            ),
            Text(
              picked > 0
                  ? l10n.provApplyGroupPicked(picked)
                  : l10n.provApplyGroupCount(total),
              style: AppTypography.body(
                size: 12,
                color: picked > 0 ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- step 3

class _DetailsStep extends ConsumerWidget {
  const _DetailsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(providerApplicationProvider);
    final d = state.draft;
    final c = ref.read(providerApplicationProvider.notifier);
    final names = _names(ref);
    return ApplyScreen(
      header: const _StepHeader(3),
      footer: [
        AppButton(
          label: l10n.provApplyNextDocuments,
          onPressed: d.detailsDone ? c.next : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyDetailsTitle, l10n.provApplyDetailsBody),
        for (final slug in d.orderedSpecializations)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: slug == state.openDetail
                ? _DetailEditor(
                    slug: slug,
                    name: names[slug] ?? slug,
                    isMain: slug == d.mainSpecialty,
                    detail: d.detailFor(slug),
                  )
                : _DetailSummary(
                    name: names[slug] ?? slug,
                    detail: d.detailFor(slug),
                    onOpen: () => c.openDetail(slug),
                  ),
          ),
      ],
    );
  }
}

class _DetailEditor extends ConsumerWidget {
  const _DetailEditor({
    required this.slug,
    required this.name,
    required this.isMain,
    required this.detail,
  });

  final String slug;
  final String name;
  final bool isMain;
  final ProviderSpecialtyDetail detail;

  Future<void> _addPhoto(WidgetRef ref) async {
    final photo = await ref.read(photoPickerProvider).pick();
    if (photo == null) return;
    ref.read(providerApplicationProvider.notifier).addPhoto(slug, photo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = ref.read(providerApplicationProvider.notifier);
    final canAdd = detail.photos.length < ProviderApplicationDraft.maxPhotos;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: applyCard(strong: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: AppTypography.display()),
              ),
              if (isMain)
                Text(
                  l10n.provApplyMain,
                  style: AppTypography.label(color: AppColors.accent),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ApplyField(
            label: l10n.provApplyWhatYouOffer,
            child: TextFormField(
              key: ValueKey('detail-$slug'),
              initialValue: detail.description,
              minLines: 3,
              maxLines: 5,
              maxLength: ProviderApplicationDraft.maxDescription,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(counterText: ''),
              onChanged: (v) => c.setDescription(slug, v),
            ),
          ),
          Text.rich(
            TextSpan(
              text: '${l10n.provApplyPhotos} ',
              style: AppTypography.body(size: 13),
              children: [
                TextSpan(
                  text: l10n.provApplyPhotosMax(
                    ProviderApplicationDraft.maxPhotos,
                  ),
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (i, photo) in detail.photos.indexed)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.memory(
                        photo.bytes,
                        fit: BoxFit.cover,
                        semanticLabel: photo.name,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        tooltip: l10n.provApplyRemovePhoto,
                        onPressed: () => c.removePhoto(slug, i),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.scrim,
                          minimumSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              if (canAdd)
                Tooltip(
                  message: l10n.provApplyAddPhoto,
                  child: OutlinedButton(
                    onPressed: () => _addPhoto(ref),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.inputBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      semanticLabel: l10n.provApplyAddPhoto,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSummary extends StatelessWidget {
  const _DetailSummary({
    required this.name,
    required this.detail,
    required this.onOpen,
  });

  final String name;
  final ProviderSpecialtyDetail detail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = detail.isDone;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.display()),
                    const SizedBox(height: 2),
                    Text(
                      done
                          ? l10n.provApplyDetailDone(detail.photos.length)
                          : l10n.provApplyDetailTodo,
                      style: AppTypography.body(
                        size: 12,
                        color: done ? AppColors.textMuted : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_rounded : Icons.chevron_right_rounded,
                color: done ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- step 4

class _DocumentsStep extends ConsumerWidget {
  const _DocumentsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(providerApplicationProvider.select((s) => s.draft));
    final c = ref.read(providerApplicationProvider.notifier);
    return ApplyScreen(
      header: const _StepHeader(4),
      footer: [
        if (!d.documentsDone) ...[
          Text(
            l10n.provApplyDocsLeft(d.documentsMissing),
            style: AppTypography.body(size: 13, color: AppColors.warning),
          ),
          const SizedBox(height: 8),
        ],
        AppButton(
          label: l10n.provApplyReviewButton,
          onPressed: d.documentsDone ? c.next : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyDocumentsTitle, l10n.provApplyDocumentsBody),
        for (final doc in ProviderApplicationDraft.askedDocuments)
          DocumentRow(
            boxed: true,
            optional: !ProviderApplicationDraft.requiredDocuments.contains(doc),
            label: applyDocumentLabel(l10n, doc),
            note: applyDocumentNote(l10n, doc),
            photo: d.documents[doc],
            frontCamera: doc == KycDocument.selfie,
            onPicked: (p) => c.setDocument(doc, p),
            onRemove: () => c.removeDocument(doc),
          ),
        const SizedBox(height: 6),
        applyEyebrow(l10n.provApplyForCategories),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: applyCard().copyWith(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.provApplyForCategoriesBody,
                  style: AppTypography.body(size: 13).copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- review

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(providerApplicationProvider);
    final d = state.draft;
    final c = ref.read(providerApplicationProvider.notifier);
    final names = _names(ref);
    final travel = switch (d.travelRange) {
      TravelRange.city => l10n.provApplyTravelCity,
      TravelRange.province => l10n.provApplyTravelProvince,
      TravelRange.anywhere => l10n.provApplyTravelAnywhere,
      null => null,
    };
    final years = d.years;
    final businessLine = [
      d.basedIn.trim(),
      if (travel != null) travel,
      if (years != null)
        experienceReviewLabel(l10n, years, claiming: d.claimingExperience),
    ].join(' · ');
    final error = state.error;
    return ApplyScreen(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.provApplyBack,
              onPressed: c.back,
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
              color: AppColors.textPrimary,
            ),
            Text(l10n.provApplyReview, style: AppTypography.display(size: 17)),
          ],
        ),
      ),
      footer: [
        if (error != null) ...[
          Text(
            error.isEmpty ? l10n.roleApplyFailed : error,
            style: AppTypography.body(size: 13, color: AppColors.error),
          ),
          const SizedBox(height: 8),
        ],
        AppButton(
          label: l10n.roleApplySubmit,
          isLoading: state.submitting,
          onPressed: d.isComplete ? c.submit : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyCheckAndSend),
        ApplyReviewSection(
          title: l10n.provApplyBusinessSection,
          onEdit: () => c.goTo(ProviderApplyStep.business),
          children: [
            Text(
              d.businessName.trim(),
              style: AppTypography.body(size: 15, color: AppColors.textPrimary),
            ),
            if (businessLine.isNotEmpty)
              Text(businessLine, style: AppTypography.body(size: 13)),
          ],
        ),
        ApplyReviewSection(
          title: l10n.provApplyCategoriesSection,
          onEdit: () => c.goTo(ProviderApplyStep.categories),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slug in d.orderedSpecializations)
                  ApplyTag(
                    label: names[slug] ?? slug,
                    main: slug == d.mainSpecialty ? l10n.provApplyMain : null,
                  ),
              ],
            ),
            Text(
              l10n.provApplyEachDescribed,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        ApplyReviewSection(
          title: l10n.provApplyDocumentsSection,
          onEdit: () => c.goTo(ProviderApplyStep.documents),
          children: [
            ApplyAllDocuments(
              count: ProviderApplicationDraft.askedDocuments
                  .where(d.documents.containsKey)
                  .length,
            ),
          ],
        ),
        CheckboxListTile(
          value: d.agreed,
          onChanged: (v) => c.edit((x) => x.copyWith(agreed: v ?? false)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.textPrimary,
          checkColor: AppColors.onLightSurface,
          title: Text(
            l10n.provApplyAgree,
            style: AppTypography.body(size: 13).copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.provApplyReviewNote,
                style: AppTypography.body(size: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- wrappers

/// The shared step header, going back through this wizard.
class _StepHeader extends ConsumerWidget {
  const _StepHeader(this.number);

  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ApplyStepHeader(
        number: number,
        total: 4,
        onBack: () => ref.read(providerApplicationProvider.notifier).back(),
      );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onClose, required this.onStart});

  final VoidCallback onClose;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ApplyIntro(
      top: const ApplyRoleSwitch(current: 'providerFoxer'),
      eyebrow: l10n.provApplyEyebrow,
      eyebrowColor: AppColors.roleProvider,
      title: l10n.provApplyIntroTitle,
      body: l10n.provApplyIntroBody,
      steps: [
        (l10n.provApplyStepBusiness, l10n.provApplyStepBusinessHint),
        (l10n.provApplyStepCategories, l10n.provApplyStepCategoriesHint),
        (l10n.provApplyStepDetails, l10n.provApplyStepDetailsHint),
        (l10n.provApplyStepDocuments, l10n.provApplyStepDocumentsHint),
      ],
      duration: l10n.provApplyDuration,
      onClose: onClose,
      onStart: onStart,
    );
  }
}

class _Sent extends ConsumerWidget {
  const _Sent({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerApplicationProvider);
    final names = _names(ref);
    return ApplySent(
      sentAt: state.sentAt ?? DateTime.now(),
      tags: [
        for (final slug in state.draft.orderedSpecializations)
          names[slug] ?? slug,
      ],
      onDone: onDone,
    );
  }
}
