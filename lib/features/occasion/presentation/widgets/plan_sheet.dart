import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// How many guests, as the four ranges the design offers.
enum GuestRange {
  upTo20(20),
  to50(50),
  to100(100),
  over100(100);

  const GuestRange(this.minCapacity);

  /// The capacity a place needs to hold this many guests.
  final int minCapacity;
}

/// What the person picked in the sheet.
class PlanChoice {
  const PlanChoice({this.date, this.guests});

  final DateTime? date;
  final GuestRange? guests;
}

/// One sheet for "Add date" and "Guests": a month calendar and the guest
/// ranges. Closing it by the button returns the choice; dismissing it keeps
/// what was there.
Future<PlanChoice?> showPlanSheet(
  BuildContext context, {
  PlanChoice initial = const PlanChoice(),
}) {
  return showModalBottomSheet<PlanChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (_) => _PlanSheet(initial: initial),
  );
}

class _PlanSheet extends StatefulWidget {
  const _PlanSheet({required this.initial});

  final PlanChoice initial;

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late DateTime? _date = widget.initial.date;
  late GuestRange? _guests = widget.initial.guests;

  String _label(BuildContext context, GuestRange range) {
    final l10n = context.l10n;
    return switch (range) {
      GuestRange.upTo20 => l10n.guestsUpTo20,
      GuestRange.to50 => l10n.guests20to50,
      GuestRange.to100 => l10n.guests50to100,
      GuestRange.over100 => l10n.guests100plus,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.planWhen, style: AppTypography.display(size: 18)),
          CalendarDatePicker(
            initialDate: _date ?? first,
            firstDate: first,
            lastDate: first.add(const Duration(days: 730)),
            onDateChanged: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: 8),
          Text(l10n.planGuests, style: AppTypography.display(size: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final range in GuestRange.values)
                ChoiceChip(
                  label: Text(_label(context, range)),
                  selected: _guests == range,
                  onSelected: (on) =>
                      setState(() => _guests = on ? range : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                PlanChoice(date: _date, guests: _guests),
              ),
              child: Text(l10n.planApply),
            ),
          ),
        ],
      ),
    );
  }
}
