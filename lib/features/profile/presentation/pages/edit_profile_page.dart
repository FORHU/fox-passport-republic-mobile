import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_update.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/shared/widgets/app_input.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Edit the profile: photo, name, username, phone and whether it is private.
/// Only what changed is sent.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  bool _private = false;
  bool _saving = false;
  bool _uploading = false;

  /// The fields are filled once the full profile is in (or has failed to
  /// load, when the session's name and username stand in), so the phone and
  /// privacy are never shown blank for someone who has them.
  bool _seeded = false;

  void _seed(ProfileEntity? profile, UserEntity? user) {
    _name.text = profile?.name ?? user?.name ?? '';
    _username.text = profile?.username ?? user?.username ?? '';
    _phone.text = profile?.phone ?? '';
    _private = profile?.isPrivate ?? false;
    _seeded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (_uploading) return;
    final l10n = context.l10n;
    final photo = await ref.read(photoPickerProvider).pick();
    if (photo == null || !mounted) return;
    setState(() => _uploading = true);
    final error =
        await ref.read(profileControllerProvider.notifier).changePhoto(photo);
    if (!mounted) return;
    setState(() => _uploading = false);
    showTopToast(
      context,
      error == null
          ? l10n.profilePhotoUpdated
          : error.isEmpty
              ? l10n.profilePhotoFailed
              : error,
    );
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final profile = ref.read(profileControllerProvider).profile;
    final user = ref.read(authControllerProvider).user;

    final name = _name.text.trim();
    final username = _username.text.trim();
    final phone = _phone.text.trim();
    final update = ProfileUpdate(
      name: name == (profile?.name ?? user?.name) ? null : name,
      username:
          username == (profile?.username ?? user?.username) ? null : username,
      phone: phone == (profile?.phone ?? '') ? null : phone,
      isPrivate: _private == (profile?.isPrivate ?? false) ? null : _private,
    );
    if (update.toJson().isEmpty) {
      router.pop();
      return;
    }

    setState(() => _saving = true);
    final error = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(update);
    if (!mounted) return;
    if (error == null) {
      showTopToast(context, l10n.profileUpdated);
      router.pop();
      return;
    }
    setState(() => _saving = false);
    showTopToast(context, error.isEmpty ? l10n.profileUpdateFailed : error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authControllerProvider).user;
    final state = ref.watch(profileControllerProvider);
    if (!_seeded && (state.profile != null || state.error != null)) {
      _seed(state.profile, user);
    }
    if (!_seeded) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(l10n.profileEdit, style: AppTypography.display(size: 18)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }
    final photo = state.profile?.imageUrl;
    final name = _name.text.trim().isNotEmpty ? _name.text : user?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.profileEdit, style: AppTypography.display(size: 18)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AvatarImage(
                        url: photo ?? user?.imageUrl,
                        radius: 48,
                        fallback: Text(
                          name.isEmpty
                              ? '?'
                              : name.characters.first.toUpperCase(),
                          style: AppTypography.display(
                            size: 34,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      if (_uploading)
                        const CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _uploading ? null : _changePhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(l10n.profileChangePhoto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppInput(
              label: l10n.profileNameLabel,
              controller: _name,
              prefixIcon: Icons.badge_outlined,
              validator: Validators.signupName,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.profileUsernameLabel,
              controller: _username,
              prefixIcon: Icons.alternate_email_rounded,
              validator: Validators.signupUsername,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: l10n.profilePhoneLabel,
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profilePrivateTitle,
                          style: AppTypography.display(size: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.profilePrivateBody,
                          style: AppTypography.body(size: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _private,
                    activeThumbColor: AppColors.onAccent,
                    activeTrackColor: AppColors.accent,
                    onChanged: (v) => setState(() => _private = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.profileSave,
              isLoading: _saving,
              onPressed: _saving ? null : () => unawaited(_save()),
            ),
          ],
        ),
      ),
    );
  }
}
