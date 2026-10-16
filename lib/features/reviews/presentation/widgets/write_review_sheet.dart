import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/reviews/reviews_repository.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// "How was it?": stars and an optional note for a booking. Resolves true once
/// the review is posted.
Future<bool> showWriteReviewSheet(
  BuildContext context, {
  required String bookingId,
  required String title,
}) async {
  final posted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _WriteReview(bookingId: bookingId, title: title),
  );
  return posted ?? false;
}

class _WriteReview extends ConsumerStatefulWidget {
  const _WriteReview({required this.bookingId, required this.title});

  final String bookingId;
  final String title;

  @override
  ConsumerState<_WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends ConsumerState<_WriteReview> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_rating == 0) {
      showTopToast(context, l10n.reviewPickStars);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(reviewsRepositoryProvider).create(
            bookingId: widget.bookingId,
            rating: _rating,
            comment: _comment.text,
          );
      if (!mounted) return;
      showTopToast(context, l10n.reviewThanks);
      Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.reviewFailed,
        );
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reviewTitle, style: AppTypography.display(size: 22)),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i',
                    onPressed: () => setState(() => _rating = i),
                    iconSize: 36,
                    icon: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          i <= _rating ? AppColors.accent : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(hintText: l10n.reviewHint),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.reviewSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
