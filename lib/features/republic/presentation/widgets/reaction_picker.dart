import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// The words for a reaction.
String reactionLabel(AppLocalizations l10n, ReactionType type) =>
    switch (type) {
      ReactionType.like => l10n.republicLike,
      ReactionType.love => l10n.republicReactLove,
      ReactionType.haha => l10n.republicReactHaha,
      ReactionType.wow => l10n.republicReactWow,
      ReactionType.sad => l10n.republicReactSad,
      ReactionType.angry => l10n.republicReactAngry,
    };

/// The six reactions in a row just above [anchor] (the Like button), opened by
/// a long press. Resolves the one tapped, or null.
Future<ReactionType?> showReactionPicker(
  BuildContext anchor, {
  ReactionType? current,
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final origin = box.localToGlobal(Offset.zero);
  final screen = MediaQuery.sizeOf(anchor);
  const width = 6 * 46.0 + 16;
  final left = math.max(8, math.min(origin.dx, screen.width - width - 8));

  return showGeneralDialog<ReactionType>(
    context: anchor,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(anchor).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
        alignment: Alignment.bottomLeft,
        child: child,
      ),
    ),
    pageBuilder: (context, _, __) => Stack(
      children: [
        Positioned(
          left: left.toDouble(),
          top: math.max(origin.dy - 60, 8),
          child: Material(
            color: AppColors.surface,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in ReactionType.values)
                    InkResponse(
                      radius: 24,
                      onTap: () => Navigator.pop(context, r),
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: r == current
                              ? AppColors.accent.withValues(alpha: 0.18)
                              : null,
                        ),
                        child: Text(
                          r.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// How many people chose each reaction on a post.
Future<void> showReactionBreakdown(BuildContext context, String postId) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _Breakdown(postId: postId),
    );

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final _breakdownProvider =
    FutureProvider.autoDispose.family<List<ReactionCount>, String>(
  (ref, postId) => ref.watch(republicRepositoryProvider).reactions(postId),
);

class _Breakdown extends ConsumerWidget {
  const _Breakdown({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final counts = ref.watch(_breakdownProvider(postId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.republicReactions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          counts.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            error: (_, __) => Text(l10n.republicActionFailed),
            data: (list) => list.isEmpty
                ? Text(l10n.republicNoReactions)
                : Column(
                    children: [
                      for (final c in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            c.type.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(reactionLabel(l10n, c.type)),
                          trailing: Text('${c.count}'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
