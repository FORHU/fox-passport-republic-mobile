import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// "New here? **Create an account**" — a muted prompt followed by a lime,
/// bold, un-underlined link (`docs/mobile-design.md` §3 "Text link").
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    required this.prompt,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$prompt ',
            style: AppTypography.body(size: 13, color: AppColors.textMuted),
          ),
          // 48px minimum touch target.
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    action,
                    style: AppTypography.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
