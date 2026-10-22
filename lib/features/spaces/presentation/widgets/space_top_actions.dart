import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// What every space screen has in its top bar: the space switcher, and the
/// person's photo, which opens Settings (the way to Profile and Sign out, which
/// a space has no tab for).
class SpaceTopActions extends ConsumerWidget {
  const SpaceTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final name = user?.name ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpaceSwitchButton(),
        IconButton(
          tooltip: context.l10n.settingsTitle,
          onPressed: () => context.push(RouteNames.settings),
          icon: AvatarImage(
            url: user?.imageUrl,
            radius: 14,
            fallback: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppTypography.display(size: 12, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
