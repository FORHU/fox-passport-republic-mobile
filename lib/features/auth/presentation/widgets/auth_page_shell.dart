import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/widgets/brand_logo.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Shared chrome for every auth screen (`docs/mobile-design.md` §5):
/// `canvas` background and no card; a small centred "FoxPassport" wordmark at
/// the top (with a back arrow when the screen isn't the first in the stack);
/// then, pushed toward the thumb, a lime eyebrow, the hero headline, an
/// optional line of body copy and the form. Scrolls when the keyboard is open.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    required this.eyebrow,
    required this.headline,
    required this.child,
    this.body,
    this.onBack,
    super.key,
  });

  /// Small uppercase lime label above the headline ("Welcome back").
  final String eyebrow;

  /// The one hero headline of the screen.
  final String headline;

  /// One short line under the headline, in `textSecondary`.
  final String? body;

  /// Shows a back arrow beside the wordmark when set.
  final VoidCallback? onBack;

  /// The form.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                AppSpacing.sm,
                20,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    minHeight:
                        constraints.maxHeight - AppSpacing.sm - AppSpacing.lg,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Wordmark(onBack: onBack),
                        // The leftover height is split 1 : 2 above and below
                        // the form, so it sits in the upper-middle of the
                        // screen instead of being pushed to the bottom with
                        // a big empty gap under the wordmark.
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: _Content(
                            eyebrow: eyebrow,
                            headline: headline,
                            body: body,
                            child: child,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FoxLogo(size: 28),
              const SizedBox(width: 10),
              Text(
                context.l10n.authWordmark,
                style: AppTypography.display(size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.eyebrow,
    required this.headline,
    required this.child,
    this.body,
  });

  final String eyebrow;
  final String headline;
  final String? body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTypography.label(color: AppColors.accent),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            headline.toUpperCase(),
            style: AppTypography.hero(),
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 14),
          Text(body!, style: AppTypography.body(size: 15)),
        ],
        const SizedBox(height: 22),
        child,
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
