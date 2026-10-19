import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/sign_out.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/currency/currency_sheet.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/area_sheet.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Settings: where "near you" is measured from, the account, and sign out.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final area = ref.watch(areaProvider);
    final filter = ref.watch(areaFilterProvider);
    final user = ref.watch(authControllerProvider).user;
    final currency = ref.watch(displayCurrencyProvider);
    final automatic = ref.watch(currencyChoiceProvider) == null;

    final locationValue = switch (area.source) {
      AreaSource.device when filter.hasPoint => filter.label == null
          ? l10n.settingsLocationDevice
          : '${l10n.settingsLocationDevice} · ${filter.label}',
      _ => filter.city ?? l10n.settingsLocationNone,
    };

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.settingsTitle, style: AppTypography.display(size: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Section(label: l10n.settingsLocation),
          _Row(
            icon: Icons.location_on_outlined,
            title: l10n.settingsLocationTitle,
            value: locationValue,
            onTap: () => showAreaSheet(context),
          ),
          const SizedBox(height: 8),
          _Row(
            icon: Icons.payments_outlined,
            title: l10n.settingsCurrency,
            value: automatic
                ? '$currency · ${l10n.currencyBasedOnLocation}'
                : currency,
            onTap: () => showCurrencySheet(context),
          ),
          const SizedBox(height: 24),
          _Section(label: l10n.settingsAccount),
          _Row(
            icon: Icons.person_outline_rounded,
            title: user?.name.isNotEmpty ?? false ? user!.name : l10n.profile,
            value: user?.email,
            onTap: () => context.push(RouteNames.profile),
          ),
          const SizedBox(height: 8),
          _Row(
            icon: Icons.workspace_premium_outlined,
            title: l10n.rolesTitle,
            value: l10n.rolesSettingsHint,
            onTap: () => context.push(RouteNames.roles),
          ),
          const SizedBox(height: 8),
          _Row(
            icon: Icons.logout_rounded,
            title: l10n.settingsSignOut,
            danger: true,
            onTap: () => confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(label.toUpperCase(), style: AppTypography.label()),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: danger ? color : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 15, color: color),
                  ),
                  if (value != null)
                    Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(size: 12),
                    ),
                ],
              ),
            ),
            if (!danger)
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
