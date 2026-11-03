import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Opens the camera and gives back the code of the first QR it reads, or null
/// when the person backs out. A provider so tests need no camera.
typedef TicketScanner = Future<String?> Function(BuildContext context);

final Provider<TicketScanner> ticketScannerProvider =
    Provider<TicketScanner>((ref) {
  return (context) => Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const TicketScannerPage(),
        ),
      );
});

/// A full-screen camera that reads a ticket's QR code.
class TicketScannerPage extends StatefulWidget {
  const TicketScannerPage({super.key});

  @override
  State<TicketScannerPage> createState() => _TicketScannerPageState();
}

class _TicketScannerPageState extends State<TicketScannerPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        // One read is enough; the camera keeps firing while the page closes.
        _done = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas.withValues(alpha: 0.5),
        title: Text(
          l10n.checkInScanTitle,
          style: AppTypography.display(size: 18),
        ),
        actions: [
          IconButton(
            tooltip: l10n.checkInTorch,
            onPressed: () => unawaited(_controller.toggleTorch()),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraProblem(
              denied:
                  error.errorCode == MobileScannerErrorCode.permissionDenied,
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brCard,
                border: Border.all(color: AppColors.accent, width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.checkInScanHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the camera when it cannot be used.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.denied});

  final bool denied;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                denied ? l10n.checkInCameraDenied : l10n.checkInCameraFailed,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.checkInTypeInstead),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
