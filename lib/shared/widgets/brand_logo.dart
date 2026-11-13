import 'package:flutter/material.dart';

/// The FoxPassport mark: the white fox head with the keyhole, same file the web
/// app's `BrandLogo` uses (`foxonlylogo.png`). It is white on transparent, so
/// it belongs on the dark canvas / surfaces; give it a [color] to tint it, for
/// example dark on a white disc.
class FoxLogo extends StatelessWidget {
  const FoxLogo({this.size = 28, this.color, super.key});

  static const assetPath = 'assets/images/foxonlylogo.png';

  final double size;

  /// Paints the whole mark in one colour; null leaves it white.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      semanticLabel: 'FoxPassport logo',
    );
  }
}
