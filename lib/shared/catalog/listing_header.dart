import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The top of a gear or service page: a short photo with a back button over
/// it, then the category, the title and a "city · rate" line.
///
/// The booking page and the listing preview both use it, so a preview looks
/// like the page guests will open. It takes ready-made text so it depends on
/// no feature's labels.
class ListingHeader extends StatelessWidget {
  const ListingHeader({
    required this.title,
    this.imageUrl,
    this.category,
    this.subtitle,
    this.photoHeight = 160,
    this.onBack,
    super.key,
  });

  final String title;
  final String? imageUrl;

  /// Shown in capitals above the title; left out when null.
  final String? category;

  /// The "city · rate" line; left out when null or empty.
  final String? subtitle;

  /// Low enough that, on a common phone, the booking page's calendar legend
  /// and part of its Days stepper show under a six-row month before any
  /// scrolling.
  final double photoHeight;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            PhotoBox(
              url: imageUrl,
              height: photoHeight,
              width: double.infinity,
              radius: 0,
            ),
            Positioned(
              left: 8,
              top: 8,
              child: IconButton.filled(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.canvas.withAlpha(180),
                  foregroundColor: AppColors.textPrimary,
                ),
                onPressed: onBack ?? () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category != null)
                Text(
                  category!.toUpperCase(),
                  style: AppTypography.label(color: AppColors.accent),
                ),
              const SizedBox(height: 4),
              Text(title, style: AppTypography.display(size: 26)),
              if (sub != null && sub.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
