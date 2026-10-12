import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:gap/gap.dart';

/// Text input per `docs/mobile-design.md` §3: `surface` fill, 1px `border`,
/// radius 16, placeholder in `textMuted`, lime focus border, error border.
///
/// Fill, borders and radius come from the app's `InputDecorationTheme`, so
/// every field in the app stays in step. Pass [hint] as the visible name
/// ("Email address"); [label] adds a small caption above, for dense forms.
class ModernTextField extends StatelessWidget {
  const ModernTextField({
    this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction,
    super.key,
  });

  final String? label;
  final String? hint;

  /// A muted line under the field, e.g. password rules.
  final String? helperText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.body(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          style: AppTypography.body(
            size: 15,
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 2,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
