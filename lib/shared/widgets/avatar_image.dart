import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// A round picture of a person or a chat. Loads through the same cached,
/// retrying loader as every other photo, so an avatar is never a silent blank;
/// with no picture it shows [fallback] (an initial or an icon).
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    required this.url,
    required this.radius,
    required this.fallback,
    super.key,
  });

  final String? url;
  final double radius;

  /// Drawn when there is no picture.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final src = url;
    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceRaised,
      child: src == null || src.isEmpty
          ? fallback
          : ClipOval(
              child: NetworkImageBox(url: src, width: size, height: size),
            ),
    );
  }
}
