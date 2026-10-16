import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/onboarding/presentation/theme/onboarding_palette.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Shown when a citizen picks a role to apply for: what the role involves and
/// what the application asks for, before they commit to the form. Resolves to
/// true when they choose to continue to the application.
Future<bool> showRoleDetailsSheet(
  BuildContext context,
  RoleCatalogEntry role,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: OnboardingPalette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RoleDetailsSheet(role: role),
  );
  return result ?? false;
}

class _RoleDetailsSheet extends StatelessWidget {
  const _RoleDetailsSheet({required this.role});

  final RoleCatalogEntry role;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OnboardingPalette.white(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(role.icon, color: role.color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(role.title, style: OnboardingPalette.display(size: 20)),
              const SizedBox(height: 4),
              Text(
                role.desc,
                style: OnboardingPalette.body(
                  color: OnboardingPalette.white(0.5),
                ),
              ),
              const SizedBox(height: 12),
              _Heading(context.l10n.onboardingWhatYoullDo),
              for (final item in role.responsibilities)
                _Bullet(
                  icon: Icons.check_circle_rounded,
                  iconColor: role.color,
                  text: item,
                  textColor: OnboardingPalette.white(0.7),
                ),
              const SizedBox(height: 14),
              _Heading(context.l10n.onboardingWhatYoullNeed),
              for (final item in role.requirements)
                _Bullet(
                  icon: Icons.description_outlined,
                  iconColor: OnboardingPalette.white(0.3),
                  text: item,
                  textColor: OnboardingPalette.white(0.6),
                ),
              const SizedBox(height: 12),
              Text(
                context.l10n.onboardingReviewNote,
                style: OnboardingPalette.body(
                  size: 12,
                  color: OnboardingPalette.white(0.35),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: OnboardingPalette.white(0.1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.l10n.onboardingNotNow,
                        style: OnboardingPalette.body(
                          color: OnboardingPalette.white(0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: role.color,
                        foregroundColor: AppColors.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.l10n.onboardingContinueApplication,
                        style: OnboardingPalette.body(
                          weight: FontWeight.w800,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: OnboardingPalette.body(
          size: 11,
          weight: FontWeight.w800,
          color: OnboardingPalette.white(0.7),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: OnboardingPalette.body(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
