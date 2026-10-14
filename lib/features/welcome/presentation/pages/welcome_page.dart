import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// First-launch welcome carousel, shown once before sign-in
/// (`docs/mobile-design.md` §4 · mockup `docs/mockups/onboarding-auth.html`).
///
/// This is the phone version of the web's `WelcomeGuide`. It is not the
/// Profile → Interests → Roles flow, which needs a signed-in user and runs
/// after sign-in.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  static const _slideCount = 6;
  static const _slideDuration = Duration(milliseconds: 280);

  final _controller = PageController();
  int _index = 0;

  bool get _isFirst => _index == 0;
  bool get _isLast => _index == _slideCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goTo(int page) => _controller.animateToPage(
        page,
        duration: _slideDuration,
        curve: Curves.easeOutCubic,
      );

  /// Leaving the carousel marks it seen, so it is never shown again.
  Future<void> _finish(String route) async {
    await ref.read(storageServiceProvider).setWelcomeSeen();
    if (mounted) context.go(route);
  }

  void _onPrimary() =>
      _isLast ? _finish(RouteNames.register) : _goTo(_index + 1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = _slides(l10n);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          _backdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopRow(
                        index: _index,
                        total: _slideCount,
                        skipLabel: l10n.welcomeSkip,
                        showSkip: !_isLast,
                        onSkip: () => _goTo(_slideCount - 1),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: slides.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (_, i) => _SlideView(slide: slides[i]),
                        ),
                      ),
                      _Dots(count: _slideCount, active: _index),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: slides[_index].button,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _onPrimary,
                      ),
                      const SizedBox(height: 8),
                      // Fixed height so the button does not jump between
                      // slides.
                      SizedBox(
                        height: 48,
                        // Links are Flexible so a long translation shrinks
                        // (with an ellipsis) instead of overflowing a narrow
                        // phone.
                        child: Row(
                          mainAxisAlignment: (!_isFirst && _isLast)
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.center,
                          children: [
                            if (!_isFirst)
                              Flexible(
                                child: _MutedLink(
                                  label: l10n.welcomeBackAction,
                                  onTap: () => _goTo(_index - 1),
                                ),
                              ),
                            if (_isLast)
                              Flexible(
                                flex: 2,
                                child: _MutedLink(
                                  label: l10n.welcomeHaveAccount,
                                  onTap: () => _finish(RouteNames.login),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 1's backdrop: the hero's night-lights globe, edge to edge, fading
  /// into the canvas behind the text. Removed (with a fade) once the user
  /// moves on, so no web view keeps rendering off-screen.
  Widget _backdrop() {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isFirst
            ? const _GlobeBackdrop(key: ValueKey('globe'))
            : const SizedBox.expand(key: ValueKey('none')),
      ),
    );
  }

  /// Copy is the web's `WelcomeGuide`, verbatim (spec §4).
  List<_Slide> _slides(AppLocalizations l10n) => [
        _Slide(
          icon: null, // slide 1 shows the spinning globe
          eyebrow: l10n.welcome1Eyebrow,
          headline: l10n.welcome1Headline,
          body: l10n.welcome1Body,
          button: l10n.welcome1Button,
        ),
        _Slide(
          icon: Icons.explore_outlined,
          eyebrow: l10n.welcome2Eyebrow,
          headline: l10n.welcome2Headline,
          body: l10n.welcome2Body,
          button: l10n.welcome2Button,
        ),
        _Slide(
          icon: Icons.handshake_outlined,
          eyebrow: l10n.welcome3Eyebrow,
          headline: l10n.welcome3Headline,
          body: l10n.welcome3Body,
          button: l10n.welcome3Button,
          chips: [
            _RoleChip(l10n.welcomeRoleEvent, AppColors.roleEvent),
            _RoleChip(l10n.welcomeRoleVenue, AppColors.roleVenue),
            _RoleChip(l10n.welcomeRoleGear, AppColors.roleGear),
            _RoleChip(l10n.welcomeRoleTalent, AppColors.roleTalent),
            _RoleChip(l10n.welcomeRolePerformer, AppColors.rolePerformer),
          ],
        ),
        _Slide(
          icon: Icons.workspace_premium_outlined,
          eyebrow: l10n.welcome4Eyebrow,
          headline: l10n.welcome4Headline,
          body: l10n.welcome4Body,
          button: l10n.welcome4Button,
        ),
        _Slide(
          icon: Icons.groups_outlined,
          eyebrow: l10n.welcome5Eyebrow,
          headline: l10n.welcome5Headline,
          body: l10n.welcome5Body,
          button: l10n.welcome5Button,
        ),
        _Slide(
          icon: Icons.rocket_launch_outlined,
          eyebrow: l10n.welcome6Eyebrow,
          headline: l10n.welcome6Headline,
          body: l10n.welcome6Body,
          button: l10n.welcome6Button,
        ),
      ];
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.eyebrow,
    required this.headline,
    required this.body,
    required this.button,
    this.chips = const [],
  });

  final IconData? icon;
  final String eyebrow;
  final String headline;
  final String body;
  final String button;
  final List<_RoleChip> chips;
}

class _RoleChip {
  const _RoleChip(this.label, this.color);

  final String label;
  final Color color;
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.index,
    required this.total,
    required this.skipLabel,
    required this.showSkip,
    required this.onSkip,
  });

  final int index;
  final int total;
  final String skipLabel;
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${index + 1} / $total',
            style: AppTypography.label(),
          ),
          // Hidden (not removed) on the last slide so the row keeps its size.
          Visibility(
            visible: showSkip,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _MutedLink(label: skipLabel, onTap: onSkip),
          ),
        ],
      ),
    );
  }
}

class _MutedLink extends StatelessWidget {
  const _MutedLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Center(
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    // Centred when it fits; scrolls on a short screen or with large text
    // instead of overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    // Slide 1 sits low, under the globe behind it; the others are centred.
    final overGlobe = slide.icon == null;
    return Column(
      mainAxisAlignment:
          overGlobe ? MainAxisAlignment.end : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!overGlobe)
          Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.accentTintBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentTintBorder),
            ),
            alignment: Alignment.center,
            child: Icon(slide.icon, size: 32, color: AppColors.accent),
          ),
        Text(
          slide.eyebrow.toUpperCase(),
          style: AppTypography.label(color: AppColors.accent),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            slide.headline.toUpperCase(),
            style: AppTypography.hero(),
          ),
        ),
        const SizedBox(height: 16),
        Text(slide.body, style: AppTypography.body(size: 15)),
        if (slide.chips.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final c in slide.chips) _Chip(chip: c)],
          ),
        ],
        // Keep the copy clear of the page dots when it sits at the bottom.
        if (overGlobe) const SizedBox(height: 28),
      ],
    );
  }
}

/// Pill with a 1px border and text in the role's colour. Never a button.
class _Chip extends StatelessWidget {
  const _Chip({required this.chip});

  final _RoleChip chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chip.color),
      ),
      child: Text(
        chip.label,
        style: AppTypography.body(
          size: 12,
          color: chip.color,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? AppColors.accent : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// The globe behind slide 1, with a scrim so the copy reads over it.
class _GlobeBackdrop extends StatelessWidget {
  const _GlobeBackdrop({super.key});

  /// Space kept clear of globe at the bottom for the copy and the button.
  static const double _textInset = 380;

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        RotatingGlobe(bottomInset: _textInset),
        // The same legibility scrim the Home hero uses.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _textInset + 60,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.canvasClear, AppColors.canvas],
                  stops: [0, 0.6],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
