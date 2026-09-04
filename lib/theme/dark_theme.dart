import 'package:flutter/material.dart';
import 'package:flutter_template/theme/light_theme.dart';

/// Dark theme configuration.
/// Currently mirrors light theme (mapanytime-app style uses light theme only).
/// If a separate dark theme is needed in the future, implement it here.
class DarkTheme {
  DarkTheme._();

  static ThemeData build() {
    /// For now, use the light theme for dark mode as well.
    /// This matches mapanytime-app's design which has no dark variant.
    return LightTheme.build();
  }
}
