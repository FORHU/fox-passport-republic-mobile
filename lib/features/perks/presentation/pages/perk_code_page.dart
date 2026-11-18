import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/screen/screen_brightness_boost.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The perk to show at the door: a QR that changes every 30 seconds (so a
/// screenshot is no use), the typed code under it, and when it is valid until.
/// Fetches a new live code each time the countdown ends.
class PerkCodePage extends ConsumerStatefulWidget {
  const PerkCodePage({required this.redemptionId, super.key});

  final String redemptionId;

  @override
  ConsumerState<PerkCodePage> createState() => _PerkCodePageState();
}

class _PerkCodePageState extends ConsumerState<PerkCodePage> {
  PerkCode? _code;
  Object? _error;
  int _left = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final code =
          await ref.read(perksRepositoryProvider).code(widget.redemptionId);
      if (!mounted) return;
      setState(() {
        _code = code;
        _error = null;
        _left = code.refreshInSeconds;
      });
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_left <= 1) {
          _tick?.cancel();
          unawaited(_load());
        } else {
          setState(() => _left -= 1);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      _tick?.cancel();
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = _code;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.rewards),
        ),
      ),
      body: code != null
          ? _ready(context, code)
          : _error != null
              ? AppStateView(
                  kind: AppStateKind.error,
                  title: _error is AppException &&
                          (_error! as AppException).message.isNotEmpty
                      ? l10n.perkCodeUnavailable
                      : l10n.apiLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () {
                    setState(() => _error = null);
                    unawaited(_load());
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
    );
  }

  Widget _ready(BuildContext context, PerkCode code) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final time = '0:${_left.toString().padLeft(2, '0')}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(l10n.perkYourPerk.toUpperCase(), style: AppTypography.label()),
        const SizedBox(height: 6),
        Text(code.title, style: AppTypography.display(size: 24)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: AppRadius.brMd,
                ),
                // A dim screen is hard to scan at the door.
                child: BrightWhileVisible(
                  child: QrImageView(
                    data: code.live,
                    size: 164,
                    backgroundColor: AppColors.lightSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                code.code,
                style: AppTypography.display(size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.perkNewCodeIn(time),
                style: AppTypography.body(size: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.perkCodeChanges,
                textAlign: TextAlign.center,
                style: AppTypography.body(size: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (code.expiresAt != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.perkValidUntil,
                        style: AppTypography.body(),
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd(locale).format(code.expiresAt!),
                      style: AppTypography.display(size: 14),
                    ),
                  ],
                ),
                const Divider(height: 24),
              ],
              Text(
                l10n.perkConfirmNote,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SecondaryButton(
          label: l10n.perkBackToRewards,
          onPressed: () => context.go(RouteNames.rewards),
        ),
      ],
    );
  }
}
