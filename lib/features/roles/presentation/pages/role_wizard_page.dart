import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_application_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/role_application_page.dart'
    show specializationLabel;
import 'package:flutter_template/features/roles/presentation/widgets/apply_wizard.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

enum _Step { intro, about, categories, documents, review, sent }

/// Applying as a Venue Foxer, Event Foxer or Event Coordinator, in the same
/// step-by-step layout as the Provider wizard (mobile#487): about you or your
/// business, categories, documents; then review and send.
class RoleWizardPage extends ConsumerStatefulWidget {
  const RoleWizardPage({required this.roleType, super.key});

  /// `venueFoxer`, `eventFoxer` or `organizer`.
  final String roleType;

  @override
  ConsumerState<RoleWizardPage> createState() => _RoleWizardPageState();
}

class _RoleWizardPageState extends ConsumerState<RoleWizardPage> {
  _Step _step = _Step.intro;
  bool _agreed = false;
  DateTime? _sentAt;

  String get _role => widget.roleType;
  bool get _isVenue => _role == 'venueFoxer';
  bool get _isEvent => _role == 'eventFoxer';
  bool get _isCoordinator => _role == 'organizer';

  RoleApplicationController get _controller =>
      ref.read(roleApplicationProvider(_role).notifier);

  void _go(_Step step) => setState(() => _step = step);

  void _back() {
    if (_step == _Step.intro || _step == _Step.sent) {
      _leave();
    } else {
      _go(_Step.values[_step.index - 1]);
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.roles);
    }
  }

  Future<void> _submit() async {
    final ok = await _controller.submit();
    if (!mounted || !ok) return;
    setState(() {
      _sentAt = DateTime.now();
      _step = _Step.sent;
    });
  }

  bool _aboutDone(RoleApplicationState state) {
    final d = state.draft;
    if (_isVenue) {
      return d.businessName.trim().isNotEmpty &&
          d.contactNumber.trim().isNotEmpty &&
          d.address.trim().isNotEmpty &&
          state.tinFits;
    }
    final placed = d.bio.trim().isNotEmpty &&
        d.city.trim().isNotEmpty &&
        d.country.trim().isNotEmpty;
    if (_isCoordinator) return placed && d.years != null;
    return placed &&
        d.portfolioProblem == null &&
        (d.experience.trim().isEmpty || d.years != null);
  }

  @override
  Widget build(BuildContext context) {
    final leaves = _step == _Step.intro || _step == _Step.sent;
    return PopScope(
      canPop: leaves,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: switch (_step) {
            _Step.intro => _intro(context),
            _Step.about => _about(context),
            _Step.categories => _categories(context),
            _Step.documents => _documents(context),
            _Step.review => _review(context),
            _Step.sent => _sent(context),
          },
        ),
      ),
    );
  }

  Widget _header(int number) =>
      ApplyStepHeader(number: number, total: 3, onBack: _back);

  // ------------------------------------------------------------- intro

  Widget _intro(BuildContext context) {
    final l10n = context.l10n;
    final docsHint = _isCoordinator
        ? l10n.roleWizCoordDocsHint
        : _isEvent
            ? l10n.roleWizEventDocsHint
            : l10n.provApplyStepDocumentsHint;
    return ApplyIntro(
      top: _isCoordinator ? const ApplyRoleSwitch(current: 'organizer') : null,
      // Event coordination is applied for from the Provider Foxer path
      // (mobile#526), so its intro keeps the Provider Foxer eyebrow.
      eyebrow:
          _isCoordinator ? l10n.provApplyEyebrow : roleTitleFor(_role) ?? '',
      eyebrowColor: _isVenue
          ? AppColors.roleVenue
          : _isEvent
              ? AppColors.roleEvent
              : AppColors.roleProvider,
      title: _isVenue
          ? l10n.roleWizVenueIntroTitle
          : _isEvent
              ? l10n.roleWizEventIntroTitle
              : l10n.roleWizCoordIntroTitle,
      body: _isVenue
          ? l10n.roleWizVenueIntroBody
          : _isEvent
              ? l10n.roleWizEventIntroBody
              : l10n.roleWizCoordIntroBody,
      steps: [
        if (_isVenue)
          (l10n.provApplyStepBusiness, l10n.roleWizVenueAboutHint)
        else
          (l10n.roleWizStepAboutYou, l10n.roleWizAboutYouHint),
        (
          l10n.provApplyStepCategories,
          _isVenue
              ? l10n.roleWizVenueCategoriesHint
              : _isEvent
                  ? l10n.roleWizEventCategoriesHint
                  : l10n.roleWizCoordCategoriesHint,
        ),
        (l10n.provApplyStepDocuments, docsHint),
      ],
      duration: l10n.roleWizDuration,
      onClose: _leave,
      onStart: () => _go(_Step.about),
    );
  }

  // ------------------------------------------------------------- step 1

  Widget _about(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(roleApplicationProvider(_role));
    final d = state.draft;
    final c = _controller;
    final yearsBad = d.experience.trim().isNotEmpty && d.years == null;

    Widget text(
      String label,
      String value,
      ValueChanged<String> onChanged, {
      String? help,
      int lines = 1,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? error,
      Key? key,
      Widget? suffix,
      String? note,
      String? prefix,
    }) =>
        ApplyField(
          label: label,
          help: help,
          child: TextFormField(
            key: key,
            initialValue: value,
            minLines: lines,
            maxLines: lines == 1 ? 1 : lines + 2,
            keyboardType: keyboard,
            inputFormatters: formatters,
            textCapitalization: lines > 1
                ? TextCapitalization.sentences
                : TextCapitalization.words,
            decoration: InputDecoration(
              errorText: error,
              errorMaxLines: 2,
              prefixText: prefix,
              suffixIcon: suffix,
              helperText: note,
              helperMaxLines: 3,
              helperStyle: AppTypography.body(
                size: 12,
                color: AppColors.warning,
              ),
            ),
            onChanged: onChanged,
          ),
        );

    final children = <Widget>[
      ApplyTitle(
        _isVenue ? l10n.provApplyStepBusiness : l10n.roleWizStepAboutYou,
      ),
      if (_isVenue) ...[
        text(
          l10n.roleApplyVenueName,
          d.businessName,
          (v) => c.edit((x) => x.copyWith(businessName: v)),
        ),
        // One country, before the fields that follow it, as the web has it
        // (app#330): the contact number takes its calling code (mobile#537)
        // and the tax number its formats (mobile#529).
        if (state.taxCountries.isNotEmpty)
          ApplyField(
            label: l10n.onboardingCountry,
            help: l10n.roleApplyCountryHelp,
            child: DropdownButtonFormField<String>(
              key: const Key('tax-country'),
              initialValue:
                  state.taxCountries.any((x) => x.code == d.tinCountry)
                      ? d.tinCountry
                      : null,
              isExpanded: true,
              items: [
                for (final country in state.taxCountries)
                  DropdownMenuItem(
                    value: country.code,
                    child: Text(country.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (code) {
                if (code != null) unawaited(c.setTinCountry(code));
              },
            ),
          ),
        text(
          l10n.roleApplyContact,
          d.contactNumber,
          (v) => c.edit((x) => x.copyWith(contactNumber: v)),
          key: const Key('contact-number'),
          keyboard: TextInputType.phone,
          prefix: d.phoneCode.isEmpty || d.contactNumber.trim().startsWith('+')
              ? null
              : '+${d.phoneCode} ',
        ),
        text(
          l10n.roleApplyAddress,
          d.address,
          (v) => c.edit((x) => x.copyWith(address: v)),
        ),
        text(
          l10n.roleApplyDescription,
          d.description,
          (v) => c.edit((x) => x.copyWith(description: v)),
          lines: 3,
        ),
        text(
          switch (state.tinFormats?.label) {
            final name? when name.isNotEmpty => l10n.roleApplyTaxIdNamed(name),
            _ => l10n.roleApplyTaxId,
          },
          d.tinNumber,
          (v) => c.edit((x) => x.copyWith(tinNumber: v)),
          key: const Key('tax-id'),
          formatters: [LengthLimitingTextInputFormatter(32)],
          help: switch (state.tinFormats?.example) {
            final example? when example.isNotEmpty =>
              l10n.roleApplyTaxIdExample(example),
            _ => null,
          },
          error: d.tinNumber.trim().isNotEmpty && !state.tinFits
              ? switch (state.tinFormats?.example) {
                  final example? when example.isNotEmpty =>
                    l10n.roleApplyTaxIdInvalid(example),
                  _ => l10n.roleApplyTaxIdInvalidAny,
                }
              : null,
        ),
      ] else ...[
        text(
          l10n.roleApplyBio,
          d.bio,
          (v) => c.edit((x) => x.copyWith(bio: v)),
          lines: 4,
        ),
        text(
          l10n.onboardingCity,
          d.city,
          (v) => c.edit((x) => x.copyWith(city: v)),
          key: ValueKey('city-${state.locatedCount}'),
          note: switch (state.locateProblem) {
            LocateOutcome.denied => l10n.areaLocationDenied,
            LocateOutcome.serviceOff => l10n.areaLocationOff,
            LocateOutcome.failed => l10n.provApplyLocateFailed,
            _ => null,
          },
          suffix: state.locating
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
        text(
          l10n.onboardingStateProvince,
          d.state,
          (v) => c.edit((x) => x.copyWith(state: v)),
          key: ValueKey('state-${state.locatedCount}'),
        ),
        text(
          l10n.onboardingCountry,
          d.country,
          (v) => c.edit((x) => x.copyWith(country: v)),
        ),
        text(
          _isCoordinator ? l10n.provApplyYears : l10n.roleWizYearsOptional,
          d.experience,
          (v) => c.edit((x) => x.copyWith(experience: v)),
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          error: yearsBad ? l10n.provApplyYearsInvalid : null,
        ),
        if (_isEvent)
          text(
            l10n.provApplyLinks,
            d.portfolio,
            (v) => c.edit((x) => x.copyWith(portfolio: v)),
            keyboard: TextInputType.url,
            help: d.portfolioProblem == null
                ? l10n.roleApplyPortfolioLinksHint
                : null,
            error: switch (d.portfolioProblem) {
              PortfolioLinkInvalid(:final link) =>
                l10n.roleApplyPortfolioLinkInvalid(link),
              PortfolioLinksTooMany() =>
                l10n.roleApplyPortfolioTooMany(maxPortfolioLinks),
              null => null,
            },
          ),
      ],
    ];

    return ApplyScreen(
      header: _header(1),
      footerBorder: false,
      footer: [
        AppButton(
          label: l10n.provApplyNextCategories,
          onPressed: _aboutDone(state) ? () => _go(_Step.categories) : null,
        ),
      ],
      children: children,
    );
  }

  // ------------------------------------------------------------- step 2

  Widget _categories(BuildContext context) {
    final l10n = context.l10n;
    final d = ref.watch(roleApplicationProvider(_role)).draft;
    const max = RoleApplicationDraft.maxSpecializations;
    final picked = d.specializations;
    return ApplyScreen(
      header: _header(2),
      footer: [
        Text(
          picked.isEmpty
              ? l10n.provApplyNothingPicked
              : l10n.roleWizPickedOf(picked.length, max),
          style: AppTypography.body(size: 13),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: picked.isEmpty
              ? l10n.provApplyPickOne
              : l10n.provApplyNextDocuments,
          onPressed: picked.isEmpty ? null : () => _go(_Step.documents),
        ),
      ],
      children: [
        ApplyTitle(
          _isVenue
              ? l10n.roleWizVenueCategoriesTitle
              : _isEvent
                  ? l10n.roleWizEventCategoriesTitle
                  : l10n.roleWizCoordCategoriesTitle,
          l10n.roleWizCategoriesBody(max),
        ),
        ApplyCategoryGrid(
          cards: [
            for (final code in specializationOptions(_role))
              ApplyCategoryCard(
                name: specializationLabel(l10n, code),
                picked: picked.contains(code),
                onTap: () => _controller.toggleSpecialization(code),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step 3

  Widget _documents(BuildContext context) {
    final l10n = context.l10n;
    final d = ref.watch(roleApplicationProvider(_role)).draft;
    final c = _controller;
    final missing =
        d.requiredDocuments.where((x) => !d.documents.containsKey(x)).length;
    return ApplyScreen(
      header: _header(3),
      footer: [
        if (missing > 0) ...[
          Text(
            l10n.provApplyDocsLeft(missing),
            style: AppTypography.body(size: 13, color: AppColors.warning),
          ),
          const SizedBox(height: 8),
        ],
        AppButton(
          label: l10n.provApplyReviewButton,
          onPressed: missing == 0 ? () => _go(_Step.review) : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyDocumentsTitle, l10n.provApplyDocumentsBody),
        for (final doc in d.askedDocuments)
          DocumentRow(
            boxed: true,
            optional: !d.requiredDocuments.contains(doc),
            label: applyDocumentLabel(l10n, doc),
            note: applyDocumentNote(l10n, doc),
            photo: d.documents[doc],
            frontCamera: doc == KycDocument.selfie,
            onPicked: (p) => c.setDocument(doc, p),
            onRemove: () => c.removeDocument(doc),
          ),
        if (_isEvent)
          DocumentRow(
            boxed: true,
            optional: true,
            document: true,
            label: l10n.roleWizPortfolioFile,
            photo: d.portfolioFile,
            onPicked: (p) => c.edit((x) => x.copyWith(portfolioFile: p)),
            onRemove: () => c.edit((x) => x.copyWith(clearPortfolioFile: true)),
          ),
      ],
    );
  }

  // ------------------------------------------------------------- review

  Widget _review(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(roleApplicationProvider(_role));
    final d = state.draft;
    final years = d.years;
    final error = state.error;
    final aboutLine = _isVenue
        ? [d.contactNumber.trim(), d.address.trim()].join(' · ')
        : [
            d.location,
            if (years != null) l10n.provApplyYearsCount(years),
          ].join(' · ');
    return ApplyScreen(
      header: ApplyTitleHeader(title: l10n.provApplyReview, onBack: _back),
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
          onPressed: d.isComplete && _agreed && d.specializations.isNotEmpty
              ? _submit
              : null,
        ),
      ],
      children: [
        ApplyTitle(l10n.provApplyCheckAndSend),
        ApplyReviewSection(
          title: _isVenue
              ? l10n.provApplyBusinessSection
              : l10n.roleWizAboutSection,
          onEdit: () => _go(_Step.about),
          children: [
            Text(
              _isVenue ? d.businessName.trim() : d.bio.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(size: 15, color: AppColors.textPrimary),
            ),
            if (aboutLine.isNotEmpty)
              Text(aboutLine, style: AppTypography.body(size: 13)),
          ],
        ),
        ApplyReviewSection(
          title: l10n.provApplyCategoriesSection,
          onEdit: () => _go(_Step.categories),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in d.specializations)
                  ApplyTag(label: specializationLabel(l10n, code)),
              ],
            ),
          ],
        ),
        ApplyReviewSection(
          title: l10n.provApplyDocumentsSection,
          onEdit: () => _go(_Step.documents),
          children: [
            ApplyAllDocuments(
              count: d.askedDocuments.where(d.documents.containsKey).length,
            ),
          ],
        ),
        ApplyAgreement(
          agreed: _agreed,
          onChanged: (v) => setState(() => _agreed = v),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- sent

  Widget _sent(BuildContext context) {
    final l10n = context.l10n;
    final d = ref.watch(roleApplicationProvider(_role)).draft;
    return ApplySent(
      sentAt: _sentAt ?? DateTime.now(),
      tags: [
        for (final code in d.specializations) specializationLabel(l10n, code),
      ],
      onDone: _leave,
    );
  }
}
