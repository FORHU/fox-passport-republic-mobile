import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Change the password: the current one, then a new one twice.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    final error =
        await ref.read(profileControllerProvider.notifier).changePassword(
              currentPassword: _current.text,
              newPassword: _new.text,
            );
    if (!mounted) return;
    if (error == null) {
      showTopToast(context, l10n.passwordChanged);
      router.pop();
      return;
    }
    setState(() => _saving = false);
    showTopToast(context, error.isEmpty ? l10n.passwordChangeFailed : error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.passwordTitle, style: AppTypography.display(size: 18)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              l10n.settingsChangePasswordHint,
              style: AppTypography.body(size: 13),
            ),
            const SizedBox(height: 20),
            AppInput(
              label: l10n.passwordCurrent,
              controller: _current,
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.loginPassword,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.passwordNew,
              controller: _new,
              obscureText: true,
              prefixIcon: Icons.lock_open_rounded,
              validator: Validators.signupPassword,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.passwordConfirm,
              controller: _confirm,
              obscureText: true,
              prefixIcon: Icons.lock_open_rounded,
              validator: (v) => Validators.signupConfirmPassword(v, _new.text),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.passwordSave,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
