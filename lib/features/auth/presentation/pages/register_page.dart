import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_template/features/auth/presentation/pages/login_page.dart'
    show LoginPage;
import 'package:flutter_template/features/auth/presentation/widgets/register_form.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/effects.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

/// Register page — ink-on-white aesthetic matching [LoginPage].
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.85, 0.85)),

                  AppSpacing.lg.v,

                  Text(
                    'Create account',
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
                    'Fill in the details below to get started',
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
                    child: const RegisterForm(),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.08, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
