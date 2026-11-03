import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_resubmit_controller.dart';
import 'package:flutter_template/features/roles/presentation/widgets/document_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/roles/role_request.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// What an admin asked an applicant to fix: the documents they flagged and
/// the reviewer's note. Only those are sent again; the rest of the application
/// stands as it was.
class RoleResubmitPage extends ConsumerWidget {
  const RoleResubmitPage({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(myRoleRequestsProvider);

    Widget body;
    if (requests.isLoading && !requests.hasValue) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    } else {
      final request =
          requests.asData?.value.where((r) => r.id == requestId).firstOrNull;
      body = request == null || !request.needsRevision
          ? _NothingToFix(
              onBack: () => context.canPop() ? context.pop() : null,
            )
          : _ResubmitForm(request: request);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          l10n.roleResubmitHeading,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: body,
    );
  }
}

class _NothingToFix extends StatelessWidget {
  const _NothingToFix({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.roleResubmitNothing,
              textAlign: TextAlign.center,
              style: AppTypography.display(size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.roleResubmitNothingBody,
              textAlign: TextAlign.center,
              style: AppTypography.body(),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onBack,
              child: Text(l10n.roleResubmitBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResubmitForm extends ConsumerWidget {
  const _ResubmitForm({required this.request});

  final RoleRequestSummary request;

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await ref.read(roleResubmitProvider(request).notifier).submit();
    if (!context.mounted) return;
    if (!ok) {
      final why = ref.read(roleResubmitProvider(request)).error;
      showTopToast(
        context,
        why == null || why.isEmpty ? l10n.roleApplyFailed : why,
      );
      return;
    }
    showTopToast(context, l10n.roleResubmitSent);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(roleResubmitProvider(request));
    final controller = ref.read(roleResubmitProvider(request).notifier);
    final role = roleCatalog
            .where((r) => r.roleType == request.roleType)
            .map((r) => r.title)
            .firstOrNull ??
        request.roleType;
    final note = request.revisionNote;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                l10n.roleResubmitTitle(role),
                style: AppTypography.display(size: 22),
              ),
              const SizedBox(height: 8),
              Text(l10n.roleResubmitIntro, style: AppTypography.body()),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.brCard,
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.roleResubmitNote.toUpperCase(),
                        style: AppTypography.label(color: AppColors.warning),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: AppTypography.body(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              for (final field in request.flaggedDocuments)
                DocumentRow(
                  label: resubmitDocumentLabel(l10n, field),
                  photo: state.files[field],
                  onPicked: (p) => controller.setFile(field, p),
                  onRemove: () => controller.removeFile(field),
                ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: AppButton(
                label: l10n.roleResubmitSend,
                isLoading: state.submitting,
                onPressed:
                    controller.complete ? () => _send(context, ref) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The name of a flagged document, by the name the API gives it.
String resubmitDocumentLabel(AppLocalizations l10n, String field) =>
    switch (field) {
      'validId1' => l10n.roleApplyDocId,
      'nbiFile' => l10n.roleApplyDocNbi,
      'tinIdFile' => l10n.roleApplyDocTin,
      'birPermitFile' => l10n.roleApplyDocBir,
      'selfieFile' => l10n.roleApplyDocSelfie,
      'backgroundClearanceFile' => l10n.roleApplyDocClearance,
      'portfolioFile' => l10n.roleApplyPortfolioFile,
      _ => field,
    };
