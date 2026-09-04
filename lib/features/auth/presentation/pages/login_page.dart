import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_template/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/effects.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ui.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / icon
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.ink.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppEffects.softShadow,
                      ),
                      child: const Icon(
                        Icons.flutter_dash,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.85, 0.85)),

                  AppSpacing.lg.v,

                  Text(
                    'Welcome back 👋',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.text.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 350.ms)
                      .slideY(begin: 0.15, end: 0),

                  AppSpacing.xs.v,

                  Text(
                    'Sign in to your account to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.text.secondary,
                        ),
                  ).animate().fadeIn(delay: 140.ms, duration: 350.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // White card container
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.ui.surface,
                      borderRadius: AppRadius.brCard,
                      border: Border.all(color: AppColors.ui.borderHairline),
                      boxShadow: AppEffects.surfaceShadow,
                    ),
                    child: const LoginForm(),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.08, end: 0),

                  AppSpacing.lg.v,

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ui.surfaceMuted,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: AppColors.ui.borderHairline),
                    ),
                    child: Text(
                      'Demo: admin@example.com  •  Password123!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
