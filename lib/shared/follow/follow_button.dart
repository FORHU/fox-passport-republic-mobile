import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Follow, Requested (a private account has not answered) or Following, with
/// how many follow them. Tapping flips between following and not.
class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(FollowStatus status) async {
    final l10n = context.l10n;
    final controller = ref.read(followProvider(widget.userId).notifier);
    setState(() => _busy = true);
    try {
      if (status.state == FollowState.none) {
        await controller.follow();
        final now = ref.read(followProvider(widget.userId)).value;
        if (mounted && now?.state == FollowState.pending) {
          showTopToast(context, l10n.followRequestSent);
        }
      } else {
        await controller.unfollow();
      }
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.followFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Failing to load the status just leaves the button off.
    final status = ref.watch(followProvider(widget.userId)).value;
    if (status == null) return const SizedBox.shrink();

    final following = status.state != FollowState.none;
    final label = switch (status.state) {
      FollowState.none => l10n.followAction,
      FollowState.pending => l10n.followRequested,
      FollowState.following => l10n.followFollowing,
    };
    final followers = status.followers;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: following
              ? OutlinedButton(
                  onPressed: _busy ? null : () => _toggle(status),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                  ),
                  child: Text(label),
                )
              : ElevatedButton(
                  onPressed: _busy ? null : () => _toggle(status),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                  ),
                  child: Text(label),
                ),
        ),
        if (followers != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              l10n.followFollowers(followers),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(),
            ),
          ),
        ],
      ],
    );
  }
}
