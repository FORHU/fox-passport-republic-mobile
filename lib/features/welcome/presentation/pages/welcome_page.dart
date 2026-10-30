import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/welcome/presentation/widgets/reel_scenes.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// First-launch welcome reel, shown once before sign-in
/// (`docs/mobile-design.md` §4).
///
/// Three scenes play on their own, round and round, above a still panel with
/// the words. Tap (left third back, anywhere else on), swipe or use the arrow
/// keys to move, and hold a finger down to pause. Creating an account and
/// logging in are on screen the whole time. It is not the Profile → Interests
/// → Roles flow, which needs a signed-in user and runs after sign-in.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _sceneCount = ReelScene.sceneCount;

  // Long enough to read the copy before the scene moves on.
  static const _sceneDuration = Duration(milliseconds: 6500);
  static const _fade = Duration(milliseconds: 500);

  /// How long a finger must stay down before the scene pauses.
  static const _holdDelay = Duration(milliseconds: 220);

  /// A tap in the left third goes back; anywhere else goes on.
  static const _backZone = 0.35;

  /// How far a swipe has to travel to count.
  static const _swipeDistance = 40.0;

  /// 0 to 1 over the current scene: the story bar and the slow zoom.
  late final AnimationController _progress;

  /// Loops forever and drives the scenes' ambient motion.
  late final AnimationController _ambient;

  int _index = 0;
  bool _started = false;

  /// Reduced motion: still frames, nothing moves on its own.
  bool _reduceMotion = false;

  /// A screen reader is on, which would otherwise read content that keeps
  /// changing under it.
  bool _screenReader = false;

  /// The app is in the background or its page is hidden.
  bool _away = false;

  Timer? _holdTimer;

  /// A finger has been held down long enough to freeze the scene.
  bool _holding = false;

  /// Set when a hold begins: the tap that ends it is not a navigation.
  bool _ignoreTap = false;
  double _dragged = 0;

  /// Everything moving on the stage stops: away, or a finger held down.
  bool get _frozen => _away || _holding;

  /// Nothing moves on its own with reduced motion or a screen reader.
  bool get _still => _reduceMotion || _screenReader;

  bool get _playing => !_still && !_away;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress = AnimationController(vsync: this, duration: _sceneDuration)
      ..addStatusListener(_onProgress);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _screenReader = MediaQuery.accessibleNavigationOf(context);
    _syncAmbient();
    if (_still) {
      _progress.value = 1;
    } else if (!_started) {
      _progress.forward();
    }
    _started = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app (hidden or in the background) pauses the reel and
    // coming back carries on from the same spot. A brief `inactive` does not:
    // on the web that fires whenever the window loses focus (clicking into
    // DevTools, another window), and on a phone for a system dialog, and the
    // reel would stall for no reason.
    final left =
        state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    if (left) {
      _setAway(true);
    } else if (state == AppLifecycleState.resumed) {
      _setAway(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdTimer?.cancel();
    _progress.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Each scene moves on by itself; after the last one it starts again.
  void _onProgress(AnimationStatus status) {
    if (status == AnimationStatus.completed && _playing) {
      _go(_index + 1);
    }
  }

  void _go(int scene) {
    // Going on from the last scene starts again; back from the first does
    // nothing.
    final next = scene >= _sceneCount ? 0 : scene.clamp(0, _sceneCount - 1);
    if (next == _index) return;
    setState(() => _index = next);
    if (_still) {
      _progress.value = 1;
    } else if (_away) {
      _progress.value = 0;
    } else {
      _progress.forward(from: 0);
    }
  }

  void _setAway(bool away) {
    if (_away == away) return;
    setState(() => _away = away);
    if (away) {
      _progress.stop();
    } else {
      _resume();
    }
    _syncAmbient();
  }

  /// The stage's looping motion runs unless motion is reduced or the reel is
  /// frozen. The board's flips and the props' lifts run off it, so they stop
  /// with it.
  void _syncAmbient() {
    if (_reduceMotion || _frozen) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  void _resume() {
    if (_playing && !_progress.isCompleted && !_progress.isAnimating) {
      _progress.forward();
    }
  }

  /// A finger that stays down pauses the scene, like a story; lifting it
  /// carries on from the same spot. A quick tap never pauses.
  void _onPointerDown(PointerDownEvent _) {
    _ignoreTap = false;
    _dragged = 0;
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDelay, () {
      _ignoreTap = true;
      setState(() => _holding = true);
      if (_playing) _progress.stop();
      _syncAmbient();
    });
  }

  void _onPointerUp(PointerEvent _) {
    _holdTimer?.cancel();
    if (!_holding) return;
    setState(() => _holding = false);
    _resume();
    _syncAmbient();
  }

  void _onTap(TapUpDetails details, double width) {
    // Letting go after a hold only resumes; it is not a tap.
    if (_ignoreTap) return;
    _go(details.localPosition.dx < width * _backZone ? _index - 1 : _index + 1);
  }

  void _onSwipeEnd() {
    if (_dragged.abs() > _swipeDistance) _go(_index + (_dragged < 0 ? 1 : -1));
    _dragged = 0;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _go(_index + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(_index - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Leaving the reel marks it seen, so it is never shown again.
  Future<void> _finish(String route) async {
    await ref.read(storageServiceProvider).setWelcomeSeen();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final copy = _copy(l10n);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Semantics(
          container: true,
          label: l10n.welcomeCarouselLabel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  // Stage and words: taps, swipes and holds land here, and the
                  // buttons below keep their own taps.
                  Expanded(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: _onPointerDown,
                      onPointerUp: _onPointerUp,
                      onPointerCancel: _onPointerUp,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (d) => _onTap(d, width),
                        onHorizontalDragUpdate: (d) => _dragged += d.delta.dx,
                        onHorizontalDragEnd: (_) => _onSwipeEnd(),
                        child: Column(
                          children: [
                            Expanded(child: _stage(l10n)),
                            _words(copy),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _Footer(
                    createLabel: l10n.welcomeCreateAccount,
                    promptLabel: l10n.welcomeHaveAccountPrompt,
                    logInLabel: l10n.welcomeLogIn,
                    onCreate: () => _finish(RouteNames.register),
                    onLogIn: () => _finish(RouteNames.login),
                  ),
                ],
              ),
              SafeArea(
                // Top aligned: the stack gives this a tight, full-screen size,
                // which would otherwise centre the bars vertically.
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _StoryBars(
                      progress: _progress,
                      index: _index,
                      total: _sceneCount,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The scene, fading as it changes, with a slow zoom while it plays. Each
  /// scene carries its own fade into the words panel below.
  Widget _stage(AppLocalizations l10n) => AnimatedSwitcher(
        duration: _fade,
        child: ScaleTransition(
          key: ValueKey(_index),
          scale: Tween<double>(
            begin: 1.06,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOut)).animate(_progress),
          child: ReelScene(index: _index, ambient: _ambient, l10n: l10n),
        ),
      );

  /// The words of every scene stacked, so the panel keeps the height of the
  /// tallest one; only the current one shows.
  Widget _words(List<_Copy> copy) => Semantics(
        liveRegion: _still,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Stack(
                children: [
                  for (var i = 0; i < copy.length; i++)
                    AnimatedOpacity(
                      opacity: i == _index ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          excluding: i != _index,
                          child: _SceneCopy(
                            key: ValueKey(i == _index ? 'on$i' : 'off$i'),
                            copy: copy[i],
                            reduceMotion: _reduceMotion,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  List<_Copy> _copy(AppLocalizations l10n) => [
        _Copy(l10n.welcome1Eyebrow, l10n.welcome1Headline, l10n.welcome1Body),
        _Copy(l10n.welcome2Eyebrow, l10n.welcome2Headline, l10n.welcome2Body),
        _Copy(l10n.welcome3Eyebrow, l10n.welcome3Headline, l10n.welcome3Body),
      ];
}

class _Copy {
  const _Copy(this.eyebrow, this.headline, this.body);

  final String eyebrow;

  /// Lines separated by a newline; each one snaps in on its own.
  final String headline;
  final String body;
}

/// One bar per scene: full once seen, filling while it plays.
class _StoryBars extends StatelessWidget {
  const _StoryBars({
    required this.progress,
    required this.index,
    required this.total,
  });

  final Animation<double> progress;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    // As tall as the row was with the pause button, so the bars stay put.
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                child: _Bar(progress: progress, scene: i, current: index),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.progress,
    required this.scene,
    required this.current,
  });

  final Animation<double> progress;
  final int scene;
  final int current;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) {
        final value = scene < current
            ? 1.0
            : scene == current
                ? progress.value
                : 0.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.textPrimary.withValues(alpha: 0.25),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: const ColoredBox(color: AppColors.accent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The scene's words: eyebrow, a two-line headline that snaps in line by
/// line, and the body.
class _SceneCopy extends StatelessWidget {
  const _SceneCopy({
    required this.copy,
    required this.reduceMotion,
    super.key,
  });

  final _Copy copy;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final lines = copy.headline.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          copy.eyebrow.toUpperCase(),
          style: AppTypography.label(color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          label: lines.join(' '),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                _Rise(
                  delay: 60.0 * i,
                  reduceMotion: reduceMotion,
                  // Scales down instead of wrapping on a narrow phone.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lines[i].toUpperCase(),
                      maxLines: 1,
                      style: AppTypography.hero(size: 32),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          copy.body,
          style: AppTypography.body(),
        ),
      ],
    );
  }
}

/// Sends a headline line up out of a mask after [delay] milliseconds. Shows it
/// straight away when motion is reduced.
class _Rise extends StatefulWidget {
  const _Rise({
    required this.child,
    required this.reduceMotion,
    this.delay = 0,
  });

  final Widget child;
  final bool reduceMotion;
  final double delay;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  static const _run = 450;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.delay + _run).round()),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay / (widget.delay + _run),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => ClipRect(
        child: FractionalTranslation(
          translation: Offset(0, 1.05 * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Create an account and log in, on every scene.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.createLabel,
    required this.promptLabel,
    required this.logInLabel,
    required this.onCreate,
    required this.onLogIn,
  });

  final String createLabel;
  final String promptLabel;
  final String logInLabel;
  final VoidCallback onCreate;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(label: createLabel, onPressed: onCreate),
                const SizedBox(height: 4),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        promptLabel,
                        style: AppTypography.body(
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      InkWell(
                        onTap: onLogIn,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                logInLabel,
                                style: AppTypography.body(
                                  size: 13,
                                  color: AppColors.accent,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
