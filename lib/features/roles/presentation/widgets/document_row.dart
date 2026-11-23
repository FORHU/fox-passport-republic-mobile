import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/documents/document_picker.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
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
    this.frontCamera = false,
    this.document = false,
    this.boxed = false,
    this.optional = false,
    super.key,
  });

  /// The Provider wizard's card look (mobile#487): a boxed row saying
  /// "Required" until chosen, with Upload, Take or Replace.
  final bool boxed;

  /// Boxed only: says "Optional" instead of "Required" until chosen.
  final bool optional;

  final String label;
  final PickedPhoto? photo;
  final ValueChanged<PickedPhoto> onPicked;
  final VoidCallback onRemove;

  /// The selfie: the camera opens on the front lens.
  final bool frontCamera;

  /// A portfolio or resume: a PDF or Word file from the device's files, not
  /// a photo (app#371).
  final bool document;

  /// Gets a PDF or Word file; one that can't be used is said plainly.
  Future<void> _chooseDocument(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(documentPickerProvider).pick();
    if (!context.mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case DocumentPicked(:final file):
        onPicked(file);
      case DocumentPickCancelled():
        break;
      case DocumentPickFailed(:final reason):
        showTopToast(
          context,
          switch (reason) {
            DocumentPickFailure.unsupported => l10n.roleApplyDocUnsupported,
            DocumentPickFailure.tooLarge => l10n.roleApplyDocTooLarge,
            DocumentPickFailure.other => l10n.roleApplyDocFailed,
          },
        );
    }
  }

  /// Asks where the photo comes from, then gets it. A refused or missing
  /// camera is said plainly, and the gallery stays available.
  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) {
        final l10n = sheet.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.roleApplyTakePhoto),
                onTap: () => Navigator.of(sheet).pop(PhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.roleApplyFromGallery),
                onTap: () => Navigator.of(sheet).pop(PhotoSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final result = await ref
        .read(photoCaptureProvider)
        .take(source: source, frontCamera: frontCamera);
    if (!context.mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case PhotoPicked(:final photo):
        onPicked(photo);
      case PhotoPickCancelled():
        break;
      case PhotoPickFailed(:final reason):
        showTopToast(
          context,
          switch (reason) {
            PhotoPickFailure.cameraDenied => l10n.roleApplyCameraDenied,
            PhotoPickFailure.cameraUnavailable =>
              l10n.roleApplyCameraUnavailable,
            PhotoPickFailure.other => l10n.roleApplyPhotoFailed,
          },
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final picked = photo;
    if (boxed) {
      final action = picked != null
          ? l10n.provApplyReplace
          : frontCamera
              ? l10n.provApplyTake
              : l10n.provApplyUpload;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              picked == null
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.check_rounded,
              size: 20,
              color: picked == null ? AppColors.inputBorder : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked?.name ??
                        (optional
                            ? l10n.provApplyOptional
                            : l10n.provApplyRequired),
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
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppColors.textPrimary,
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: picked == null
                      ? AppColors.textPrimary
                      : AppColors.borderStrong,
                ),
              ),
              onPressed: () => document
                  ? _chooseDocument(context, ref)
                  : _choose(context, ref),
              child: Semantics(
                label: '$action $label',
                excludeSemantics: true,
                child: Text(
                  action,
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
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
                if (picked == null && document)
                  Text(
                    l10n.roleApplyPortfolioFormats,
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
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
            onPressed: () => document
                ? _chooseDocument(context, ref)
                : _choose(context, ref),
            child: Text(
              picked == null ? l10n.roleApplyChoose : l10n.roleApplyChange,
            ),
          ),
        ],
      ),
    );
  }
}
