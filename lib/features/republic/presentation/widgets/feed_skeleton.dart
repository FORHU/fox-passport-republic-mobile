import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/skeleton.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Post-shaped placeholders for the feed while its first page loads: the
/// author row, a few lines of words and a photo, split by the same thick
/// rule the real posts are.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const Divider(
          height: 8,
          thickness: 8,
          color: AppColors.surface,
        ),
        itemBuilder: (_, __) => const _PostShape(),
      ),
    );
  }
}

class _PostShape extends StatelessWidget {
  const _PostShape();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(
                width: 40,
                height: 40,
                radius: BorderRadius.all(Radius.circular(20)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 12),
                    SizedBox(height: 6),
                    SkeletonBox(width: 70, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBox(height: 12),
          SizedBox(height: 6),
          SkeletonBox(height: 12),
          SizedBox(height: 6),
          SkeletonBox(width: 180, height: 12),
          SizedBox(height: 14),
          SkeletonBox(height: 200),
        ],
      ),
    );
  }
}
