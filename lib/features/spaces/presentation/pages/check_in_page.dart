import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/presentation/pages/ticket_scanner_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Checks a guest in by the code on their ticket. Event Owners, their
/// Organizers and Check-in Helpers, and a Venue's staff on the day can do it;
/// the server decides who may check in which booking.
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _checking = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    if (_checking || !(_form.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    setState(() => _checking = true);
    String message;
    try {
      final result =
          await ref.read(spacesRepositoryProvider).checkIn(_code.text);
      message = result.message ?? l10n.checkInDone;
      _code.clear();
    } on AppException catch (e) {
      message = e.message.isEmpty ? l10n.checkInFailed : e.message;
    } on Object {
      message = l10n.checkInFailed;
    }
    if (!mounted) return;
    setState(() => _checking = false);
    showTopToast(context, message);
  }

  /// Opens the camera; a code it reads is checked in straight away.
  Future<void> _scan() async {
    if (_checking) return;
    final code = await ref.read(ticketScannerProvider)(context);
    if (code == null || !mounted) return;
    _code.text = code;
    await _checkIn();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.checkInTitle),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(l10n.checkInIntro, style: AppTypography.body(size: 13)),
            const SizedBox(height: 20),
            SecondaryButton(
              label: l10n.checkInScan,
              icon: Icons.qr_code_scanner_rounded,
              onPressed: _checking ? null : _scan,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.checkInCodeLabel,
              controller: _code,
              prefixIcon: Icons.confirmation_number_outlined,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.checkInCodeLabel : null,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.checkInAction,
              icon: Icons.check_circle_outline_rounded,
              isLoading: _checking,
              onPressed: _checking ? null : _checkIn,
            ),
          ],
        ),
      ),
    );
  }
}
