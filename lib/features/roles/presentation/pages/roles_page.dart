import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/roles/role_request.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Become a Foxer: the roles a citizen can apply for, where each application
/// stands, and a way into the application form (which asks for identity
/// documents, so it is completed on the web).
class RolesPage extends ConsumerWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(myRoleRequestsProvider);
    final held = ref.watch(authControllerProvider).user?.roleType ?? const [];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.rolesTitle, style: AppTypography.display(size: 18)),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async => ref.invalidate(myRoleRequestsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(l10n.rolesIntro, style: AppTypography.body()),
            const SizedBox(height: 16),
            for (final role in roleCatalog) ...[
              _RoleCard(
                role: role,
                status: _statusOf(role, held, requests.value ?? const []),
                onTap: () => _open(context, role),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  static _RoleStatus _statusOf(
    RoleCatalogEntry role,
    List<String> held,
    List<RoleRequestSummary> requests,
  ) {
    if (held.contains(role.roleType)) return _RoleStatus.active;
    final mine = requests.where((r) => r.roleType == role.roleType);
    if (mine.any((r) => r.isApproved)) return _RoleStatus.active;
    if (mine.any((r) => r.needsRevision)) return _RoleStatus.revision;
    if (mine.any((r) => r.isPending)) return _RoleStatus.review;
    return _RoleStatus.none;
  }

  Future<void> _open(BuildContext context, RoleCatalogEntry role) async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoleSheet(role: role),
    );
    if (proceed != true || !context.mounted) return;
    final opened = await openWebApp(role.href);
    if (!opened && context.mounted) {
      showTopToast(context, context.l10n.onboardingWebNotConfigured);
    }
  }
}

enum _RoleStatus { none, review, revision, active }

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.status,
    required this.onTap,
  });

  final RoleCatalogEntry role;
  final _RoleStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badge = switch (status) {
      _RoleStatus.active => (l10n.onboardingStatusActive, AppColors.success),
      _RoleStatus.review => (l10n.onboardingStatusReview, AppColors.warning),
      _RoleStatus.revision => (l10n.onboardingStatusRevision, AppColors.error),
      _RoleStatus.none => null,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.15),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(role.icon, color: role.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          role.title,
                          style: AppTypography.display(size: 15),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          badge.$1,
                          style: AppTypography.label(color: badge.$2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(role.desc, style: AppTypography.body(size: 13)),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSheet extends StatelessWidget {
  const _RoleSheet({required this.role});

  final RoleCatalogEntry role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Text(role.title, style: AppTypography.display(size: 20)),
            const SizedBox(height: 4),
            Text(role.desc, style: AppTypography.body()),
            const SizedBox(height: 16),
            _Heading(l10n.onboardingWhatYoullDo),
            for (final item in role.responsibilities)
              _Bullet(item, Icons.check_circle_rounded, role.color),
            const SizedBox(height: 12),
            _Heading(l10n.onboardingWhatYoullNeed),
            for (final item in role.requirements)
              _Bullet(item, Icons.description_outlined, AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingReviewNote,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: const BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                      child: Text(l10n.onboardingNotNow),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                      child: Text(l10n.rolesContinueOnWeb),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(), style: AppTypography.label()),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, this.icon, this.color);

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppTypography.body(size: 13))),
          ],
        ),
      );
}
