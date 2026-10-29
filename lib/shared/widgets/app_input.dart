import 'package:flutter/material.dart';

/// Thin wrapper over [TextFormField] with a consistent look.
class AppInput extends StatelessWidget {
  const AppInput({
    required this.label,
    super.key,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  /// More than one for a box that takes a few lines, such as a bio.
  final int maxLines;

  /// Stops typing at this many characters and shows a counter.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText || maxLines == 1 ? 1 : 2,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}
