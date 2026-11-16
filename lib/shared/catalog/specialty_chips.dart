import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';

/// The catalog's specialties as a row of chips, to narrow Foxers to those who
/// declared one. Tap the chosen chip again to drop it. Shows nothing while the
/// list loads or when it cannot, since what it filters works without it.
class SpecialtyChips extends ConsumerWidget {
  const SpecialtyChips({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(providerSpecialtiesProvider).asData?.value;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          for (final s in list)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.name),
                selected: s.slug == value,
                onSelected: (on) => onChanged(on ? s.slug : null),
              ),
            ),
        ],
      ),
    );
  }
}
