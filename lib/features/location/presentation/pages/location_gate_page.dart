import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Shown once, before the app is used: says why location helps and asks for
/// it. Choosing "Not now" is allowed, and the app then works from the city on
/// the profile; it is not asked again, but it can be turned on from
/// Settings.
class LocationGatePage extends ConsumerStatefulWidget {
  const LocationGatePage({super.key});

  @override
  ConsumerState<LocationGatePage> createState() => _LocationGatePageState();
}

class _LocationGatePageState extends ConsumerState<LocationGatePage> {
  bool _busy = false;

  Future<void> _finish() async {
    await ref.read(storageServiceProvider).setLocationPromptSeen();
    if (mounted) context.go(RouteNames.home);
  }

  Future<void> _allow() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final outcome = await ref.read(areaProvider.notifier).useDevice();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case LocateOutcome.ok:
        break;
      case LocateOutcome.denied:
        showTopToast(context, l10n.areaLocationDenied);
      case LocateOutcome.serviceOff:
        showTopToast(context, l10n.areaLocationOff);
      case LocateOutcome.failed:
        showTopToast(context, l10n.areaLocationFailed);
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTintBg,
                  border: Border.all(color: AppColors.accentTintBorder),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.locGateTitle,
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.locGateBody,
                textAlign: TextAlign.center,
                style: AppTypography.body(size: 15),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _busy ? null : _allow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onAccent,
                          ),
                        )
                      : Text(
                          l10n.locGateAllow,
                          style: AppTypography.display(
                            color: AppColors.onAccent,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _finish,
                child: Text(
                  l10n.locGateSkip,
                  style: AppTypography.body(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
