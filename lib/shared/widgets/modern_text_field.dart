import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:gap/gap.dart';

/// A premium dark text field with an optional floating label and icons.
class ModernTextField extends StatelessWidget {
  const ModernTextField({
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    super.key,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text.secondaryDark,
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
          style: TextStyle(color: AppColors.text.primaryDark, fontSize: 15),
          cursorColor: AppColors.brand.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.text.tertiaryDark),
            filled: true,
            fillColor: AppColors.ui.surfaceElevatedDark,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.text.secondaryDark)
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.ui.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.ui.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(
                color: AppColors.brand.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
