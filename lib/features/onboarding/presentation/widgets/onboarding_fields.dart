import 'package:flutter/material.dart';
import 'package:flutter_template/features/onboarding/presentation/theme/onboarding_palette.dart';

/// `text-xs font-bold uppercase tracking-wider text-white/60` field label.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {this.required = false, this.hint, super.key});

  final String text;
  final bool required;

  /// Muted trailing note, e.g. "— optional".
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          style: OnboardingPalette.body(
            size: 12,
            weight: FontWeight.w800,
            color: OnboardingPalette.white(0.6),
            letterSpacing: 1,
          ),
          children: [
            TextSpan(text: text.toUpperCase()),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: OnboardingPalette.accent),
              ),
            if (hint != null)
              TextSpan(
                text: ' $hint',
                style: TextStyle(
                  color: OnboardingPalette.white(0.3),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoration({
  required String hint,
  required IconData? icon,
  bool enabled = true,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: OnboardingPalette.body(
      size: 15,
      color: OnboardingPalette.white(0.3),
    ),
    filled: true,
    fillColor: OnboardingPalette.white(enabled ? 0.05 : 0.03),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 20, color: OnboardingPalette.white(0.4)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(OnboardingPalette.white(0.1)),
    enabledBorder: border(OnboardingPalette.white(0.1)),
    disabledBorder: border(OnboardingPalette.white(0.06)),
    focusedBorder: border(OnboardingPalette.accent.withValues(alpha: 0.5)),
  );
}

/// Dark text input with a leading icon (the web's `inputClass`).
class OnboardingTextField extends StatelessWidget {
  const OnboardingTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      cursorColor: OnboardingPalette.accent,
      style: OnboardingPalette.body(size: 15, color: Colors.white),
      decoration: _decoration(hint: hint, icon: icon, enabled: enabled),
    );
  }
}

/// A read-only field that opens a searchable list in a bottom sheet — the
/// phone form of the web's `SearchableDropdown`.
///
/// With [allowCustom] the user may also use text that isn't in [options] (a
/// city missing from the dataset can still be typed in).
class SearchableSelectField extends StatelessWidget {
  const SearchableSelectField({
    required this.value,
    required this.placeholder,
    required this.searchHint,
    required this.options,
    required this.onSelected,
    this.icon,
    this.enabled = true,
    this.allowCustom = false,
    this.loading = false,
    super.key,
  });

  final String value;
  final String placeholder;
  final String searchHint;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final IconData? icon;
  final bool enabled;
  final bool allowCustom;
  final bool loading;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnboardingPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OptionSheet(
        title: placeholder,
        searchHint: searchHint,
        options: options,
        selected: value,
        allowCustom: allowCustom,
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return Semantics(
      button: true,
      enabled: enabled,
      label: placeholder,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? () => _open(context) : null,
        child: InputDecorator(
          isEmpty: !hasValue,
          decoration: _decoration(
            hint: '',
            icon: icon,
            enabled: enabled,
          ).copyWith(
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: OnboardingPalette.accent,
                      ),
                    ),
                  )
                : Icon(
                    Icons.expand_more_rounded,
                    color: OnboardingPalette.white(0.4),
                  ),
          ),
          child: Text(
            hasValue ? value : placeholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OnboardingPalette.body(
              size: 15,
              color: hasValue
                  ? Colors.white
                  : OnboardingPalette.white(enabled ? 0.3 : 0.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    required this.selected,
    required this.allowCustom,
  });

  final String title;
  final String searchHint;
  final List<String> options;
  final String selected;
  final bool allowCustom;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.options
        : widget.options.where((o) => o.toLowerCase().contains(q)).toList();
    final exact = widget.options.any((o) => o.toLowerCase() == q);
    final canUseCustom = widget.allowCustom && q.isNotEmpty && !exact;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: OnboardingPalette.white(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  cursorColor: OnboardingPalette.accent,
                  style: OnboardingPalette.body(size: 15, color: Colors.white),
                  decoration: _decoration(
                    hint: widget.searchHint,
                    icon: Icons.search_rounded,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    if (canUseCustom)
                      ListTile(
                        leading: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: OnboardingPalette.accent,
                        ),
                        title: Text(
                          'Use "${_query.trim()}"',
                          style: OnboardingPalette.body(
                            size: 15,
                            weight: FontWeight.w700,
                            color: OnboardingPalette.accent,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(_query.trim()),
                      ),
                    for (final option in filtered)
                      ListTile(
                        title: Text(
                          option,
                          style: OnboardingPalette.body(
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                        trailing: option == widget.selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: OnboardingPalette.accent,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(option),
                      ),
                    if (filtered.isEmpty && !canUseCustom)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No matches',
                            style: OnboardingPalette.body(
                              color: OnboardingPalette.white(0.4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
