import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/domain/promotion.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The form for a new discount on one of [venues]. Resolves what was filled
/// in, or null when dismissed.
Future<PromotionDraft?> showPromotionSheet(
  BuildContext context,
  List<SpaceListing> venues,
) {
  return showModalBottomSheet<PromotionDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _PromotionForm(venues: venues),
  );
}

class _PromotionForm extends StatefulWidget {
  const _PromotionForm({required this.venues});

  final List<SpaceListing> venues;

  @override
  State<_PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<_PromotionForm> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  late String _venueId = widget.venues.first.id;
  bool _percentage = true;
  bool _auto = false;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  num? get _amount => num.tryParse(_value.text.trim());

  bool get _valid {
    final amount = _amount;
    if (_name.text.trim().isEmpty || amount == null || amount <= 0) {
      return false;
    }
    return !_percentage || amount <= 100;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.promotionNew, style: AppTypography.display(size: 18)),
            const SizedBox(height: 16),
            if (widget.venues.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _venueId,
                decoration: InputDecoration(labelText: l10n.promotionVenue),
                items: [
                  for (final v in widget.venues)
                    DropdownMenuItem(value: v.id, child: Text(v.name)),
                ],
                onChanged: (id) => setState(() => _venueId = id ?? _venueId),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.promotionName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.promotionPercent)),
                ButtonSegment(value: false, label: Text(l10n.promotionFixed)),
              ],
              selected: {_percentage},
              onSelectionChanged: (s) => setState(() => _percentage = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.promotionValue,
                suffixText: _percentage ? '%' : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.promotionAutoApply),
              subtitle: Text(l10n.promotionAutoApplyHint),
              value: _auto,
              onChanged: (v) => setState(() => _auto = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _valid
                    ? () => Navigator.of(context).pop(
                          PromotionDraft(
                            venueId: _venueId,
                            name: _name.text,
                            isPercentage: _percentage,
                            value: _amount!,
                            autoApply: _auto,
                          ),
                        )
                    : null,
                child: Text(l10n.promotionCreate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
