import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/citizen_profile_page.dart';
import 'package:flutter_template/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Your own profile: the same page others see when they open you (photo,
/// level, roles, bio, counts, stamps, badges and your posts), with your XP and
/// an Edit profile button, and your email, phone, followers and Sign out under
/// the card.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({this.activityBuilder, super.key});

  /// Your posts for the Activity tab. The route passes the Republic feed.
  final Widget Function(BuildContext context, CitizenProfile profile)?
      activityBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(
            context.l10n.profile,
            style: AppTypography.display(size: 18),
          ),
        ),
        // Signed out: the router is already leaving this page.
        body: const SizedBox.shrink(),
      );
    }
    return CitizenProfilePage(
      userId: me,
      activityBuilder: activityBuilder,
      ownerSection: const ProfileAccountSection(),
    );
  }
}
