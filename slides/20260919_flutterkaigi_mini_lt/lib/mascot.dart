import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart' as scene;
import 'package:flutterkaigi_mini_20260919/dashmaru_background.dart';
import 'package:flutterkaigi_mini_20260919/dashmaru_scene.dart';

/// Placement in the deck's 1920 × 1080 logical coordinate system.
Rect dashmaruActorBounds(int slideIndex) => switch (slideIndex) {
  5 => const Rect.fromLTWH(900, 140, 920, 850),
  // Celebrate's full-body hops need more space above and beside the actor.
  // Keep its center X and bottom aligned with the usual companion frame.
  6 => const Rect.fromLTWH(1420, 530, 470, 500),
  16 => const Rect.fromLTWH(1110, 220, 790, 790),
  _ => const Rect.fromLTWH(1460, 660, 390, 370),
};

/// One retained actor, placed above the deck's changing slide routes.
///
/// Keep this widget mounted (with the same key) while changing [slideIndex].
/// The scene loads during the introduction and is revealed on slide 6.
class DashmaruActor extends StatefulWidget {
  const DashmaruActor({
    required this.slideIndex,
    required this.large,
    this.enableRendering = true,
    super.key,
  });

  final int slideIndex;
  final bool large;

  /// CPU-only layout tests can omit the GPU scene and asset loading.
  final bool enableRendering;

  @override
  State<DashmaruActor> createState() => _DashmaruActorState();
}

class _DashmaruActorState extends State<DashmaruActor> {
  final _cues = DashmaruCueController();
  DashmaruScene? _world;
  bool _ready = false;
  bool _reducedMotion = false;
  Object? _error;
  int _loadGeneration = 0;

  bool get _demo => widget.slideIndex == 5;

  @override
  void initState() {
    super.initState();
    if (widget.enableRendering) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _cues.selectSlide(widget.slideIndex, reducedMotion: _reducedMotion);
  }

  @override
  void didUpdateWidget(DashmaruActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cues.selectSlide(widget.slideIndex, reducedMotion: _reducedMotion);
    if (widget.enableRendering && !oldWidget.enableRendering) _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    // Retry uses a fresh graph, so a partly loaded model is never duplicated.
    final world = DashmaruScene();
    try {
      await world.load(
        initialMotion: DashmaruMotion.idle,
        initialBackground: DashmaruBackground.night,
      );
      if (!mounted || generation != _loadGeneration) return;
      _cues.attach(world);
      setState(() {
        _world = world;
        _ready = true;
        _error = null;
      });
    } catch (error, stack) {
      debugPrint('Dashmaru actor loading failed: $error\n$stack');
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _error = error);
    }
  }

  void _retry() {
    setState(() {
      _ready = false;
      _error = null;
    });
    _load();
  }

  @override
  void dispose() {
    _loadGeneration++;
    _cues.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'だしゅまる。${_world?.motion.label ?? '待機'}。',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            bottom: _demo ? 104 : 0,
            child: RepaintBoundary(child: _buildScene(context)),
          ),
          if (_demo)
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: colors.surfaceContainerLowest.withValues(alpha: 0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: _demoControls(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScene(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (!widget.enableRendering) {
      return Center(
        child: Icon(
          Icons.flutter_dash_rounded,
          size: widget.large ? 160 : 88,
          color: colors.secondary,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flutter_dash_rounded,
                color: colors.secondary,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'だしゅまるは、ひと休み中',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              TextButton(onPressed: _retry, child: const Text('もう一度呼ぶ')),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_reducedMotion)
              Icon(
                Icons.flutter_dash_rounded,
                color: colors.secondary,
                size: 32,
              )
            else
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'だしゅまるを呼んでいます…',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
    }
    final world = _world!;
    return MouseRegion(
      cursor: _demo ? SystemMouseCursors.grab : MouseCursor.defer,
      child: Listener(
        onPointerSignal: !_demo
            ? null
            : (event) {
                if (event is PointerScrollEvent) {
                  setState(() => world.zoom(event.scrollDelta.dy));
                }
              },
        child: GestureDetector(
          behavior: _demo
              ? HitTestBehavior.opaque
              : HitTestBehavior.deferToChild,
          onPanUpdate: !_demo
              ? null
              : (details) => setState(
                  () => world.drag(details.delta.dx, details.delta.dy),
                ),
          child: TickerMode(
            enabled: widget.slideIndex >= 5 && world.playing,
            child: scene.SceneView(
              world.sceneGraph,
              cameraBuilder: _cues.camera,
              onTick: _cues.tick,
              // The small companion never needs a full Retina render target.
              pixelRatio: widget.large ? null : 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoControls(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final (motion, icon) in const [
        (DashmaruMotion.wave, Icons.waving_hand_rounded),
        (DashmaruMotion.run, Icons.directions_run_rounded),
        (DashmaruMotion.shake, Icons.vibration_rounded),
        (DashmaruMotion.jump, Icons.arrow_upward_rounded),
      ])
        TextButton.icon(
          onPressed: !_ready
              ? null
              : () => setState(() => _cues.selectDemoMotion(motion)),
          style: TextButton.styleFrom(
            foregroundColor: _world?.motion == motion
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            backgroundColor: _world?.motion == motion
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            textStyle: Theme.of(context).textTheme.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          icon: Icon(icon, size: 18),
          label: Text(motion.label),
        ),
      IconButton(
        tooltip: _world?.playing ?? true ? '一時停止' : '再生',
        onPressed: !_ready ? null : () => setState(_cues.toggleDemoPlayback),
        icon: Icon(
          _world?.playing ?? true
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
        ),
      ),
    ],
  );
}

/// Slide cues advance on the same clock as the actual animation clips.
///
/// Navigation replaces the whole sequence synchronously. There are no timers
/// or async cue callbacks that can change an actor after its slide has left.
/// A scene attached after loading receives only the latest selected slide.
class DashmaruCueController {
  static const _cameraDistance = 10.4;
  DashmaruScene? _world;
  int _slideIndex = 0;
  bool _reducedMotion = false;
  bool _disposed = false;
  List<_CueStage> _stages = const [];
  int _stageIndex = 0;
  double _stageElapsed = 0;
  double _riseRemaining = 0;

  scene.PerspectiveCamera camera(Duration elapsed) {
    final camera = _world!.camera(elapsed);
    if (_slideIndex == 6) {
      // The larger viewport keeps the same pixels per model unit because
      // distance grows in proportion to its height. Move the view upward by
      // half the extra world-space height, leaving the feet at the same edge.
      final lift =
          (_world!.distance - _cameraDistance) *
          math.tan(camera.fovRadiansY / 2);
      camera.position.y += lift;
      camera.target.y += lift;
    }
    return camera;
  }

  void selectSlide(int index, {bool reducedMotion = false}) {
    if (_disposed ||
        (_slideIndex == index && _reducedMotion == reducedMotion)) {
      return;
    }
    _slideIndex = index;
    _reducedMotion = reducedMotion;
    _applySlide();
  }

  void attach(DashmaruScene world) {
    if (_disposed) return;
    _world = world;
    _applySlide();
  }

  void _applySlide() {
    _stages = const [];
    _stageIndex = 0;
    _stageElapsed = 0;
    final world = _world;
    if (world == null) return;
    world.setCamera('front');
    world.distance = _slideIndex == 6
        ? _cameraDistance *
              dashmaruActorBounds(6).height /
              dashmaruActorBounds(9).height
        : _cameraDistance;
    world.setSpeed(1);
    final expression = switch (_slideIndex) {
      6 || 16 => DashmaruExpression.smile,
      7 => DashmaruExpression.strain,
      8 || 10 => DashmaruExpression.spiral,
      _ => DashmaruExpression.normal,
    };
    if (_slideIndex < 5 || _reducedMotion) {
      _riseRemaining = 0;
      world.selectMotion(DashmaruMotion.idle, animateTransition: false);
      world.selectExpression(expression);
      world.setPlaying(false);
      world.tick(Duration.zero, 0);
      return;
    }
    double duration(DashmaruMotion motion) => world.durations[motion] ?? 2.5;
    const idle = _CueStage(DashmaruMotion.idle);
    _stages = switch (_slideIndex) {
      5 => const [_CueStage(DashmaruMotion.wave)],
      6 => const [
        _CueStage(
          DashmaruMotion.celebrate,
          expression: DashmaruExpression.smile,
        ),
      ],
      7 => const [
        _CueStage(DashmaruMotion.shake, expression: DashmaruExpression.strain),
      ],
      8 => const [
        _CueStage(DashmaruMotion.sit, expression: DashmaruExpression.spiral),
      ],
      10 => const [
        _CueStage(DashmaruMotion.tilt, expression: DashmaruExpression.spiral),
      ],
      11 || 12 => const [_CueStage(DashmaruMotion.sit)],
      14 => [
        _CueStage(DashmaruMotion.wave, seconds: duration(DashmaruMotion.wave)),
        idle,
      ],
      16 => const [
        _CueStage(DashmaruMotion.wave, expression: DashmaruExpression.smile),
      ],
      _ => const [idle],
    };
    _applyStage();
    world.tick(Duration.zero, 0);
  }

  void _applyStage() {
    final world = _world!;
    final stage = _stages[_stageIndex];
    final unchanged = world.motion == stage.motion;
    if (stage.motion == DashmaruMotion.sit) {
      _riseRemaining = 0;
    } else if (world.motion == DashmaruMotion.sit) {
      _riseRemaining = 1.25;
    }
    final retainingPose =
        stage.motion == DashmaruMotion.sit ||
        stage.motion == DashmaruMotion.idle;
    // Keep the seated playback phase through the video and QR examples.
    // Re-entering a one-shot gesture starts a fresh full clip.
    if (!unchanged || !retainingPose) {
      world.selectMotion(stage.motion, animateTransition: !unchanged);
    }
    world.selectExpression(stage.expression);
    world.setPlaying(true);
  }

  void tick(Duration elapsed, double deltaSeconds) {
    final world = _world;
    if (_disposed || world == null || _slideIndex < 5 || !world.playing) return;
    final delta = math.min(math.max(deltaSeconds, 0), 0.05).toDouble();
    // DashmaruScene samples and applies the scene graph itself. Advancing the
    // graph a second time here would double the authored animation speed.
    world.tick(elapsed, delta);
    final risingDelta = math.min(_riseRemaining, delta);
    _riseRemaining = math.max(0, _riseRemaining - delta);
    if (_stages.isEmpty) return;
    final motion = _stages[_stageIndex].motion;
    final gesture =
        motion == DashmaruMotion.jump ||
        motion == DashmaruMotion.wave ||
        motion == DashmaruMotion.blink;
    // Jumping straight from a seated slide still gets a full gesture after
    // the source scene has finished its grounded standing transition.
    _stageElapsed += gesture ? delta - risingDelta : delta;
    final seconds = _stages[_stageIndex].seconds;
    if (seconds != null &&
        _stageElapsed + 1e-9 >= seconds &&
        _stageIndex + 1 < _stages.length) {
      _stageIndex++;
      _stageElapsed = 0;
      _applyStage();
    }
  }

  void selectDemoMotion(DashmaruMotion motion) {
    final world = _world;
    if (_disposed || world == null || _slideIndex != 5) return;
    _stages = const [];
    world.selectMotion(motion);
    world.selectExpression(
      motion == DashmaruMotion.run
          ? DashmaruExpression.strain
          : DashmaruExpression.normal,
    );
    // Explicit demo interactions may move even with reduced motion enabled.
    world.setPlaying(true);
    world.tick(Duration.zero, 0);
  }

  void toggleDemoPlayback() {
    final world = _world;
    if (_disposed || world == null || _slideIndex != 5) return;
    world.setPlaying(!world.playing);
  }

  void dispose() {
    _disposed = true;
    _stages = const [];
    _world?.setPlaying(false);
    _world = null;
  }
}

class _CueStage {
  const _CueStage(
    this.motion, {
    this.expression = DashmaruExpression.normal,
    this.seconds,
  });

  final DashmaruMotion motion;
  final DashmaruExpression expression;
  final double? seconds;
}
