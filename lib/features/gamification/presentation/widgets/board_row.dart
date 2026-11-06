import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One line of a leaderboard: position, avatar, name and a line under it.
/// The caller's own row has an accent border and a "You" tag. It shows no
/// scores: the server does not send any.
class BoardRow extends StatelessWidget {
  const BoardRow({
    required this.position,
    required this.name,
    required this.subtitle,
    required this.isMe,
    this.image,
    super.key,
  });

  final int position;
  final String name;
  final String subtitle;
  final String? image;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: isMe ? AppColors.accent : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$position',
              style: AppTypography.display(
                color:
                    position <= 3 ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
          AvatarImage(
            url: image,
            radius: 20,
            fallback: Text(initial, style: AppTypography.display()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            Text(
              l10n.leaderboardYou,
              style: AppTypography.display(size: 13, color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}

/// A leaderboard's rows, with the caller's own row pinned below them when the
/// list does not reach it ([pinned] is null when it does, or they are absent).
class BoardList extends StatelessWidget {
  const BoardList({required this.rows, this.pinned, super.key});

  final List<Widget> rows;
  final Widget? pinned;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => rows[i],
          ),
        ),
        if (pinned != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: pinned,
          ),
      ],
    );
  }
}
