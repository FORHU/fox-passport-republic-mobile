import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// What / Where / When + "Find events": the web hero's `HeroSearch`, stacked
/// for a phone. Each row opens a bottom sheet (or the date picker) rather than
/// a native select, so it matches the rest of the app.
class HeroSearch extends StatefulWidget {
  const HeroSearch({this.cities = const [], super.key});

  /// Cities that have events, offered as quick picks under "Where".
  final List<String> cities;

  @override
  State<HeroSearch> createState() => _HeroSearchState();
}

class _HeroSearchState extends State<HeroSearch> {
  /// `value` is what the API filters on (`wedding`, `birthday`, …).
  String? _eventType;
  String? _city;
  DateTime? _date;

  static const _eventTypes = [
    'wedding',
    'birthday',
    'corporate',
    'social',
    'other',
  ];

  String _typeLabel(AppLocalizations l10n, String value) => switch (value) {
        'wedding' => l10n.homeEventWedding,
        'birthday' => l10n.homeEventBirthday,
        'corporate' => l10n.homeEventCorporate,
        'social' => l10n.homeEventSocial,
        _ => l10n.homeEventOther,
      };

  Future<void> _pickType() async {
    final l10n = context.l10n;
    final picked = await _pickFromList(
      title: l10n.homeSearchWhat,
      anyLabel: l10n.homeSearchAnyEvent,
      options: [for (final t in _eventTypes) (t, _typeLabel(l10n, t))],
      selected: _eventType,
    );
    if (picked != null) {
      setState(() => _eventType = picked.isEmpty ? null : picked);
    }
  }

  Future<void> _pickCity() async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CitySheet(
        title: l10n.homeSearchWhere,
        anyLabel: l10n.homeSearchAnyCity,
        hint: l10n.homeSearchCityHint,
        cities: widget.cities,
        selected: _city,
      ),
    );
    if (picked != null) setState(() => _city = picked.isEmpty ? null : picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<String?> _pickFromList({
    required String title,
    required String anyLabel,
    required List<(String, String)> options,
    required String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(title, style: AppTypography.display(size: 18)),
            ),
            _OptionTile(
              label: anyLabel,
              selected: selected == null,
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final (value, label) in options)
              _OptionTile(
                label: label,
                selected: selected == value,
                onTap: () => Navigator.of(context).pop(value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _find() {
    // The Search tab will read these when it is built; passing them now keeps
    // the hero's contract stable.
    context.go(
      RouteNames.search,
      extra: <String, Object?>{
        'type': _eventType,
        'city': _city,
        'date': _date?.toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _Field(
            label: l10n.homeSearchWhat,
            value: _eventType == null
                ? l10n.homeSearchAnyEvent
                : _typeLabel(l10n, _eventType!),
            isSet: _eventType != null,
            icon: Icons.expand_more_rounded,
            onTap: _pickType,
          ),
          const Divider(height: 1),
          _Field(
            label: l10n.homeSearchWhere,
            value: _city ?? l10n.homeSearchAnyCity,
            isSet: _city != null,
            icon: Icons.expand_more_rounded,
            onTap: _pickCity,
          ),
          const Divider(height: 1),
          _Field(
            label: l10n.homeSearchWhen,
            value: _date == null
                ? l10n.homeSearchAnyDate
                : DateFormat.yMMMd(Localizations.localeOf(context).toString())
                    .format(_date!),
            isSet: _date != null,
            icon: Icons.calendar_today_rounded,
            onTap: _pickDate,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _find,
                child: Text(l10n.homeSearchFind),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.isSet,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSet;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppTypography.label(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 15,
                        color: isSet
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: AppTypography.body(size: 15, color: AppColors.textPrimary),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.accent)
          : null,
      onTap: onTap,
    );
  }
}

class _CitySheet extends StatefulWidget {
  const _CitySheet({
    required this.title,
    required this.anyLabel,
    required this.hint,
    required this.cities,
    required this.selected,
  });

  final String title;
  final String anyLabel;
  final String hint;
  final List<String> cities;
  final String? selected;

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.selected ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(widget.title, style: AppTypography.display(size: 18)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              label: widget.anyLabel,
              selected: widget.selected == null,
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final city in widget.cities.take(8))
              _OptionTile(
                label: city,
                selected: widget.selected == city,
                onTap: () => Navigator.of(context).pop(city),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
