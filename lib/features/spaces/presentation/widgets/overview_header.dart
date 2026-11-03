import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

const _foxerRoles = {
  'venueFoxer',
  'eventFoxer',
  'gearFoxer',
  'serviceFoxer',
  'performerFoxer',
};

/// The top of a space's Overview: a greeting by first name, and the role the
/// person is acting as, with a count of the other Foxer roles they hold. The
/// chip only says which role this is: switching space lives in More, not here.
class OverviewGreeting extends ConsumerWidget {
  const OverviewGreeting({
    required this.roleLabel,
    required this.roleColor,
    super.key,
  });

  /// The role's name, such as "Venue Foxer".
  final String roleLabel;

  /// The role's colour, shown as a dot on the chip only.
  final Color roleColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = ref.watch(authControllerProvider).user?.name.trim() ?? '';
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final others =
        ref.watch(heldRolesProvider).where(_foxerRoles.contains).length - 1;
    final hour = DateTime.now().hour;
    final greeting = first.isEmpty
        ? l10n.overviewGreetingNoName
        : hour < 12
            ? l10n.overviewGreetingMorning(first)
            : hour < 18
                ? l10n.overviewGreetingAfternoon(first)
                : l10n.overviewGreetingEvening(first);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(size: 22),
          ),
          const SizedBox(height: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  roleLabel,
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (others > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+$others',
                    style: AppTypography.body(
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
