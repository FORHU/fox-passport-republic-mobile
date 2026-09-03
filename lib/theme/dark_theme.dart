import 'package:flutter/material.dart';
import 'package:flutter_template/theme/light_theme.dart';

/// Dark theme configuration.
/// Currently mirrors the light theme (mapanytime-app style uses light theme only).
/// If a separate dark theme is needed in the future, implement it here.
class DarkTheme {
  DarkTheme._();

  static ThemeData build() {
    /// For now, use the light theme for dark mode as well.
    /// This matches mapanytime-app's design system which doesn't have a dark variant.
    return LightTheme.build();
  }
}
}
