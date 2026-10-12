import 'package:flutter/material.dart';
import 'package:flutter_template/features/onboarding/domain/entities/role_catalog.dart';
import 'package:flutter_template/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter_template/features/onboarding/presentation/theme/onboarding_palette.dart';

/// The card every step sits in: raised surface, hairline border, a soft blurred
/// glow in the top-right corner (the web's `STEP_CARD`).
class StepCard extends StatelessWidget {
  const StepCard({
    required this.child,
    this.glow = OnboardingPalette.accent,
    super.key,
  });

  final Widget child;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 768
            ? 48.0
            : constraints.maxWidth >= 640
                ? 40.0
                : 24.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: OnboardingPalette.surfaceRaised,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: OnboardingPalette.white(0.05)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            glow.withValues(alpha: 0.22),
                            glow.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Icon tile, title and subtitle centred at the top of a step.
class StepHeader extends StatelessWidget {
  const StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = OnboardingPalette.accent,
    this.titleSpans,
    super.key,
  });

  final IconData icon;
  final Color color;

  /// Plain title; ignored when [titleSpans] is given.
  final String title;

  /// For a title with an accent-coloured part ("Welcome, **Ada!**").
  final List<InlineSpan>? titleSpans;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final titleSize = MediaQuery.sizeOf(context).width >= 768 ? 36.0 : 30.0;
    final base = OnboardingPalette.display(size: titleSize);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              style: base,
              children: titleSpans ?? [TextSpan(text: title)],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: OnboardingPalette.body(),
          ),
        ],
      ),
    );
  }
}

/// Divider then the step's own actions.
class StepFooter extends StatelessWidget {
  const StepFooter({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: OnboardingPalette.white(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Lime call-to-action (`bg-accent text-black font-bold rounded-xl`).
class AccentButton extends StatelessWidget {
  const AccentButton({
    required this.label,
    required this.onPressed,
    this.trailing,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailing;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.4,
      child: Material(
        color: OnboardingPalette.accent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                else ...[
                  Text(
                    label,
                    style: OnboardingPalette.body(
                      size: 15,
                      weight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailing, size: 18, color: Colors.black),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordered secondary action (`border-white/10 text-white/70`).
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        side: BorderSide(color: OnboardingPalette.white(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: OnboardingPalette.body(
          weight: FontWeight.w800,
          color: OnboardingPalette.white(0.7),
        ),
      ),
    );
  }
}

/// `← Back` text action.
class BackAction extends StatelessWidget {
  const BackAction({required this.onPressed, this.label = 'Back', super.key});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.arrow_back_rounded,
        size: 18,
        color: OnboardingPalette.white(0.4),
      ),
      label: Text(
        label,
        style: OnboardingPalette.body(
          weight: FontWeight.w800,
          color: OnboardingPalette.white(0.4),
        ),
      ),
    );
  }
}

/// Numbered step pills joined by hairlines (`Profile · Interests · Roles`).
class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({
    required this.journey,
    required this.current,
    super.key,
  });

  final List<OnboardingStep> journey;
  final OnboardingStep current;

  static String _label(OnboardingStep s) => switch (s) {
        OnboardingStep.profile => 'Profile',
        OnboardingStep.intent => 'Interests',
        OnboardingStep.roles => 'Roles',
      };

  @override
  Widget build(BuildContext context) {
    final currentIndex = journey.indexOf(current);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < journey.length; i++) ...[
          if (i > 0)
            Container(
              width: 16,
              height: 1,
              color: i <= currentIndex
                  ? OnboardingPalette.accent.withValues(alpha: 0.6)
                  : OnboardingPalette.white(0.1),
            ),
          _Pill(
            index: i,
            label: _label(journey[i]),
            active: i == currentIndex,
            done: i < currentIndex,
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? OnboardingPalette.accent
        : done
            ? OnboardingPalette.accent.withValues(alpha: 0.15)
            : OnboardingPalette.white(0.05);
    final fg = active
        ? Colors.black
        : done
            ? OnboardingPalette.accent
            : OnboardingPalette.white(0.4);

    return Semantics(
      selected: active,
      label: 'Step ${index + 1}: $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done)
              Icon(Icons.check_rounded, size: 14, color: fg)
            else
              Text(
                '${index + 1}',
                style: OnboardingPalette.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: fg,
                ),
              ),
            // Only the active step spells out its name, to fit narrow phones.
            if (active || MediaQuery.sizeOf(context).width >= 640) ...[
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: OnboardingPalette.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: fg,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status of a role card in step 3.
enum RoleStatus { available, active, pending, revision }

/// Colours for a [RoleStatus] badge.
({Color color, IconData icon, String label}) roleBadge(RoleStatus s) =>
    switch (s) {
      RoleStatus.active => (
          color: OnboardingPalette.success,
          icon: Icons.check_circle_rounded,
          label: 'ACTIVE',
        ),
      RoleStatus.pending => (
          color: OnboardingPalette.warning,
          icon: Icons.schedule_rounded,
          label: 'UNDER REVIEW',
        ),
      RoleStatus.revision => (
          color: OnboardingPalette.orange,
          icon: Icons.flag_rounded,
          label: 'NEEDS REVISION',
        ),
      RoleStatus.available => (
          color: Colors.transparent,
          icon: Icons.circle,
          label: '',
        ),
    };

/// A role in the step-3 grid, in whichever status it is.
class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.role,
    required this.status,
    required this.onTap,
    super.key,
  });

  final RoleCatalogEntry role;
  final RoleStatus status;

  /// Null for roles that can't be acted on (active / under review).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = roleBadge(status);
    final bordered = status != RoleStatus.available;
    final borderColor = bordered
        ? badge.color.withValues(alpha: 0.25)
        : OnboardingPalette.white(0.05);
    final dim = status == RoleStatus.pending;

    final caption = switch (status) {
      RoleStatus.revision => 'One or more documents were flagged — tap to fix '
          'and resubmit.',
      _ => role.desc,
    };

    return Material(
      color: OnboardingPalette.white(0.03),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: dim ? 0.6 : 1,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: role.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(role.icon, color: role.color, size: 24),
                    ),
                  ),
                  const Spacer(),
                  if (bordered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: badge.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badge.icon, size: 11, color: badge.color),
                          const SizedBox(width: 4),
                          Text(
                            badge.label,
                            style: OnboardingPalette.body(
                              size: 10,
                              weight: FontWeight.w800,
                              color: badge.color,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(role.title, style: OnboardingPalette.display()),
              const SizedBox(height: 4),
              Text(
                caption,
                style: OnboardingPalette.body(
                  size: 12,
                  color: status == RoleStatus.revision
                      ? const Color(0xFFFDBA74).withValues(alpha: 0.8)
                      : OnboardingPalette.white(dim ? 0.25 : 0.4),
                ),
              ),
              if (status == RoleStatus.available) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Learn more & apply',
                      style: OnboardingPalette.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: role.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: role.color,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
