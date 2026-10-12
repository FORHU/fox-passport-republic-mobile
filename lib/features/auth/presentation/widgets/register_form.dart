import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/modern_text_field.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:go_router/go_router.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
          _emailController.text,
          _passwordController.text,
          name: _nameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      showTopToast(context, 'Account created! Please sign in.');
      context.go(RouteNames.login);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showTopToast(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
            label: 'Full Name',
            hint: 'Jane Smith',
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 350.ms)
              .slideY(begin: 0.1, end: 0),
          AppSpacing.md.v,
          ModernTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          )
              .animate()
              .fadeIn(delay: 160.ms, duration: 350.ms)
              .slideY(begin: 0.1, end: 0),
          AppSpacing.md.v,
          ModernTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.text.tertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          )
              .animate()
              .fadeIn(delay: 220.ms, duration: 350.ms)
              .slideY(begin: 0.1, end: 0),
          AppSpacing.md.v,
          ModernTextField(
            label: 'Confirm Password',
            hint: '••••••••',
            controller: _confirmController,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.text.tertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          )
              .animate()
              .fadeIn(delay: 280.ms, duration: 350.ms)
              .slideY(begin: 0.1, end: 0),
          AppSpacing.xl.v,
          PrimaryButton(
            label: 'Create Account',
            isLoading: state.isLoading,
            onPressed: _submit,
          )
              .animate()
              .fadeIn(delay: 340.ms, duration: 350.ms)
              .slideY(begin: 0.1, end: 0),
          AppSpacing.lg.v,
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: AppColors.text.secondary,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(RouteNames.login),
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    color: AppColors.ink.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
