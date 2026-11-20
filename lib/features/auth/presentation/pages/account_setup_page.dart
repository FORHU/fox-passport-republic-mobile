import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:flutter_template/features/auth/presentation/widgets/sign_out.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/modern_text_field.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

/// How long typing pauses before the username is checked.
const usernameCheckDelay = Duration(milliseconds: 400);

enum _Availability { idle, checking, available, taken }

/// A Google account picks the username and password it lacks before using
/// the app (api#419). Only the missing ones are asked; the username is
/// checked as it is typed. The router keeps the account here until both are
/// set, then moves on by itself.
class AccountSetupPage extends ConsumerStatefulWidget {
  const AccountSetupPage({super.key});

  @override
  ConsumerState<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends ConsumerState<AccountSetupPage> {
  final _formKey = GlobalKey<FormState>();
  // No errors until the first submit; after that they follow the input.
  bool _submitted = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  _Availability _availability = _Availability.idle;
  Timer? _debounce;
  // The username a pending check is for; a newer one makes it stale.
  String _checking = '';

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    final value = _usernameController.text.trim().toLowerCase();
    if (Validators.username(value) != null) {
      _checking = '';
      if (_availability != _Availability.idle) {
        setState(() => _availability = _Availability.idle);
      }
      return;
    }
    _checking = value;
    setState(() => _availability = _Availability.checking);
    _debounce = Timer(usernameCheckDelay, () => unawaited(_check(value)));
  }

  Future<void> _check(String value) async {
    final free = await ref
        .read(authControllerProvider.notifier)
        .isUsernameAvailable(value);
    if (!mounted || value != _checking) return;
    setState(() {
      _availability = switch (free) {
        true => _Availability.available,
        false => _Availability.taken,
        null => _Availability.idle,
      };
    });
  }

  Future<void> _submit({required bool needsUsername}) async {
    if (!_submitted) setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (needsUsername && _availability == _Availability.taken) return;

    final needsPassword =
        !(ref.read(authControllerProvider).user?.hasPassword ?? true);
    final ok = await ref.read(authControllerProvider.notifier).setUpCredentials(
          username: needsUsername
              ? _usernameController.text.trim().toLowerCase()
              : null,
          password: needsPassword ? _passwordController.text : null,
        );
    if (!mounted) return;
    if (ok) {
      // The router leaves this page now that nothing is missing.
      showTopToast(context, context.l10n.accountSetupDone);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showTopToast(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    final user = state.user;
    final needsUsername = user != null && user.username.trim().isEmpty;
    final needsPassword = user != null && !user.hasPassword;

    return AuthPageShell(
      eyebrow: l10n.accountSetupEyebrow,
      headline: l10n.accountSetupHeadline,
      body: needsUsername && needsPassword
          ? l10n.accountSetupBodyBoth
          : needsUsername
              ? l10n.accountSetupBodyUsername
              : l10n.accountSetupBodyPassword,
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (needsUsername) ...[
              ModernTextField(
                key: const Key('account-setup-username'),
                hint: l10n.authUsername,
                controller: _usernameController,
                autofillHints: const [AutofillHints.newUsername],
                helperText: switch (_availability) {
                  _Availability.checking => l10n.accountSetupChecking,
                  _Availability.available => l10n.accountSetupAvailable,
                  _Availability.taken => l10n.accountSetupTaken,
                  _Availability.idle => l10n.accountSetupUsernameHelper,
                },
                validator: (v) =>
                    Validators.username(v) ??
                    (_availability == _Availability.taken
                        ? l10n.accountSetupTaken
                        : null),
              ),
              AppSpacing.md.v,
            ],
            if (needsPassword) ...[
              ModernTextField(
                key: const Key('account-setup-password'),
                hint: l10n.accountSetupPassword,
                controller: _passwordController,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                helperText: l10n.accountSetupPasswordHelper,
                validator: Validators.signupPassword,
                suffixIcon: IconButton(
                  tooltip:
                      _obscure ? l10n.authShowPassword : l10n.authHidePassword,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              AppSpacing.md.v,
              ModernTextField(
                key: const Key('account-setup-confirm'),
                hint: l10n.resetConfirmPassword,
                controller: _confirmController,
                obscureText: _obscure,
                validator: (v) => Validators.signupConfirmPassword(
                  v,
                  _passwordController.text,
                ),
              ),
              AppSpacing.md.v,
            ],
            AppSpacing.sm.v,
            PrimaryButton(
              label: l10n.accountSetupContinue,
              isLoading: state.isLoading,
              onPressed: () => _submit(needsUsername: needsUsername),
            ),
            AppSpacing.md.v,
            TextButton(
              onPressed: () => confirmSignOut(context, ref),
              child: Text(
                l10n.settingsSignOut,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
