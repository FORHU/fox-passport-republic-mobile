import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A Home section's heading with its "See all" on the right.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    required this.title,
    required this.action,
    required this.onAction,
    super.key,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: AppTypography.display(size: 20)),
        ),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(action, style: AppTypography.body()),
          ),
        ),
      ],
    );
  }
}
