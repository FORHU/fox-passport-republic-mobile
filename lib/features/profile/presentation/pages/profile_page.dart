import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/sign_out.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Who you are on FoxPassport: name, email, when you joined, and the two
/// things you do with an account here, rename it and sign out.
///
/// Backed by [ProfileController]. While the full profile loads, or if it
/// fails, the name and email of the signed-in session are shown instead.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final state = ref.watch(profileControllerProvider);
    final sessionUser = ref.watch(authControllerProvider).user;

    final name = state.profile?.name ?? sessionUser?.name ?? '';
    final email = state.profile?.email ?? sessionUser?.email ?? '';
    final joinedAt = state.profile?.joinedAt;
    final bio = state.profile?.bio;
    final loadFailed = state.error != null && state.profile == null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.profile, style: AppTypography.display(size: 18)),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () =>
            ref.read(profileControllerProvider.notifier).fetchProfile(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: _Avatar(name: name, imageUrl: sessionUser?.imageUrl)),
            const SizedBox(height: 16),
            if (name.isNotEmpty)
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 24),
              ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
            ],
            if (joinedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profileMemberSince(
                  DateFormat.yMMMM(locale).format(joinedAt.toLocal()),
                ),
                textAlign: TextAlign.center,
                style: AppTypography.label(),
              ),
            ],
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
            ],
            if (state.isLoading && state.profile == null) ...[
              const SizedBox(height: 20),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
            if (loadFailed) ...[
              const SizedBox(height: 20),
              Text(
                l10n.profileLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.warning),
              ),
              Center(
                child: TextButton(
                  onPressed: () => ref
                      .read(profileControllerProvider.notifier)
                      .fetchProfile(),
                  child: Text(l10n.retry),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SecondaryButton(
              label: l10n.profileEditName,
              icon: Icons.edit_outlined,
              onPressed:
                  name.isEmpty ? null : () => _editName(context, ref, name),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text(
                l10n.settingsSignOut,
                style: const TextStyle(color: AppColors.error),
              ),
              onPressed: () => confirmSignOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _EditNameSheet(current: current),
    );
    if (saved == true && context.mounted) {
      showTopToast(context, context.l10n.profileNameUpdated);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.surface,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppTypography.display(size: 32, color: AppColors.accent),
            ),
    );
  }
}

class _EditNameSheet extends ConsumerStatefulWidget {
  const _EditNameSheet({required this.current});

  final String current;

  @override
  ConsumerState<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<_EditNameSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.current);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final failed = context.l10n.profileNameUpdateFailed;
    setState(() => _saving = true);
    final error = await ref.read(profileControllerProvider.notifier).updateName(
          _name.text,
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _saving = false);
    showTopToast(context, error.isEmpty ? failed : error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileEditName, style: AppTypography.display(size: 18)),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.profileNameLabel,
              controller: _name,
              validator: Validators.signupName,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.profileSave,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
