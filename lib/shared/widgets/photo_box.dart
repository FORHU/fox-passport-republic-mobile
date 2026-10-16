import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// A rounded photo, or the dark placeholder tile when there is no image.
class PhotoBox extends StatelessWidget {
  const PhotoBox({
    this.url,
    this.width,
    this.height,
    this.radius = 16,
    super.key,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src != null && src.isNotEmpty) {
      return NetworkImageBox(
        url: src,
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(radius),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textFaint,
        size: 28,
      ),
    );
  }
}
