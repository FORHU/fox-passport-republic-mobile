import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Tokens per peso: the same rate the server uses to set the price.
const int _tokensPerPeso = 5;

/// Offers a perk: which event package or venue, what you give, what it is
/// worth in pesos and how many. The Token price shows as you type; the server
/// sets the real one from the same peso value.
///
/// [targets] are the person's own event packages and venues, passed in by the
/// route so Perks does not import the spaces feature.
class AddPerkPage extends ConsumerStatefulWidget {
  const AddPerkPage({required this.targets, super.key});

  final AsyncValue<List<PerkTarget>> targets;

  @override
  ConsumerState<AddPerkPage> createState() => _AddPerkPageState();
}

class _AddPerkPageState extends ConsumerState<AddPerkPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _worth = TextEditingController();
  final _quantity = TextEditingController();
  PerkTarget? _target;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The Token price follows the peso value as it is typed.
    _worth.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _worth.dispose();
    _quantity.dispose();
    super.dispose();
  }

  num? get _worthValue => num.tryParse(_worth.text.trim());

  int? get _price {
    final w = _worthValue;
    return w == null || w <= 0 ? null : (w * _tokensPerPeso).round();
  }

  Future<void> _save(List<PerkTarget> targets) async {
    final l10n = context.l10n;
    final target = _target ?? (targets.length == 1 ? targets.first : null);
    if (_busy || target == null || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(perksRepositoryProvider).create(
            target: target,
            title: _title.text.trim(),
            description: _description.text.trim(),
            worthPhp: _worthValue!,
            quantity: int.parse(_quantity.text.trim()),
          );
      ref
        ..invalidate(offeredPerksProvider)
        ..invalidate(perksProvider);
      if (mounted) context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(
        context,
        e is AppException && e.message.isNotEmpty
            ? e.message
            : l10n.perkAddFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.perkAddTitle, style: AppTypography.display(size: 20)),
      ),
      body: widget.targets.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
        ),
        data: (targets) => targets.isEmpty
            ? AppStateView(title: l10n.perkNoTargets)
            : _form_(context, targets),
      ),
    );
  }

  Widget _form_(BuildContext context, List<PerkTarget> targets) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final price = _price;
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.perkRequired : null;

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l10n.perkForWhich.toUpperCase(), style: AppTypography.label()),
          const SizedBox(height: 6),
          DropdownButtonFormField<PerkTarget>(
            initialValue:
                _target ?? (targets.length == 1 ? targets.first : null),
            isExpanded: true,
            items: [
              for (final t in targets)
                DropdownMenuItem(
                  value: t,
                  child: Text(t.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (t) => setState(() => _target = t),
            validator: (v) => v == null ? l10n.perkRequired : null,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.perkWhatYouGive.toUpperCase(),
            style: AppTypography.label(),
          ),
          const SizedBox(height: 6),
          AppInput(
            label: l10n.perkTitleHint,
            controller: _title,
            validator: required,
          ),
          const SizedBox(height: 10),
          AppInput(
            label: l10n.perkDescriptionHint,
            controller: _description,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppInput(
                  label: l10n.perkWorthLabel,
                  controller: _worth,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = num.tryParse((v ?? '').trim());
                    return n == null || n <= 0 ? l10n.perkRequired : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInput(
                  label: l10n.perkHowManyLabel,
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 1 ? l10n.perkRequired : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.perkCitizensPay,
                        style: AppTypography.body(),
                      ),
                    ),
                    const Icon(coinsIcon, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      price == null
                          ? '–'
                          : l10n.perkPaidTokens(format.format(price)),
                      style: AppTypography.display(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.perkRateNote,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.perkHostNote,
            style: AppTypography.body(size: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.perkAddButton,
            isLoading: _busy,
            onPressed: _busy ? null : () => _save(targets),
          ),
        ],
      ),
    );
  }
}
