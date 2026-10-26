import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// What the ⋯ menu of a post offers.
enum PostMenuAction { copyLink, save, edit, delete, hide, report }

/// The post's menu. Your own post can be edited or deleted; someone else's can
/// be hidden or reported. Resolves what was chosen, or null.
Future<PostMenuAction?> showPostMenu(
  BuildContext context, {
  required bool isOwner,
  required bool saved,
  required bool canCopyLink,
}) {
  final l10n = context.l10n;
  Widget row(
    IconData icon,
    String label,
    PostMenuAction action, {
    bool danger = false,
  }) =>
      ListTile(
        leading: Icon(icon, color: danger ? AppColors.error : null),
        title: Text(
          label,
          style: danger ? const TextStyle(color: AppColors.error) : null,
        ),
        onTap: () => Navigator.pop(context, action),
      );

  return showModalBottomSheet<PostMenuAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canCopyLink)
          row(
            Icons.link_rounded,
            l10n.republicMenuCopyLink,
            PostMenuAction.copyLink,
          ),
        row(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          saved ? l10n.republicMenuUnsave : l10n.republicMenuSave,
          PostMenuAction.save,
        ),
        if (isOwner) ...[
          row(Icons.edit_outlined, l10n.republicMenuEdit, PostMenuAction.edit),
          row(
            Icons.delete_outline_rounded,
            l10n.republicMenuDelete,
            PostMenuAction.delete,
            danger: true,
          ),
        ] else ...[
          row(
            Icons.visibility_off_outlined,
            l10n.republicMenuHide,
            PostMenuAction.hide,
          ),
          row(
            Icons.flag_outlined,
            l10n.republicMenuReport,
            PostMenuAction.report,
            danger: true,
          ),
        ],
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// Why someone is reporting a post. Resolves the reason, or null.
Future<String?> showReportSheet(BuildContext context) {
  final l10n = context.l10n;
  final reasons = [
    l10n.republicReasonSpam,
    l10n.republicReasonHarassment,
    l10n.republicReasonHate,
    l10n.republicReasonNudity,
    l10n.republicReasonViolence,
    l10n.republicReasonMisinfo,
    l10n.republicReasonOther,
  ];
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.republicReportTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final r in reasons)
              ListTile(
                title: Text(r),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    ),
  );
}
