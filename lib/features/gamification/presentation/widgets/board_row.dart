import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One line of a leaderboard: position, avatar, name, and under the name the
/// Foxer's role. The caller's own row has an accent border and reads
/// "You · name". There is no rank or level: those are retired.
class BoardRow extends StatelessWidget {
  const BoardRow({
    required this.position,
    required this.name,
    required this.isMe,
    this.rolePill,
    this.image,
    this.squareAvatar = false,
    this.trailing,
    super.key,
  });

  final int position;
  final String name;

  /// The role of a Foxer ("Venue"), shown under the name.
  final String? rolePill;
  final String? image;

  /// A rounded square instead of a circle, as Foxers (who run venues and
  /// listings) are drawn on the board.
  final bool squareAvatar;
  final bool isMe;

  /// Something at the end of the row, such as a level or a Foxer's rating.
  final Widget? trailing;

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
                size: position <= 3 ? 18 : 15,
                color: position <= 3
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          if (squareAvatar)
            _SquareAvatar(url: image, initial: initial)
          else
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
                  isMe ? l10n.leaderboardYouName(name) : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (rolePill != null)
                      Flexible(child: _RolePill(label: rolePill!)),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            // Capped so a long count or large text wraps instead of pushing
            // the name out of the row.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 104),
              child: trailing,
            ),
          ],
        ],
      ),
    );
  }
}

/// A 40 px rounded square: the picture, or the initial when there is none.
class _SquareAvatar extends StatelessWidget {
  const _SquareAvatar({required this.url, required this.initial});

  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final src = url;
    return ClipRRect(
      borderRadius: AppRadius.brMd,
      child: SizedBox(
        width: 40,
        height: 40,
        child: src == null || src.isEmpty
            ? ColoredBox(
                color: AppColors.surfaceRaised,
                child: Center(
                  child: Text(initial, style: AppTypography.display()),
                ),
              )
            : NetworkImageBox(url: src, width: 40, height: 40),
      ),
    );
  }
}

/// "Venue", "Event", ...: the role a Foxer is listed in.
class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.18),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.body(size: 11, color: AppColors.textPrimary),
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

/// A filter pill: white when chosen, dark with a border when not.
class BoardChip extends StatelessWidget {
  const BoardChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: AppRadius.brPill,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.textPrimary : AppColors.surface,
              borderRadius: AppRadius.brPill,
              border: Border.all(
                color: selected ? AppColors.textPrimary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.display(
                size: 14,
                color: selected ? AppColors.canvas : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
