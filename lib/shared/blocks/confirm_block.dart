import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/blocks/data/blocks_repository.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Asks whether to block [name] and, if the person agrees, blocks them.
/// Resolves to true when they are blocked. Says why when the API refuses,
/// e.g. while the two of you have a booking together.
Future<bool> confirmBlock(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
}) async {
  final l10n = context.l10n;
  final sure = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.blockTitle(name)),
      content: Text(l10n.blockBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.republicCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.blockConfirm,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return false;

  try {
    await ref.read(blocksRepositoryProvider).block(userId);
    ref.invalidate(blockedUsersProvider);
    if (context.mounted) showTopToast(context, l10n.blockDone(name));
    return true;
  } on Object catch (e) {
    if (context.mounted) {
      showTopToast(
        context,
        e is AppException ? e.message : l10n.blockFailed,
      );
    }
    return false;
  }
}
