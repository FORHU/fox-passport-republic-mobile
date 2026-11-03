import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Why someone is reporting a post, person or venue. Resolves the reason, or
/// null. [title] names what is being reported.
Future<String?> showReportSheet(BuildContext context, {String? title}) {
  final l10n = context.l10n;
  final reasons = [
    l10n.republicReasonSpam,
    l10n.republicReasonHarassment,
    l10n.republicReasonHate,
    l10n.republicReasonNudity,
    l10n.republicReasonViolence,
    l10n.republicReasonMisinfo,
    l10n.republicReasonOther,
  ];
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                title ?? l10n.republicReportTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final r in reasons)
              ListTile(
                title: Text(r),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    ),
  );
}
