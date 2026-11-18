import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Opens the camera and gives back the first QR it reads, or null when the
/// person backs out. Passed in by the route (it is the same camera the ticket
/// check-in uses), so Perks does not import the spaces feature.
typedef PerkCodeScanner = Future<String?> Function(BuildContext context);

/// Venue and event staff check a perk at the door: scan the guest's code or
/// type it, see whether it is valid, and mark it used. The server decides who
/// may check which perk.
class PerkScanPage extends ConsumerStatefulWidget {
  const PerkScanPage({required this.scan, super.key});

  final PerkCodeScanner scan;

  @override
  ConsumerState<PerkScanPage> createState() => _PerkScanPageState();
}

class _PerkScanPageState extends ConsumerState<PerkScanPage> {
  final _code = TextEditingController();
  bool _busy = false;
  PerkCheck? _result;
  bool _markedUsed = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _reason(Object e) {
    final l10n = context.l10n;
    return e is AppException && e.message.isNotEmpty
        ? e.message
        : l10n.perkScanFailed;
  }

  Future<void> _check(String raw) async {
    final value = raw.trim();
    if (_busy || value.isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(perksRepositoryProvider).check(value);
      if (!mounted) return;
      setState(() {
        _result = result;
        _markedUsed = false;
        _busy = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(context, _reason(e));
    }
  }

  Future<void> _scan() async {
    if (_busy) return;
    final code = await widget.scan(context);
    if (code == null || !mounted) return;
    _code.text = code;
    await _check(code);
  }

  Future<void> _markUsed(PerkCheck result) async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(perksRepositoryProvider).markUsed(result.redemptionId);
      if (!mounted) return;
      setState(() {
        _markedUsed = true;
        _busy = false;
      });
      showTopToast(context, l10n.perkMarkedUsed);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(context, _reason(e));
    }
  }

  void _again() => setState(() {
        _result = null;
        _markedUsed = false;
        _code.clear();
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.perkScanTitle, style: AppTypography.display(size: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (result == null)
            ..._entry(context)
          else
            ..._result_(context, result),
        ],
      ),
    );
  }

  List<Widget> _entry(BuildContext context) {
    final l10n = context.l10n;
    return [
      Text(
        l10n.perkScanIntro,
        style: AppTypography.body(color: AppColors.textMuted),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: l10n.perkScanCamera,
        icon: Icons.qr_code_scanner_rounded,
        onPressed: _busy ? null : _scan,
      ),
      const SizedBox(height: 20),
      Text(l10n.perkScanType.toUpperCase(), style: AppTypography.label()),
      const SizedBox(height: 6),
      AppInput(
        label: l10n.perkCodeHint,
        controller: _code,
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: l10n.perkCheck,
        isLoading: _busy,
        onPressed: _busy ? null : () => _check(_code.text),
      ),
    ];
  }

  List<Widget> _result_(BuildContext context, PerkCheck r) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    final dateTime = DateFormat.yMMMd(locale).add_jm();

    final (title, body, color) = switch (r.state) {
      PerkCheckState.valid => (
          l10n.perkValidTitle,
          l10n.perkValidBody,
          AppColors.accent,
        ),
      PerkCheckState.used => (
          l10n.perkUsedTitle,
          l10n.perkUsedBody,
          AppColors.warning,
        ),
      PerkCheckState.expired => (
          l10n.perkExpiredTitle,
          l10n.perkExpiredBody,
          AppColors.warning,
        ),
    };

    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: AppTypography.body())),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: AppTypography.display(size: 14),
                  ),
                ),
              ],
            ),
          );

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _markedUsed ? l10n.perkMarkedUsed : title,
              style: AppTypography.display(size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              _markedUsed ? l10n.perkMarkUsedNote : body,
              style: AppTypography.body(size: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            row(l10n.perkFieldPerk, r.title),
            row(l10n.perkFieldGuest, r.guestFirstName),
            row(
              l10n.perkBookingLabel,
              [
                if (r.bookingName != null) r.bookingName!,
                if (r.bookingStartAt != null) date.format(r.bookingStartAt!),
              ].join(', '),
            ),
            if (r.state == PerkCheckState.used) ...[
              row(
                l10n.perkFieldUsed,
                r.usedAt == null ? null : dateTime.format(r.usedAt!),
              ),
              row(l10n.perkFieldAt, r.venueName),
            ] else
              row(
                l10n.perkValidUntil,
                r.validUntil == null ? null : date.format(r.validUntil!),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (r.state == PerkCheckState.valid && !_markedUsed) ...[
        PrimaryButton(
          label: l10n.perkMarkUsed,
          isLoading: _busy,
          onPressed: _busy ? null : () => _markUsed(r),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.perkMarkUsedNote,
          textAlign: TextAlign.center,
          style: AppTypography.body(size: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
      ],
      SecondaryButton(label: l10n.perkScanAnother, onPressed: _again),
    ];
  }
}
