import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/domain/experience.dart';
import 'package:flutter_template/features/roles/presentation/widgets/apply_wizard.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Years of experience with the over-30 claim (mobile#535), as the web's
/// form has it (app#441): whole years up to 30; a number over the limit is
/// refused as it's typed, which reveals "I have more than 30 years of
/// experience". Ticking it allows up to 50, shows the bracket the number
/// counts as, and asks for a CV with references, PDF only.
class ApplyYearsOfExperience extends StatefulWidget {
  const ApplyYearsOfExperience({
    required this.label,
    required this.experience,
    required this.claiming,
    required this.cv,
    required this.onExperienceChanged,
    required this.onClaimingChanged,
    required this.onCvPicked,
    required this.onCvRemoved,
    super.key,
  });

  final String label;
  final String experience;
  final bool claiming;

  /// The CV behind a claim, or null.
  final PickedPhoto? cv;
  final ValueChanged<String> onExperienceChanged;

  /// Ticking or unticking also drops the CV: an earlier portfolio may be a
  /// Word file, and an unticked claim has no CV.
  final ValueChanged<bool> onClaimingChanged;
  final ValueChanged<PickedPhoto> onCvPicked;
  final VoidCallback onCvRemoved;

  @override
  State<ApplyYearsOfExperience> createState() => _ApplyYearsOfExperienceState();
}

class _ApplyYearsOfExperienceState extends State<ApplyYearsOfExperience> {
  /// A number over the limit was refused; the claim box shows from then on.
  bool _refused = false;

  int get _max => yearsMax(claiming: widget.claiming);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = widget.experience.trim();
    final notWhole = value.isNotEmpty && wholeYears(value, _max) == null;
    final problem = experienceClaimProblem(
      experience: widget.experience,
      claiming: widget.claiming,
      cv: widget.cv,
    );
    final years = wholeYears(value, claimMaxYears);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApplyField(
          label: widget.label,
          child: TextFormField(
            key: const Key('years-of-experience'),
            initialValue: widget.experience,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxYearsFormatter(
                max: () => _max,
                onRefused: () {
                  if (!_refused) setState(() => _refused = true);
                },
              ),
            ],
            decoration: InputDecoration(
              errorText: notWhole ? l10n.expWholeYears(_max) : null,
              errorMaxLines: 2,
              helperText: _refused && !notWhole
                  ? widget.claiming
                      ? l10n.expMaxYearsClaim(claimMaxYears)
                      : l10n.expMaxYears(baseMaxYears)
                  : null,
              helperMaxLines: 3,
              helperStyle: AppTypography.body(
                size: 12,
                color: AppColors.warning,
              ),
            ),
            onChanged: widget.onExperienceChanged,
          ),
        ),
        if (_refused || widget.claiming) ...[
          CheckboxListTile(
            key: const Key('experience-claim'),
            value: widget.claiming,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              l10n.expClaimTitle(baseMaxYears),
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              l10n.expClaimHint(claimMaxYears),
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
            onChanged: (v) {
              widget.onCvRemoved();
              widget.onClaimingChanged(v ?? false);
            },
          ),
          if (widget.claiming) ...[
            if (years != null && years > baseMaxYears) ...[
              Text(
                l10n.expClaimBracket(
                  years,
                  bracketLabel(experienceBracket(years)),
                ),
                style: AppTypography.body(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.expClaimCvRules,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            DocumentRow(
              key: const Key('experience-cv'),
              boxed: true,
              document: true,
              label: l10n.expClaimCvLabel,
              photo: widget.cv,
              onPicked: widget.onCvPicked,
              onRemove: widget.onCvRemoved,
            ),
            if (switch (problem) {
              ExperienceClaimProblem.tooFewYears =>
                l10n.expClaimTooFew(baseMaxYears),
              ExperienceClaimProblem.cvNotPdf => l10n.expClaimCvPdf,
              ExperienceClaimProblem.cvMissing || null => null,
            }
                case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message,
                  style: AppTypography.body(size: 12, color: AppColors.error),
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Refuses a digit edit that goes over the limit, as the web does, and says
/// so through [onRefused].
class _MaxYearsFormatter extends TextInputFormatter {
  _MaxYearsFormatter({required this.max, required this.onRefused});

  final int Function() max;
  final VoidCallback onRefused;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!exceedsMaxYears(newValue.text, max())) return newValue;
    onRefused();
    return oldValue;
  }
}

/// Years as the review shows them: "6 years", or "40+ (CV attached)" for a
/// claim of more than 30.
String experienceReviewLabel(
  AppLocalizations l10n,
  int years, {
  required bool claiming,
}) =>
    claiming && years > baseMaxYears
        ? l10n.expClaimReview(bracketLabel(experienceBracket(years)))
        : l10n.provApplyYearsCount(years);
