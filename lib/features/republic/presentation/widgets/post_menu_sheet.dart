import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// What the ⋯ menu of a post offers.
enum PostMenuAction { copyLink, save, edit, delete, hide, report, block }

/// The post's menu. Your own post can be edited or deleted; someone else's can
/// be hidden or reported. Resolves what was chosen, or null.
Future<PostMenuAction?> showPostMenu(
  BuildContext context, {
  required bool isOwner,
  required bool saved,
  required bool canCopyLink,
  required String authorName,
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
          row(
            Icons.block_rounded,
            l10n.republicMenuBlock(authorName),
            PostMenuAction.block,
            danger: true,
          ),
        ],
        const SizedBox(height: 8),
      ],
    ),
  );
}
