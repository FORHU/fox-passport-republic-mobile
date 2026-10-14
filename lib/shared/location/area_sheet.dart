import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// "Where are you?": use the device position, the profile city, or a city
/// typed in. Nothing here asks for a permission until a row is tapped.
Future<void> showAreaSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AreaSheet(),
  );
}

class _AreaSheet extends ConsumerStatefulWidget {
  const _AreaSheet();

  @override
  ConsumerState<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends ConsumerState<_AreaSheet> {
  final _controller = TextEditingController();
  bool _locating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useDevice() async {
    final l10n = context.l10n;
    setState(() => _locating = true);
    final outcome = await ref.read(areaProvider.notifier).useDevice();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (outcome) {
      case LocateOutcome.ok:
        Navigator.of(context).pop();
      case LocateOutcome.denied:
        showTopToast(context, l10n.areaLocationDenied);
      case LocateOutcome.serviceOff:
        showTopToast(context, l10n.areaLocationOff);
      case LocateOutcome.failed:
        showTopToast(context, l10n.areaLocationFailed);
    }
  }

  Future<void> _useProfile() async {
    await ref.read(areaProvider.notifier).useProfile();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _useTyped() async {
    final city = _controller.text.trim();
    if (city.isEmpty) return;
    await ref.read(areaProvider.notifier).useCity(city);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final area = ref.watch(areaProvider);
    final profileCity = ref.watch(profileCityProvider).value;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.areaTitle, style: AppTypography.display(size: 18)),
              const SizedBox(height: 12),
              _Option(
                icon: Icons.my_location_rounded,
                title: l10n.areaUseDevice,
                subtitle: l10n.areaUseDeviceHint,
                selected: area.source == AreaSource.device,
                busy: _locating,
                onTap: _locating ? null : _useDevice,
              ),
              if (profileCity != null) ...[
                const SizedBox(height: 8),
                _Option(
                  icon: Icons.home_outlined,
                  title: l10n.areaUseProfile(profileCity),
                  selected: area.source == AreaSource.profile,
                  onTap: _useProfile,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.areaOtherCity.toUpperCase(),
                style: AppTypography.label(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _useTyped(),
                      cursorColor: AppColors.accent,
                      style: AppTypography.body(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.areaOtherCityHint,
                        hintStyle:
                            AppTypography.body(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.brSm,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.brSm,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.brSm,
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _useTyped,
                      style: ElevatedButton.styleFrom(
                        // The app theme makes buttons full width; in a Row
                        // that is an infinite minimum, so size it here.
                        minimumSize: const Size(72, 48),
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                      child: Text(l10n.areaGo),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.brSm,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.display(size: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.body(size: 12)),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
