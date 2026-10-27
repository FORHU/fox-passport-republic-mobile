import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/profile/data/identity_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/identity_status.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// The optional ID check: send a government ID (and a selfie if you like) and
/// an admin reviews it. Approval earns a Verified badge; booking never needs
/// it.
class IdentityPage extends ConsumerWidget {
  const IdentityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(identityStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.identityTitle, style: AppTypography.display(size: 18)),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.identityLoadFailed,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              TextButton(
                onPressed: () => ref.invalidate(identityStatusProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (status) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (status.isVerified)
              _Note(
                icon: Icons.verified_rounded,
                color: AppColors.accent,
                text: l10n.identityVerified,
              )
            else if (status.isPending)
              _Note(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                text: l10n.identityPending(_when(context, status.latest)),
              )
            else ...[
              if (status.latest?.status == 'rejected')
                _Note(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.error,
                  text: status.latest?.rejectionReason == null
                      ? l10n.identityRejected
                      : l10n.identityRejectedWhy(
                          status.latest!.rejectionReason!,
                        ),
                ),
              const _SubmitForm(),
            ],
          ],
        ),
      ),
    );
  }

  static String _when(BuildContext context, IdentitySubmission? latest) {
    final at = latest?.createdAt;
    if (at == null) return '';
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(at);
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTypography.body(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
}

class _SubmitForm extends ConsumerStatefulWidget {
  const _SubmitForm();

  @override
  ConsumerState<_SubmitForm> createState() => _SubmitFormState();
}

class _SubmitFormState extends ConsumerState<_SubmitForm> {
  IdType _type = IdType.passport;
  PickedPhoto? _id;
  PickedPhoto? _selfie;
  bool _busy = false;

  Future<void> _pick({required bool selfie}) async {
    final photo = await ref.read(photoPickerProvider).pick();
    if (photo == null || !mounted) return;
    setState(() => selfie ? _selfie = photo : _id = photo);
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final id = _id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(identityRepositoryProvider)
          .submit(type: _type, id: id, selfie: _selfie);
      ref.invalidate(identityStatusProvider);
      if (mounted) showTopToast(context, l10n.identitySent);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showTopToast(
          context,
          e is AppException ? e.message : l10n.identityFailed,
        );
      }
    }
  }

  String _label(AppLocalizations l10n, IdType type) => switch (type) {
        IdType.passport => l10n.identityTypePassport,
        IdType.driversLicense => l10n.identityTypeLicense,
        IdType.nationalId => l10n.identityTypeNational,
        IdType.other => l10n.identityTypeOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.identityIntro, style: AppTypography.body()),
        const SizedBox(height: 20),
        Text(l10n.identityKind, style: AppTypography.label()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final type in IdType.values)
              ChoiceChip(
                label: Text(_label(l10n, type)),
                selected: _type == type,
                onSelected: _busy ? null : (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _PhotoRow(
          label: l10n.identityIdPhoto,
          chosen: _id,
          onPick: _busy ? null : () => _pick(selfie: false),
        ),
        const SizedBox(height: 8),
        _PhotoRow(
          label: l10n.identitySelfie,
          chosen: _selfie,
          onPick: _busy ? null : () => _pick(selfie: true),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _busy || _id == null ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            ),
            child: Text(l10n.identitySubmit),
          ),
        ),
      ],
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.label,
    required this.chosen,
    required this.onPick,
  });

  final String label;
  final PickedPhoto? chosen;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photo = chosen;
    return OutlinedButton.icon(
      onPressed: onPick,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(
        photo == null
            ? Icons.add_a_photo_outlined
            : Icons.check_circle_outline_rounded,
      ),
      label: Text(photo == null ? label : '$label · ${l10n.identityChosen}'),
    );
  }
}
