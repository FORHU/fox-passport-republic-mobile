import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Cached remote image with an ink-style shimmer placeholder and error box.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: resolveAssetUrl(url),
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            _Placeholder(width: width, height: height),
        errorWidget: (context, url, error) =>
            _ErrorBox(width: width, height: height),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.ui.surfaceMuted,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.text.tertiary,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.ui.surfaceMuted,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.text.tertiary,
      ),
    );
  }
}
