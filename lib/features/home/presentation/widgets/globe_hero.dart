import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/data/globe_stops_provider.dart';
import 'package:flutter_template/features/home/presentation/widgets/hero_search.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The web landing hero, for the phone: a full-bleed night-lights globe with
/// event pins and callout cards, and over it the kicker, the "Book the night,
/// anywhere." headline, one line of copy and the What / Where / When search.
class GlobeHero extends ConsumerWidget {
  const GlobeHero({this.userName, super.key});

  /// Shown in the kicker ("Welcome back, Ada"); null for a guest.
  final String? userName;

  /// Room kept under the globe for the text laid over its lower part.
  static const double _contentInset = 430;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stops = ref.watch(globeStopsProvider).value ?? const <GlobeStop>[];

    final first = userName?.trim().split(RegExp(r'\s+')).first ?? '';
    final kicker = first.isEmpty
        ? l10n.homeHeroKickerGuest
        : l10n.homeHeroKickerUser(first);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = (screenHeight * 0.96).clamp(720.0, 900.0);

    final headline = AppTypography.hero(size: 52);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: RotatingGlobe(
              stops: stops,
              bottomInset: _contentInset,
            ),
          ),
          // Legibility scrim: the globe fades into the canvas behind the text,
          // as the web's `from-canvas via-canvas/60` overlay does.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _contentInset + 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0002040A), AppColors.canvas],
                    stops: [0, 0.55],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kicker.toUpperCase(),
                  style: AppTypography.label(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(
                      style: headline,
                      children: [
                        TextSpan(
                          text: '${l10n.homeHeroBookThe.toUpperCase()}\n',
                        ),
                        TextSpan(
                          text: '${l10n.homeHeroNight.toUpperCase()},',
                          style: headline.copyWith(color: AppColors.accent),
                        ),
                        TextSpan(
                          text: '\n${l10n.homeHeroAnywhere.toUpperCase()}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.homeHeroBody,
                  style: AppTypography.body(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 20),
                HeroSearch(
                  cities: [for (final s in stops) s.city],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
