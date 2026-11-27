import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// "Withdraw your … application?" before an applicant takes back a role
/// application still under review (api#367). True when they confirm.
Future<bool> confirmWithdrawRole(BuildContext context, String roleTitle) async {
  final l10n = context.l10n;
  final sure = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.rolesWithdrawTitle(roleTitle)),
      content: Text(l10n.rolesWithdrawBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.rolesWithdrawKeep),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l10n.rolesWithdraw),
        ),
      ],
    ),
  );
  return sure ?? false;
}
