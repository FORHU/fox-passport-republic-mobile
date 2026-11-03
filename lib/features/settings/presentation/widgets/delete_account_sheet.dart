import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Asks for the password and the word DELETE, then removes the account. On
/// success the session ends and the app goes back to the start by itself.
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || !(_form.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    setState(() => _deleting = true);
    final error = await ref
        .read(profileControllerProvider.notifier)
        .deleteAccount(_password.text);
    if (!mounted) return;
    if (error == null) {
      navigator.pop();
      return;
    }
    setState(() => _deleting = false);
    showTopToast(context, error.isEmpty ? l10n.deleteAccountFailed : error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.deleteAccountTitle,
                style: AppTypography.display(size: 18, color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(l10n.deleteAccountBody, style: AppTypography.body(size: 13)),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.deleteAccountPassword,
                controller: _password,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) =>
                    (v ?? '').isEmpty ? l10n.deleteAccountPassword : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.deleteAccountType,
                controller: _confirmation,
                prefixIcon: Icons.warning_amber_rounded,
                validator: (v) => (v ?? '').trim() == 'DELETE'
                    ? null
                    : l10n.deleteAccountMismatch,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _deleting ? null : _delete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.brPill,
                    ),
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.canvas,
                          ),
                        )
                      : Text(
                          l10n.deleteAccountAction,
                          style: AppTypography.display(
                            color: AppColors.canvas,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
