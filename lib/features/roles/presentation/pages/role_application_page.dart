import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_application_controller.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Applying for a role from the phone (Provider, Venue, Event or Organizer):
/// what they offer, a few details, and the documents an admin checks. One
/// scrolling form.
class RoleApplicationPage extends ConsumerStatefulWidget {
  const RoleApplicationPage({required this.roleType, super.key});

  final String roleType;

  @override
  ConsumerState<RoleApplicationPage> createState() =>
      _RoleApplicationPageState();
}

class _RoleApplicationPageState extends ConsumerState<RoleApplicationPage> {
  late String _activeRoleType = widget.roleType;

  @override
  void didUpdateWidget(covariant RoleApplicationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleType != widget.roleType) {
      _activeRoleType = widget.roleType;
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final ok = await ref
        .read(roleApplicationProvider(_activeRoleType).notifier)
        .submit();
    if (!mounted) return;
    if (!ok) {
      final why = ref.read(roleApplicationProvider(_activeRoleType)).error;
      showTopToast(
        context,
        why == null || why.isEmpty ? l10n.roleApplyFailed : why,
      );
      return;
    }
    showTopToast(context, l10n.roleApplySent);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(roleApplicationProvider(_activeRoleType));
    final controller =
        ref.read(roleApplicationProvider(_activeRoleType).notifier);
    final d = state.draft;
    final title = roleTitleFor(_activeRoleType);
    final isProviderFamily =
        _activeRoleType == 'providerFoxer' || _activeRoleType == 'organizer';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          title ?? l10n.roleApplyTitle,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (isProviderFamily) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  for (final tab in const [
                    ('providerFoxer', 'Provider Foxer'),
                    ('organizer', 'Event Coordinator'),
                  ])
                    Expanded(
                      child: InkWell(
                        borderRadius: AppRadius.brSm,
                        onTap: () => setState(() => _activeRoleType = tab.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeRoleType == tab.$1
                                ? AppColors.roleProvider
                                : Colors.transparent,
                            borderRadius: AppRadius.brSm,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab.$2,
                            style: AppTypography.label(
                              color: _activeRoleType == tab.$1
                                  ? AppColors.onAccent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _Card(
            title: l10n.roleApplyAbout,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.isVenue || d.isProvider)
                  _Field(
                    label: d.isVenue
                        ? l10n.roleApplyVenueName
                        : l10n.roleApplyBusiness,
                    value: d.businessName,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(businessName: v)),
                  ),
                if (d.isVenue) ...[
                  _Field(
                    label: l10n.roleApplyContact,
                    value: d.contactNumber,
                    phone: true,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(contactNumber: v)),
                  ),
                  _Field(
                    label: l10n.roleApplyAddress,
                    value: d.address,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(address: v)),
                  ),
                  _Field(
                    label: l10n.roleApplyDescription,
                    value: d.description,
                    lines: 3,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(description: v)),
                  ),
                ] else if (d.isEvent || d.isOrganizer) ...[
                  _Field(
                    label: l10n.roleApplyBio,
                    value: d.bio,
                    lines: 4,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(bio: v)),
                  ),
                  _Field(
                    label: l10n.onboardingCountry,
                    value: d.country,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(country: v)),
                  ),
                  _Field(
                    label: l10n.onboardingStateProvince,
                    value: d.state,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(state: v)),
                  ),
                  _Field(
                    label: l10n.onboardingCity,
                    value: d.city,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(city: v)),
                  ),
                  _Field(
                    label: l10n.roleApplyExperience,
                    value: d.experience,
                    number: true,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(experience: v)),
                  ),
                ] else
                  _Field(
                    label: switch (_activeRoleType) {
                      'providerFoxer' => l10n.roleApplyProviderTypes,
                      _ => l10n.roleApplyServiceTypes,
                    },
                    hint: l10n.roleApplyCommaHint,
                    value: d.types,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(types: v)),
                  ),
                if (d.isProvider)
                  _Field(
                    label: l10n.roleApplyExperience,
                    value: d.experience,
                    number: true,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(experience: v)),
                  ),
                if (d.isProvider || d.isEvent)
                  _Field(
                    label: l10n.roleApplyPortfolio,
                    hint: l10n.roleApplyPortfolioLinksHint,
                    value: d.portfolio,
                    url: true,
                    error: _portfolioError(l10n, d.portfolioProblem),
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(portfolio: v)),
                  ),
                if (d.isProvider)
                  _ProviderSpecializations(
                    picked: d.specializations,
                    onToggle: controller.toggleSpecialization,
                  )
                else
                  _Specializations(
                    options: [
                      for (final o in specializationOptions(widget.roleType))
                        (code: o, label: specializationLabel(l10n, o)),
                    ],
                    picked: d.specializations,
                    onToggle: controller.toggleSpecialization,
                    maxPicks: RoleApplicationDraft.maxSpecializationsFor(
                      widget.roleType,
                    ),
                  ),
              ],
            ),
          ),
          _Card(
            title: l10n.roleApplyIds,
            hint: l10n.roleApplyIdsHint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.isProvider)
                  _Field(
                    label: l10n.roleApplyNbiNumber,
                    value: d.nbiNumber,
                    number: true,
                    formatters: [LengthLimitingTextInputFormatter(18)],
                    onChanged: (v) => controller.edit(
                      (x) => x.copyWith(
                        nbiNumber: RoleApplicationDraft.digits(v, 18),
                      ),
                    ),
                  ),
                if (!d.isEvent && !d.isOrganizer)
                  _Field(
                    label: d.isVenue
                        ? l10n.roleApplyTinRequired
                        : l10n.roleApplyTin,
                    value: d.tinNumber,
                    number: true,
                    formatters: [LengthLimitingTextInputFormatter(9)],
                    onChanged: (v) => controller.edit(
                      (x) => x.copyWith(
                        tinNumber: RoleApplicationDraft.digits(v, 9),
                      ),
                    ),
                  ),
                for (final slot in d.requiredDocuments)
                  DocumentRow(
                    label: _documentLabel(l10n, slot),
                    photo: d.documents[slot],
                    frontCamera: slot == KycDocument.selfie,
                    onPicked: (p) => controller.setDocument(slot, p),
                    onRemove: () => controller.removeDocument(slot),
                  ),
                if (d.isEvent)
                  DocumentRow(
                    label: l10n.roleApplyPortfolioFile,
                    document: true,
                    photo: d.portfolioFile,
                    onPicked: (p) =>
                        controller.edit((x) => x.copyWith(portfolioFile: p)),
                    onRemove: () => controller
                        .edit((x) => x.copyWith(clearPortfolioFile: true)),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppButton(
              label: l10n.roleApplySubmit,
              isLoading: state.submitting,
              onPressed: d.isComplete ? _submit : null,
            ),
          ),
        ),
      ),
    );
  }
}

String _documentLabel(AppLocalizations l10n, KycDocument slot) =>
    switch (slot) {
      KycDocument.validId => l10n.roleApplyDocId,
      KycDocument.nbi => l10n.roleApplyDocNbi,
      KycDocument.tinId => l10n.roleApplyDocTin,
      KycDocument.birPermit => l10n.roleApplyDocBir,
      KycDocument.selfie => l10n.roleApplyDocSelfie,
      KycDocument.backgroundClearance => l10n.roleApplyDocClearance,
    };

String? _portfolioError(
  AppLocalizations l10n,
  PortfolioLinksProblem? problem,
) =>
    switch (problem) {
      null => null,
      PortfolioLinkInvalid(:final link) =>
        l10n.roleApplyPortfolioLinkInvalid(link),
      PortfolioLinksTooMany() =>
        l10n.roleApplyPortfolioTooMany(maxPortfolioLinks),
    };

String specializationLabel(AppLocalizations l10n, String code) =>
    switch (code) {
      'corporate' => l10n.roleSpecCorporate,
      'birthday' => l10n.roleSpecBirthday,
      'wedding' => l10n.roleSpecWedding,
      'social' => l10n.roleSpecSocial,
      'indoor' => l10n.roleSpecIndoor,
      'outdoor' => l10n.roleSpecOutdoor,
      'hotel' => l10n.roleSpecHotel,
      'beach_resort' => l10n.roleSpecBeachResort,
      'garden' => l10n.roleSpecGarden,
      'mix' => l10n.roleSpecMix,
      'design' => l10n.roleSpecDesign,
      'catering' => l10n.roleSpecCatering,
      'service_staff' => l10n.roleSpecStaff,
      'photography' => l10n.roleSpecPhotography,
      'videography' => l10n.roleSpecVideography,
      'dj' => l10n.roleSpecDj,
      'live_band' => l10n.roleSpecLiveBand,
      'mc' => l10n.roleSpecMc,
      'furnitures' => l10n.roleSpecFurniture,
      'sound_system' => l10n.roleSpecSound,
      'decorations' => l10n.roleSpecDecorations,
      _ => l10n.roleSpecOther,
    };

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.display()),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error,
    this.number = false,
    this.phone = false,
    this.url = false,
    this.lines = 1,
    this.formatters = const [],
  });

  final String label;
  final String? hint;

  /// Shown under the field in place of [hint]; the field then reads invalid.
  final String? error;
  final String value;
  final bool number;
  final bool phone;
  final bool url;
  final int lines;
  final List<TextInputFormatter> formatters;
  final ValueChanged<String> onChanged;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: _controller,
          inputFormatters: widget.formatters,
          keyboardType: widget.number
              ? TextInputType.number
              : widget.phone
                  ? TextInputType.phone
                  : widget.url
                      ? TextInputType.url
                      : null,
          minLines: widget.lines,
          maxLines: widget.lines,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.hint,
            helperMaxLines: 2,
            errorText: widget.error,
            errorMaxLines: 3,
          ),
          onChanged: widget.onChanged,
        ),
      );
}

class _Specializations extends StatelessWidget {
  const _Specializations({
    required this.options,
    required this.picked,
    required this.onToggle,
    this.maxPicks,
  });

  final List<({String code, String label})> options;
  final List<String> picked;
  final ValueChanged<String> onToggle;
  final int? maxPicks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final full = maxPicks != null && picked.length >= maxPicks!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          maxPicks == null
              ? l10n.roleApplySpecializationsProvider
              : l10n.roleApplySpecializationsOther,
          style: AppTypography.label(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o.label),
                selected: picked.contains(o.code),
                onSelected: full && !picked.contains(o.code)
                    ? null
                    : (_) => onToggle(o.code),
              ),
          ],
        ),
      ],
    );
  }
}

/// A Provider's specialties, read live from the catalog so the form offers
/// exactly what the API will accept.
class _ProviderSpecializations extends ConsumerWidget {
  const _ProviderSpecializations({
    required this.picked,
    required this.onToggle,
  });

  final List<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ref.watch(providerSpecialtiesProvider).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
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
          data: (list) => _Specializations(
            options: [for (final s in list) (code: s.slug, label: s.name)],
            picked: picked,
            onToggle: onToggle,
          ),
        );
  }
}
