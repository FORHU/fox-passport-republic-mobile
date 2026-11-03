import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One document an application asks for: what it is, the file chosen for it
/// (or a button to choose one), and a way to remove or change it.
class DocumentRow extends ConsumerWidget {
  const DocumentRow({
    required this.label,
    required this.photo,
    required this.onPicked,
    required this.onRemove,
    super.key,
  });

  final String label;
  final PickedPhoto? photo;
  final ValueChanged<PickedPhoto> onPicked;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final picked = photo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            picked == null
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_circle_rounded,
            color: picked == null ? AppColors.textMuted : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body()),
                if (picked != null)
                  Text(
                    picked.name,
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
          if (picked != null)
            IconButton(
              tooltip: l10n.roleApplyRemoveDoc,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () async {
              final p = await ref.read(photoPickerProvider).pick();
              if (p != null) onPicked(p);
            },
            child: Text(
              picked == null ? l10n.roleApplyChoose : l10n.roleApplyChange,
            ),
          ),
        ],
      ),
    );
  }
}
