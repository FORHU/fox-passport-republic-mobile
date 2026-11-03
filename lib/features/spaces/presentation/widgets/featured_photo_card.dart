import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The next thing coming up, led by a photo: its day over the picture (and a
/// status chip on the other corner), then what it is and where. The picture is
/// a grey placeholder when there is none.
class FeaturedPhotoCard extends StatelessWidget {
  const FeaturedPhotoCard({
    required this.dayLabel,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.highlight = false,
    this.statusChip,
    super.key,
  });

  /// "TODAY" or a short date, upper case.
  final String dayLabel;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  /// Outlines the card in lime, for something happening today.
  final bool highlight;

  /// Shown in the top right corner of the picture.
  final Widget? statusChip;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: highlight ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PhotoBox(
                url: imageUrl,
                width: double.infinity,
                height: 140,
                radius: 0,
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    dayLabel,
                    style: AppTypography.label(
                      color:
                          highlight ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (statusChip != null)
                Positioned(right: 12, top: 12, child: statusChip!),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(),
                ),
                if (sub != null && sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(size: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
