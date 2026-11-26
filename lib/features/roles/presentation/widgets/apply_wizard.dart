import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The pieces every role application wizard is built from (mobile#487), so
/// Provider, Venue, Event and Event Coordinator look the same: the "Become a
/// Provider" designs.

/// A screen: optional header, scrolling content, a footer pinned below.
class ApplyScreen extends StatelessWidget {
  const ApplyScreen({
    required this.children,
    required this.footer,
    this.header,
    this.footerBorder = true,
    super.key,
  });

  final Widget? header;
  final List<Widget> children;
  final List<Widget> footer;
  final bool footerBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (header != null) header!,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            children: children,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: footerBorder
                ? const Border(top: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: footer,
            ),
          ),
        ),
      ],
    );
  }
}

/// Back, "STEP n OF total" and the progress bars.
class ApplyStepHeader extends StatelessWidget {
  const ApplyStepHeader({
    required this.number,
    required this.total,
    required this.onBack,
    super.key,
  });

  final int number;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.provApplyBack,
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded, size: 26),
                color: AppColors.textPrimary,
              ),
              Text(
                l10n.provApplyStepOf(number, total).toUpperCase(),
                style: AppTypography.label(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 1; i <= total; i++) ...[
                    if (i > 1) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= number
                              ? AppColors.textPrimary
                              : AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back and a plain title, for the review screen.
class ApplyTitleHeader extends StatelessWidget {
  const ApplyTitleHeader({
    required this.title,
    required this.onBack,
    super.key,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.provApplyBack,
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded, size: 26),
            color: AppColors.textPrimary,
          ),
          Text(title, style: AppTypography.display(size: 17)),
        ],
      ),
    );
  }
}

class ApplyTitle extends StatelessWidget {
  const ApplyTitle(this.title, [this.body]) : super(key: null);

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.display(size: 22)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, style: AppTypography.body().copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

BoxDecoration applyCard({bool strong = false, bool raised = false}) =>
    BoxDecoration(
      color: raised ? AppColors.surfaceRaised : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(
        color: strong ? AppColors.textPrimary : AppColors.border,
      ),
    );

Widget applyEyebrow(String text, {Color color = AppColors.textMuted}) =>
    Text(text.toUpperCase(), style: AppTypography.label(color: color));

/// A label above its field, as the designs place it.
class ApplyField extends StatelessWidget {
  const ApplyField({
    required this.label,
    required this.child,
    this.help,
    super.key,
  });

  final String label;
  final Widget child;
  final String? help;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.body(size: 13)),
          const SizedBox(height: 6),
          child,
          if (help != null) ...[
            const SizedBox(height: 6),
            Text(
              help!,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The two Provider-family roles side by side, as in the role catalog
/// (mobile#488): switching opens the other one's application.
class ApplyRoleSwitch extends StatelessWidget {
  const ApplyRoleSwitch({required this.current, super.key});

  final String current;

  static const roles = ['providerFoxer', 'organizer'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final role in roles)
            Expanded(
              child: Semantics(
                button: true,
                selected: role == current,
                child: InkWell(
                  borderRadius: AppRadius.brSm,
                  onTap: role == current
                      ? null
                      : () => context.pushReplacement(
                            RouteNames.roleApply(role),
                          ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: role == current
                          ? AppColors.roleProvider
                          : AppColors.clear,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      roleTitleFor(role) ?? role,
                      style: AppTypography.label(
                        color: role == current
                            ? AppColors.onAccent
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The first screen: what the role is and the steps ahead.
class ApplyIntro extends StatelessWidget {
  const ApplyIntro({
    required this.eyebrow,
    required this.eyebrowColor,
    required this.title,
    required this.body,
    required this.steps,
    required this.duration,
    required this.onClose,
    required this.onStart,
    this.top,
    super.key,
  });

  final String eyebrow;
  final Color eyebrowColor;
  final String title;
  final String body;

  /// Each step's name and what it asks for.
  final List<(String, String)> steps;
  final String duration;
  final VoidCallback onClose;
  final VoidCallback onStart;

  /// Shown above the eyebrow, such as the Provider / Event Coordinator switch.
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ApplyScreen(
      footerBorder: false,
      header: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: IconButton(
            tooltip: l10n.provApplyClose,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textPrimary,
          ),
        ),
      ),
      footer: [AppButton(label: l10n.provApplyStart, onPressed: onStart)],
      children: [
        if (top != null) ...[top!, const SizedBox(height: 20)],
        applyEyebrow(eyebrow, color: eyebrowColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.display(size: 24).copyWith(height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(body, style: AppTypography.body().copyWith(height: 1.6)),
        const SizedBox(height: 20),
        for (final (i, s) in steps.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: applyCard().copyWith(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppTypography.label(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: AppTypography.body(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.$2,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Text(
          duration,
          style: AppTypography.body(size: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class ApplyPill extends StatelessWidget {
  const ApplyPill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.clear,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.textPrimary : AppColors.borderStrong,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.body(
                size: 13,
                color: selected
                    ? AppColors.onLightSurface
                    : AppColors.textSecondary,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A category: tap to pick or drop it. With [onMakeMain], a picked one shows
/// the star that makes it the main one.
class ApplyCategoryCard extends StatelessWidget {
  const ApplyCategoryCard({
    required this.name,
    required this.picked,
    required this.onTap,
    this.isMain = false,
    this.onMakeMain,
    super.key,
  });

  final String name;
  final bool picked;
  final bool isMain;
  final VoidCallback onTap;
  final VoidCallback? onMakeMain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = BorderRadius.circular(AppRadius.md);
    final makeMain = onMakeMain;
    return Material(
      color: picked ? AppColors.surfaceRaised : AppColors.clear,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: picked ? AppColors.textPrimary : AppColors.borderStrong,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              selected: picked,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 62),
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.body(
                          color: AppColors.textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (picked) ...[
                        const SizedBox(height: 4),
                        Text(
                          isMain ? l10n.provApplyMain : l10n.provApplyPicked,
                          style: isMain
                              ? AppTypography.label(color: AppColors.accent)
                              : AppTypography.body(
                                  size: 12,
                                  color: AppColors.textMuted,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (picked && makeMain != null)
            IconButton(
              tooltip: isMain
                  ? l10n.provApplyIsMain(name)
                  : l10n.provApplyMakeMain(name),
              isSelected: isMain,
              onPressed: makeMain,
              icon: Icon(
                isMain ? Icons.star_rounded : Icons.star_border_rounded,
                color: isMain ? AppColors.accent : AppColors.textSecondary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

/// Category cards two to a row.
class ApplyCategoryGrid extends StatelessWidget {
  const ApplyCategoryGrid({required this.cards, super.key});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class ApplyReviewSection extends StatelessWidget {
  const ApplyReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
    super.key,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 16),
      decoration: applyCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: applyEyebrow(title)),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(44, 44),
                  textStyle: AppTypography.body(size: 13).copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
                child: Semantics(
                  label: '${l10n.provApplyEdit} $title',
                  excludeSemantics: true,
                  child: Text(l10n.provApplyEdit),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, w) in children.indexed) ...[
                  if (i > 0) const SizedBox(height: 10),
                  w,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "N documents added" with a check, for the review screen. Optional ones
/// may be left out, so it counts what was added (mobile#529).
class ApplyAllDocuments extends StatelessWidget {
  const ApplyAllDocuments({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
        const SizedBox(width: 8),
        Text(
          context.l10n.provApplyAllDocs(count),
          style: AppTypography.body(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// The terms box and the note under it, for the review screen.
class ApplyAgreement extends StatelessWidget {
  const ApplyAgreement({
    required this.agreed,
    required this.onChanged,
    super.key,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        CheckboxListTile(
          value: agreed,
          onChanged: (v) => onChanged(v ?? false),
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

class ApplyTag extends StatelessWidget {
  const ApplyTag({required this.label, this.main, super.key});

  final String label;

  /// "MAIN" on the main one.
  final String? main;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color:
                main != null ? AppColors.textPrimary : AppColors.borderStrong,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.body(size: 13, color: AppColors.textPrimary),
          ),
          if (main != null) ...[
            const SizedBox(width: 6),
            Text(main!, style: AppTypography.label(color: AppColors.accent)),
          ],
        ],
      ),
    );
  }
}

/// After sending: the timeline and what is under review.
class ApplySent extends StatelessWidget {
  const ApplySent({
    required this.sentAt,
    required this.tags,
    required this.onDone,
    super.key,
  });

  final DateTime sentAt;

  /// The categories sent, as their names.
  final List<String> tags;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = TimeOfDay.fromDateTime(sentAt).format(context);
    final steps = [
      (l10n.provApplySentStep1, l10n.provApplySentToday(time), _Dot.done),
      (l10n.provApplySentStep2, l10n.provApplyInProgress, _Dot.current),
      (l10n.provApplySentStep3, l10n.provApplySentStep3Hint, _Dot.next),
    ];
    return ApplyScreen(
      footerBorder: false,
      footer: [AppButton(label: l10n.provApplyDone, onPressed: onDone)],
      children: [
        const SizedBox(height: 44),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.warning),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.warning,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(l10n.provApplySentTitle, style: AppTypography.display(size: 22)),
        const SizedBox(height: 18),
        Text(
          l10n.provApplySentBody,
          style: AppTypography.body().copyWith(height: 1.6),
        ),
        const SizedBox(height: 26),
        for (final (title, sub, dot) in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dot == _Dot.done ? AppColors.textPrimary : null,
                    border: dot == _Dot.done
                        ? null
                        : Border.all(
                            color: dot == _Dot.current
                                ? AppColors.warning
                                : AppColors.borderStrong,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (tags.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: applyCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                applyEyebrow(l10n.provApplyUnderReview),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final t in tags) ApplyTag(label: t)],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _Dot { done, current, next }

/// What each document is called in the wizards.
String applyDocumentLabel(AppLocalizations l10n, KycDocument doc) =>
    switch (doc) {
      KycDocument.validId => l10n.provApplyDocId,
      KycDocument.nbi => l10n.provApplyDocNbi,
      KycDocument.tinId => l10n.provApplyDocTin,
      KycDocument.birPermit => l10n.provApplyDocBir,
      KycDocument.selfie => l10n.provApplyDocSelfie,
      KycDocument.backgroundClearance => l10n.roleApplyDocClearance,
    };

/// A line under a document saying which papers count for it, or null.
String? applyDocumentNote(AppLocalizations l10n, KycDocument doc) =>
    doc == KycDocument.tinId ? l10n.kycDocTaxNote : null;
