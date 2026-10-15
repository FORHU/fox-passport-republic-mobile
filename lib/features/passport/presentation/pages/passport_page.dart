import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Passport: the ID card, XP progress, stamps from events attended, badges.
class PassportPage extends ConsumerWidget {
  const PassportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final passport = ref.watch(passportProvider);
    final name = ref.watch(authControllerProvider).user?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async => ref.invalidate(passportProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.passportTitle,
                      style: AppTypography.display(size: 28),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.settingsTitle,
                    onPressed: () => context.push(RouteNames.settings),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              passport.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (_, __) => AppStateView(
                  kind: AppStateKind.error,
                  title: l10n.apiLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(passportProvider),
                ),
                data: (summary) => _Body(summary: summary, name: name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary, required this.name});

  final PassportSummary summary;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stamps = summary.stamps.take(PassportSummary.stampSlots).toList();
    final locale = Localizations.localeOf(context).toString();
    final badges = summary.badges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IdCard(
          summary: summary,
          name: name,
          onTap: () => context.go(RouteNames.profile),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: l10n.passportStamps,
          trailing: l10n.passportStampsCount(
            summary.stamps.length.clamp(0, PassportSummary.stampSlots),
            PassportSummary.stampSlots,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final size = (constraints.maxWidth - gap * 3) / 4;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < PassportSummary.stampSlots; i++)
                  _Stamp(
                    size: size,
                    color: _stampColors[i % _stampColors.length],
                    stamp: i < stamps.length ? stamps[i] : null,
                    locale: locale,
                  ),
              ],
            );
          },
        ),
        if (stamps.isEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.passportEmptyStamps,
                  style: AppTypography.body(),
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.searchFor('events')),
                child: Text(l10n.passportEmptyAction),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _SectionHeader(
          title: l10n.passportBadges,
          action: l10n.passportLeaderboard,
          onAction: () => showTopToast(context, l10n.comingSoonLeaderboard),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final badge in badges.take(8))
              _BadgeChip(
                badge: badge,
                fallbackName: l10n.passportLocked,
              ),
          ],
        ),
      ],
    );
  }

  static const List<Color> _stampColors = [
    AppColors.accent,
    AppColors.roleVenue,
    AppColors.roleGear,
    AppColors.roleTalent,
  ];
}

class _IdCard extends StatelessWidget {
  const _IdCard({
    required this.summary,
    required this.name,
    required this.onTap,
  });

  final PassportSummary summary;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shownName = name.isEmpty ? '—' : name;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 32,
                      color: AppColors.textFaint,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.passportRepublic.toUpperCase(),
                          style: AppTypography.label(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shownName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(size: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.passportCitizenLevel(summary.level),
                          style: AppTypography.body(
                            color: AppColors.accent,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: AppRadius.brPill,
                child: LinearProgressIndicator(
                  value: summary.progress,
                  minHeight: 6,
                  color: AppColors.accent,
                  backgroundColor: AppColors.borderStrong,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.passportXp(summary.totalXp).toUpperCase(),
                    style: AppTypography.label(),
                  ),
                  Text(
                    l10n
                        .passportNextLevel(
                          summary.level + 1,
                          summary.nextLevelXp,
                        )
                        .toUpperCase(),
                    style: AppTypography.label(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderStrong, height: 1),
              const SizedBox(height: 12),
              Text(
                _mrz(shownName, sample: summary.isSample),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: AppTypography.label(color: AppColors.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The machine-readable line of a passport: `P<FOX<CITIZEN<<NAME<<<<<`.
  static String _mrz(String name, {required bool sample}) {
    final body = sample
        ? 'SAMPLE'
        : name
            .toUpperCase()
            .replaceAll(RegExp('[^A-Z ]'), '')
            .trim()
            .replaceAll(RegExp(r'\s+'), '<');
    final line = 'P<FOX<CITIZEN<<$body';
    return line.padRight(34, '<').substring(0, math.max(34, line.length));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.action,
    this.onAction,
  });

  final String title;
  final String? trailing;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(size: 18),
          ),
        ),
        if (trailing != null)
          Text(trailing!.toUpperCase(), style: AppTypography.label()),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                action!,
                style: AppTypography.body(),
              ),
            ),
          ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.size,
    required this.color,
    required this.stamp,
    required this.locale,
  });

  final double size;
  final Color color;
  final PassportStamp? stamp;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = stamp;
    if (s == null) {
      return CustomPaint(
        size: Size.square(size),
        painter: const _DashedCircle(AppColors.borderStrong),
      );
    }
    final month = s.date == null
        ? ''
        : DateFormat.MMM(locale).format(s.date!).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.label,
            style: AppTypography.display(size: 15, color: color),
          ),
          if (month.isNotEmpty)
            Text(month, style: AppTypography.label(color: color)),
        ],
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  const _DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & size;
    const dashes = 28;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color;
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.fallbackName});

  final PassportBadge badge;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    final accent = _parse(badge.colorHex) ?? AppColors.roleGear;
    final name = badge.name.isEmpty ? fallbackName : badge.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: earned ? AppColors.surface : Colors.transparent,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.workspace_premium_outlined : Icons.lock_outline,
            size: 16,
            color: earned ? accent : AppColors.textFaint,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: AppTypography.display(
              size: 14,
              color: earned ? AppColors.textPrimary : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  static Color? _parse(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return null;
    final value = int.tryParse(clean, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }
}
