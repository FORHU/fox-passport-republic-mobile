import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/reports/report_sheet.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';

/// What can be reported besides a post: a person or a venue.
enum ReportTarget {
  user,
  venue;

  /// How the API names it.
  String get wire => name;
}

/// Asks why, then files a report against [id]. Says whether it went through.
/// Resolves to true when the report was filed.
Future<bool> fileReport(
  BuildContext context,
  WidgetRef ref, {
  required ReportTarget target,
  required String id,
  required String title,
}) async {
  final l10n = context.l10n;
  final reason = await showReportSheet(context, title: title);
  if (reason == null || !context.mounted) return false;

  try {
    await ref.read(apiServiceProvider).post(ApiEndpoints.reports, {
      'targetType': target.wire,
      'targetId': id,
      'reason': reason,
    });
    if (context.mounted) showTopToast(context, l10n.republicReported);
    return true;
  } on Object catch (e) {
    if (context.mounted) {
      showTopToast(context, e is AppException ? e.message : l10n.reportFailed);
    }
    return false;
  }
}
