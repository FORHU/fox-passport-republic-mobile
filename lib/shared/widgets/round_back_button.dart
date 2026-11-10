import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// A circular back button with a hairline border, for an app bar's `leading`
/// (give the bar a `leadingWidth` of 64). Goes back like the usual one.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
