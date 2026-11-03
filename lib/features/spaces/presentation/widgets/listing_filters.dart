import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The order the status filters come in: what is live first, then what is
/// still waiting on something.
const listingGroupOrder = ['live', 'pending', 'draft', 'rejected', 'archived'];

/// The name of a status group (see `SpaceListing.group`) as the person reads
/// it.
String listingGroupLabel(AppLocalizations l10n, String group) =>
    switch (group) {
      'live' => l10n.listingStatusLive,
      'pending' => l10n.listingStatusPending,
      'rejected' => l10n.listingStatusRejected,
      'archived' => l10n.listingStatusArchived,
      _ => l10n.listingStatusDraft,
    };

/// A search box for a list of the person's own venues or events, with a clear
/// button once something is typed.
class ListingSearchField extends StatelessWidget {
  const ListingSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.venuesSearchClear,
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
      ),
    );
  }
}

/// A row of status filters with counts: All, then each status that is present.
/// Draws nothing when everything is in one status, since there is nothing to
/// choose between.
class ListingFilterBar extends StatelessWidget {
  const ListingFilterBar({
    required this.counts,
    required this.total,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// How many there are in each status group.
  final Map<String, int> counts;
  final int total;

  /// The group being shown; null is all of them.
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (counts.length < 2) return const SizedBox.shrink();
    final l10n = context.l10n;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: l10n.venuesFilterAll(total),
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final group in listingGroupOrder)
            if (counts.containsKey(group))
              _Chip(
                label: '${listingGroupLabel(l10n, group)} ${counts[group]}',
                selected: selected == group,
                onTap: () => onSelected(group),
              ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.accent,
          labelStyle: AppTypography.label(
            color: selected ? AppColors.onAccent : AppColors.textPrimary,
          ),
        ),
      );
}
