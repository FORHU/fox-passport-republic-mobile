import 'package:flutter/material.dart';
import 'package:flutter_template/features/onboarding/domain/entities/role_catalog.dart';
import 'package:flutter_template/features/onboarding/presentation/theme/onboarding_palette.dart';

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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
              const SizedBox(height: 20),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: role.color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(role.title, style: OnboardingPalette.display(size: 24)),
              const SizedBox(height: 4),
              Text(
                role.desc,
                style: OnboardingPalette.body(
                  color: OnboardingPalette.white(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const _Heading("What you'll do"),
              for (final item in role.responsibilities)
                _Bullet(
                  icon: Icons.check_circle_rounded,
                  iconColor: role.color,
                  text: item,
                  textColor: OnboardingPalette.white(0.7),
                ),
              const SizedBox(height: 20),
              const _Heading("What you'll need to apply"),
              for (final item in role.requirements)
                _Bullet(
                  icon: Icons.description_outlined,
                  iconColor: OnboardingPalette.white(0.3),
                  text: item,
                  textColor: OnboardingPalette.white(0.6),
                ),
              const SizedBox(height: 16),
              Text(
                'Our team reviews every application. If a document needs '
                "fixing, we'll flag just that one so you can resubmit it.",
                style: OnboardingPalette.body(
                  size: 12,
                  color: OnboardingPalette.white(0.35),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: OnboardingPalette.white(0.1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Not now',
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
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue to application',
                        style: OnboardingPalette.body(
                          weight: FontWeight.w800,
                          color: Colors.black,
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
