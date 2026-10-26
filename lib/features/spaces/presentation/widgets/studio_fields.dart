import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A text field for a studio form. It keeps its own cursor while the draft
/// behind it changes, and follows the draft when that is loaded or changed from
/// elsewhere.
class StudioField extends StatefulWidget {
  const StudioField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.number = false,
    this.formatters = const [],
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool number;

  /// Limits on what can be typed.
  final List<TextInputFormatter> formatters;

  @override
  State<StudioField> createState() => _StudioFieldState();
}

class _StudioFieldState extends State<StudioField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(StudioField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Not while the host is typing: the text already matches then.
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          inputFormatters: widget.formatters,
          keyboardType: widget.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: InputDecoration(labelText: widget.label),
          onChanged: widget.onChanged,
        ),
      );
}

/// Country, state and city as dropdowns that narrow down in turn, with a
/// button that fills them in from where the phone is. When the lists cannot be
/// loaded they fall back to plain text fields.
class PlaceFields extends StatelessWidget {
  const PlaceFields({
    required this.country,
    required this.state,
    required this.city,
    required this.countries,
    required this.states,
    required this.cities,
    required this.locating,
    required this.locateProblem,
    required this.onCountryText,
    required this.onStateText,
    required this.onCityText,
    required this.onPickCountry,
    required this.onPickState,
    required this.onUseMyLocation,
    super.key,
  });

  final String country;
  final String state;
  final String city;
  final List<PlaceOption> countries;
  final List<PlaceOption> states;
  final List<String> cities;
  final bool locating;

  /// `denied`, `off` or `failed`, or null.
  final String? locateProblem;

  /// For the text fields used when the lists could not be loaded; the city
  /// also takes a pick from its list.
  final ValueChanged<String> onCountryText;
  final ValueChanged<String> onStateText;
  final ValueChanged<String> onCityText;
  final ValueChanged<PlaceOption> onPickCountry;
  final ValueChanged<PlaceOption> onPickState;
  final VoidCallback onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String? problem;
    switch (locateProblem) {
      case 'denied':
        problem = l10n.studioLocateDenied;
      case 'off':
        problem = l10n.studioLocateOff;
      case 'failed':
        problem = l10n.studioLocateFailed;
    }

    if (countries.isEmpty) {
      return Column(
        children: [
          StudioField(
            label: l10n.studioCountry,
            value: country,
            onChanged: onCountryText,
          ),
          StudioField(
            label: l10n.studioState,
            value: state,
            onChanged: onStateText,
          ),
          StudioField(
            label: l10n.studioCity,
            value: city,
            onChanged: onCityText,
          ),
        ],
      );
    }

    // A city the phone found, or one saved on the web, may not be in the list.
    final cityOptions = [
      ...cities,
      if (city.isNotEmpty && !cities.contains(city)) city,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: locating ? null : onUseMyLocation,
          icon: locating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(l10n.studioUseMyLocation),
        ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              problem,
              style: AppTypography.body(size: 13, color: AppColors.warning),
            ),
          ),
        const SizedBox(height: 16),
        _PlaceMenu(
          label: l10n.studioCountry,
          value: country,
          options: [for (final c in countries) c.name],
          onPicked: (name) =>
              onPickCountry(countries.firstWhere((c) => c.name == name)),
        ),
        if (states.isNotEmpty)
          _PlaceMenu(
            label: l10n.studioState,
            value: state,
            options: [for (final s in states) s.name],
            onPicked: (name) =>
                onPickState(states.firstWhere((s) => s.name == name)),
          ),
        if (country.isNotEmpty)
          if (cityOptions.isNotEmpty)
            _PlaceMenu(
              label: l10n.studioCity,
              value: city,
              options: cityOptions,
              onPicked: onCityText,
            )
          else
            StudioField(
              label: l10n.studioCity,
              value: city,
              onChanged: onCityText,
            ),
      ],
    );
  }
}

/// A dropdown you can type into to narrow a long list.
class _PlaceMenu extends StatelessWidget {
  const _PlaceMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.onPicked,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownMenu<String>(
          // Rebuilt when the value is set from elsewhere, such as the phone's
          // position, or the list changes under it.
          key: ValueKey('$label|$value|${options.length}'),
          label: Text(label),
          initialSelection: options.contains(value) ? value : null,
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          menuHeight: 280,
          dropdownMenuEntries: [
            for (final o in options) DropdownMenuEntry(value: o, label: o),
          ],
          onSelected: (v) {
            if (v != null) onPicked(v);
          },
        ),
      );
}
