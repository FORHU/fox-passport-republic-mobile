import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Asks before signing out, and says so when it did not work. A failed
/// sign-out keeps the user signed in, so staying silent would look like a
/// button that does nothing.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final sure = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.signOutConfirmTitle),
      content: Text(l10n.signOutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.signOutStay),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(
            l10n.settingsSignOut,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;

  final done = await ref.read(authControllerProvider.notifier).logout();
  if (!done && context.mounted) showTopToast(context, l10n.signOutFailed);
}
