import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:gap/gap.dart';

/// Primary action: lime fill, `onAccent` text, Space Grotesk 700, 52 tall,
/// radius 16, full width, no shadow. One per screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _PressableButton(
      onPressed: onPressed,
      expand: expand,
      isLoading: isLoading,
      label: label,
      icon: icon,
      foreground: AppColors.onAccent,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadius.brMd,
      ),
      pressedColor: AppColors.accentPressed,
    );
  }
}

/// Secondary action: transparent, 1px `borderStrong`, white text. Used for
/// social sign-in and secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _PressableButton(
      onPressed: onPressed,
      expand: expand,
      isLoading: isLoading,
      label: label,
      icon: icon,
      foreground: AppColors.textPrimary,
      fontSize: 14,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.borderStrong),
      ),
      pressedColor: AppColors.surface,
    );
  }
}

/// Kept for existing call sites. The spec has no gradient button, so this is
/// the primary button.
class GradientButton extends PrimaryButton {
  const GradientButton({
    required super.label,
    required super.onPressed,
    super.icon,
    super.expand,
    super.isLoading,
    super.key,
  });
}

class _PressableButton extends StatefulWidget {
  const _PressableButton({
    required this.label,
    required this.onPressed,
    required this.decoration,
    required this.foreground,
    required this.pressedColor,
    required this.expand,
    required this.isLoading,
    this.fontSize = 15,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final BoxDecoration decoration;
  final Color foreground;
  final Color pressedColor;
  final double fontSize;
  final bool expand;
  final bool isLoading;
  final IconData? icon;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setDown({required bool value}) => setState(() => _down = value);

  @override
  Widget build(BuildContext context) {
    final decoration = _down
        ? widget.decoration.copyWith(color: widget.pressedColor)
        : widget.decoration;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _setDown(value: true) : null,
        onTapUp: _enabled ? (_) => _setDown(value: false) : null,
        onTapCancel: _enabled ? () => _setDown(value: false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedOpacity(
          opacity: widget.onPressed == null ? 0.4 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.expand ? double.infinity : null,
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: decoration,
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(widget.foreground),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.foreground, size: 20),
                        const Gap(AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            size: widget.fontSize,
                            color: widget.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
