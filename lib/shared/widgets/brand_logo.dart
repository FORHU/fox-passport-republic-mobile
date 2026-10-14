import 'package:flutter/material.dart';

/// The FoxPassport mark: the white fox head with the keyhole, same file the web
/// app's `BrandLogo` uses (`foxonlylogo.png`). It is white on transparent, so
/// it belongs on the dark canvas / surfaces.
class FoxLogo extends StatelessWidget {
  const FoxLogo({this.size = 28, super.key});

  static const assetPath = 'assets/images/foxonlylogo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'FoxPassport logo',
    );
  }
}
