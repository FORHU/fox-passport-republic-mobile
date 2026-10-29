import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_application_controller.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Applying to be a Talent, Performer or Gear Foxer: what they offer, a few
/// details, and the documents an admin checks. One scrolling form.
class RoleApplicationPage extends ConsumerStatefulWidget {
  const RoleApplicationPage({required this.roleType, super.key});

  final String roleType;

  @override
  ConsumerState<RoleApplicationPage> createState() =>
      _RoleApplicationPageState();
}

class _RoleApplicationPageState extends ConsumerState<RoleApplicationPage> {
  Future<void> _submit() async {
    final l10n = context.l10n;
    final ok = await ref
        .read(roleApplicationProvider(widget.roleType).notifier)
        .submit();
    if (!mounted) return;
    if (!ok) {
      final why = ref.read(roleApplicationProvider(widget.roleType)).error;
      showTopToast(
        context,
        why == null || why.isEmpty ? l10n.roleApplyFailed : why,
      );
      return;
    }
    showTopToast(context, l10n.roleApplySent);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(roleApplicationProvider(widget.roleType));
    final controller =
        ref.read(roleApplicationProvider(widget.roleType).notifier);
    final d = state.draft;
    final title = roleCatalog
        .where((r) => r.roleType == widget.roleType)
        .map((r) => r.title)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          title ?? l10n.roleApplyTitle,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Card(
            title: l10n.roleApplyAbout,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.isGear)
                  _Field(
                    label: l10n.roleApplyBusiness,
                    value: d.businessName,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(businessName: v)),
                  ),
                _Field(
                  label: switch (widget.roleType) {
                    'gearFoxer' => l10n.roleApplyGearTypes,
                    'performerFoxer' => l10n.roleApplyPerformerTypes,
                    _ => l10n.roleApplyServiceTypes,
                  },
                  hint: l10n.roleApplyCommaHint,
                  value: d.types,
                  onChanged: (v) =>
                      controller.edit((x) => x.copyWith(types: v)),
                ),
                if (!d.isGear) ...[
                  _Field(
                    label: l10n.roleApplyExperience,
                    value: d.experience,
                    number: true,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(experience: v)),
                  ),
                  _Field(
                    label: l10n.roleApplyPortfolio,
                    hint: l10n.roleApplyCommaHint,
                    value: d.portfolio,
                    onChanged: (v) =>
                        controller.edit((x) => x.copyWith(portfolio: v)),
                  ),
                ],
                _Specializations(
                  options: specializationOptions(widget.roleType),
                  picked: d.specializations,
                  onToggle: controller.toggleSpecialization,
                ),
              ],
            ),
          ),
          _Card(
            title: l10n.roleApplyIds,
            hint: l10n.roleApplyIdsHint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!d.isGear)
                  _Field(
                    label: l10n.roleApplyNbiNumber,
                    value: d.nbiNumber,
                    number: true,
                    formatters: [LengthLimitingTextInputFormatter(18)],
                    onChanged: (v) => controller.edit(
                      (x) => x.copyWith(
                        nbiNumber: RoleApplicationDraft.digits(v, 18),
                      ),
                    ),
                  ),
                _Field(
                  label: l10n.roleApplyTin,
                  value: d.tinNumber,
                  number: true,
                  formatters: [LengthLimitingTextInputFormatter(9)],
                  onChanged: (v) => controller.edit(
                    (x) => x.copyWith(
                      tinNumber: RoleApplicationDraft.digits(v, 9),
                    ),
                  ),
                ),
                for (final slot in KycDocument.values)
                  _DocumentRow(
                    label: _documentLabel(l10n, slot),
                    photo: d.documents[slot],
                    onPicked: (p) => controller.setDocument(slot, p),
                    onRemove: () => controller.removeDocument(slot),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: AppButton(
              label: l10n.roleApplySubmit,
              isLoading: state.submitting,
              onPressed: d.isComplete ? _submit : null,
            ),
          ),
        ),
      ),
    );
  }
}

String _documentLabel(AppLocalizations l10n, KycDocument slot) =>
    switch (slot) {
      KycDocument.validId => l10n.roleApplyDocId,
      KycDocument.nbi => l10n.roleApplyDocNbi,
      KycDocument.tinId => l10n.roleApplyDocTin,
      KycDocument.birPermit => l10n.roleApplyDocBir,
      KycDocument.selfie => l10n.roleApplyDocSelfie,
    };

String specializationLabel(AppLocalizations l10n, String code) =>
    switch (code) {
      'design' => l10n.roleSpecDesign,
      'catering' => l10n.roleSpecCatering,
      'service_staff' => l10n.roleSpecStaff,
      'photography' => l10n.roleSpecPhotography,
      'videography' => l10n.roleSpecVideography,
      'dj' => l10n.roleSpecDj,
      'live_band' => l10n.roleSpecLiveBand,
      'mc' => l10n.roleSpecMc,
      'furnitures' => l10n.roleSpecFurniture,
      'sound_system' => l10n.roleSpecSound,
      'decorations' => l10n.roleSpecDecorations,
      _ => l10n.roleSpecOther,
    };

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.display()),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.number = false,
    this.formatters = const [],
  });

  final String label;
  final String? hint;
  final String value;
  final bool number;
  final List<TextInputFormatter> formatters;
  final ValueChanged<String> onChanged;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(text: widget.value);

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
          inputFormatters: widget.formatters,
          keyboardType: widget.number ? TextInputType.number : null,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.hint,
            helperMaxLines: 2,
          ),
          onChanged: widget.onChanged,
        ),
      );
}

class _Specializations extends StatelessWidget {
  const _Specializations({
    required this.options,
    required this.picked,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> picked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final full = picked.length >= RoleApplicationDraft.maxSpecializations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.roleApplySpecializations, style: AppTypography.label()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(specializationLabel(l10n, o)),
                selected: picked.contains(o),
                onSelected:
                    full && !picked.contains(o) ? null : (_) => onToggle(o),
              ),
          ],
        ),
      ],
    );
  }
}

class _DocumentRow extends ConsumerWidget {
  const _DocumentRow({
    required this.label,
    required this.photo,
    required this.onPicked,
    required this.onRemove,
  });

  final String label;
  final PickedPhoto? photo;
  final ValueChanged<PickedPhoto> onPicked;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final picked = photo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            picked == null
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_circle_rounded,
            color: picked == null ? AppColors.textMuted : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body()),
                if (picked != null)
                  Text(
                    picked.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (picked != null)
            IconButton(
              tooltip: l10n.roleApplyRemoveDoc,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () async {
              final p = await ref.read(photoPickerProvider).pick();
              if (p != null) onPicked(p);
            },
            child: Text(
              picked == null ? l10n.roleApplyChoose : l10n.roleApplyChange,
            ),
          ),
        ],
      ),
    );
  }
}
