import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens — elevation and effects.
///
/// `docs/mobile-design.md` §2: **no gradients, glows or blurred blobs; flat
/// fills and hairline borders.** The shadow tokens are therefore empty. They
/// remain so existing call sites compile; use a 1px `AppColors.border` instead.
class AppEffects {
  AppEffects._();

  static const double glassBlur = 18;

  static ImageFilter get glassFilter =>
      ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur);

  static const List<BoxShadow> cardShadow = [];
  static const List<BoxShadow> softShadow = [];
  static const List<BoxShadow> surfaceShadow = [];
  static const List<BoxShadow> primaryGlow = [];
}
