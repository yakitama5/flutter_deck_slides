import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

import 'storybook_page_curl.dart';
import 'storybook_reveal.dart';
import 'storybook_sound_effects.dart';

enum _PageTurnDirection { forward, backward }

/// A page-turn transition for [FlutterDeckApp].
///
/// Reuse a single instance as the deck's global transition. The instance keeps
/// track of the current slide number so that previous navigation turns the page
/// in the opposite direction.
class StorybookPageTurnTransitionBuilder extends FlutterDeckTransitionBuilder {
  /// Creates a storybook page-turn transition builder.
  StorybookPageTurnTransitionBuilder({
    this.perspective = 0.00008,
    this.maxRotation = math.pi / 2,
    this.pageFlex = 0.34,
    this.pageTwist = 0.045,
    this.meshColumns = 32,
    this.meshRows = 10,
    this.reverseOnPrevious = true,
    this.usePerspective = true,
    this.enableInkReveal = true,
    this.inkRevealDuration = const Duration(milliseconds: 2750),
    this.inkRevealOrigin = const Alignment(0, 0.25),
    this.soundEffects,
  }) : assert(perspective > 0),
       assert(maxRotation > 0 && maxRotation <= math.pi / 2),
       assert(pageFlex >= 0 && pageFlex <= math.pi / 3),
       assert(pageTwist >= 0 && pageTwist <= math.pi / 3),
       assert(meshColumns >= 8 && meshColumns <= 64),
       assert(meshRows >= 2 && meshRows <= 24),
       assert(inkRevealDuration > Duration.zero);

  /// Perspective applied to the page transform.
  final double perspective;

  /// Maximum Y-axis rotation in radians.
  final double maxRotation;

  /// Horizontal bend applied across the paper while it turns.
  final double pageFlex;

  /// Phase-changing twist between the top and bottom edges.
  final double pageTwist;

  /// Horizontal subdivisions used by the paper mesh.
  final int meshColumns;

  /// Vertical subdivisions used by the paper mesh.
  final int meshRows;

  /// Whether previous navigation should turn the page in reverse.
  final bool reverseOnPrevious;

  /// Whether to use the perspective-based 3D transition.
  ///
  /// The full slide is treated as one sheet and rotates around a vertical edge.
  /// This is enabled by default on every platform, including web. Pass `false`
  /// to use a slide-and-crossfade fallback on a problematic renderer.
  final bool usePerspective;

  /// Whether a blank page should develop from pencil lines into full color.
  ///
  /// The reveal starts after the incoming page has finished turning. It only
  /// affects [StorybookPage] content; the paper surface remains visible.
  final bool enableInkReveal;

  /// Duration of the blank-paper, pencil, and watercolor reveal sequence.
  ///
  /// The default timing follows the supplied Bayonetta Origins reference:
  /// roughly 300 ms of blank paper, 900 ms of underdrawing, and 1.7 seconds of
  /// overlapping watercolor bloom.
  final Duration inkRevealDuration;

  /// Point from which the watercolor bloom spreads across the page.
  final Alignment inkRevealOrigin;

  /// Optional page-turn and drawing audio cues.
  ///
  /// Pass [StorybookSoundEffects] to use the bundled sounds. Leaving this null
  /// keeps the deck silent. Audio is also skipped when reduced motion is on.
  final StorybookSoundEffectPlayer? soundEffects;

  int? _lastSlideNumber;
  _PageTurnDirection _direction = _PageTurnDirection.forward;

  @override
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reverseOnPrevious) {
      _updateDirection(context.flutterDeck.slideNumber);
    }

    if (!usePerspective &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      return _StorybookPlanarPageTurnTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        direction: _direction,
        child: _StorybookInkSequence(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          enabled: enableInkReveal,
          duration: inkRevealDuration,
          revealOrigin: inkRevealOrigin,
          soundEffects: soundEffects,
          child: child,
        ),
      );
    }

    return _StorybookPageTurnTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      direction: _direction,
      perspective: perspective,
      maxRotation: maxRotation,
      pageFlex: pageFlex,
      pageTwist: pageTwist,
      meshColumns: meshColumns,
      meshRows: meshRows,
      enableInkReveal: enableInkReveal,
      inkRevealDuration: inkRevealDuration,
      inkRevealOrigin: inkRevealOrigin,
      soundEffects: soundEffects,
      child: child,
    );
  }

  void _updateDirection(int targetSlideNumber) {
    final previousSlideNumber = _lastSlideNumber;

    if (previousSlideNumber != null &&
        previousSlideNumber != targetSlideNumber) {
      _direction = targetSlideNumber > previousSlideNumber
          ? _PageTurnDirection.forward
          : _PageTurnDirection.backward;
    }

    _lastSlideNumber = targetSlideNumber;
  }
}

class _StorybookPlanarPageTurnTransition extends StatelessWidget {
  const _StorybookPlanarPageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PageTurnDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final directionSign = direction == _PageTurnDirection.forward ? 1.0 : -1.0;
    final incomingPosition = animation.drive(
      Tween<Offset>(
        begin: Offset(directionSign * 0.12, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final outgoingPosition = secondaryAnimation.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(-directionSign * 0.08, 0),
      ).chain(CurveTween(curve: Curves.easeInCubic)),
    );
    final incomingOpacity = animation.drive(CurveTween(curve: Curves.easeOut));
    final outgoingOpacity = ReverseAnimation(secondaryAnimation)
        .drive(CurveTween(curve: Curves.easeIn));

    return FadeTransition(
      key: const ValueKey('storybook-page-turn-planar'),
      opacity: outgoingOpacity,
      child: SlideTransition(
        position: outgoingPosition,
        child: FadeTransition(
          opacity: incomingOpacity,
          child: SlideTransition(position: incomingPosition, child: child),
        ),
      ),
    );
  }
}

class _StorybookPageTurnTransition extends StatelessWidget {
  const _StorybookPageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
    required this.pageFlex,
    required this.pageTwist,
    required this.meshColumns,
    required this.meshRows,
    required this.enableInkReveal,
    required this.inkRevealDuration,
    required this.inkRevealOrigin,
    required this.soundEffects,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PageTurnDirection direction;
  final double perspective;
  final double maxRotation;
  final double pageFlex;
  final double pageTwist;
  final int meshColumns;
  final int meshRows;
  final bool enableInkReveal;
  final Duration inkRevealDuration;
  final Alignment inkRevealOrigin;
  final StorybookSoundEffectPlayer? soundEffects;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return FadeTransition(
        key: const ValueKey('storybook-page-turn-fade'),
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: _StorybookInkSequence(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        enabled: enableInkReveal,
        duration: inkRevealDuration,
        revealOrigin: inkRevealOrigin,
        soundEffects: soundEffects,
        child: child,
      ),
      builder: (context, page) {
        final incoming = Curves.easeInOutSine.transform(
          animation.value.clamp(0.0, 1.0),
        );
        final outgoing = Curves.easeInOutSine.transform(
          secondaryAnimation.value.clamp(0.0, 1.0),
        );
        final curlDirection = direction == _PageTurnDirection.forward
            ? StorybookPageCurlDirection.forward
            : StorybookPageCurlDirection.backward;

        final turnsOutWithPrimary =
            animation.status == AnimationStatus.reverse && animation.value < 1;
        final turnsOutWithSecondary =
            secondaryAnimation.status == AnimationStatus.forward &&
            secondaryAnimation.value > 0;
        final isTurningOut = turnsOutWithPrimary || turnsOutWithSecondary;

        if (!isTurningOut) {
          // Keep the next sheet flat and expose only the area no longer
          // covered by the rotating old sheet. This makes the paper itself
          // uncover the blank page instead of crossfading between two pages.
          final revealProgress =
              secondaryAnimation.status == AnimationStatus.reverse
              ? 1 - outgoing
              : incoming;

          return StorybookCurlReveal(
            clipKey: const ValueKey('storybook-page-turn-incoming-reveal'),
            progress: revealProgress,
            direction: curlDirection,
            perspective: perspective,
            maxRotation: maxRotation,
            flex: pageFlex,
            twist: pageTwist,
            columns: meshColumns,
            rows: meshRows,
            child: page!,
          );
        }

        final turnProgress = turnsOutWithPrimary ? 1 - incoming : outgoing;
        return StorybookCurlSheet(
          key: const ValueKey('storybook-page-turn-outgoing-sheet'),
          progress: turnProgress,
          direction: curlDirection,
          perspective: perspective,
          maxRotation: maxRotation,
          flex: pageFlex,
          twist: pageTwist,
          columns: meshColumns,
          rows: meshRows,
          child: page!,
        );
      },
    );
  }
}

class _StorybookInkSequence extends StatefulWidget {
  const _StorybookInkSequence({
    required this.animation,
    required this.secondaryAnimation,
    required this.enabled,
    required this.duration,
    required this.revealOrigin,
    required this.soundEffects,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool enabled;
  final Duration duration;
  final Alignment revealOrigin;
  final StorybookSoundEffectPlayer? soundEffects;
  final Widget child;

  @override
  State<_StorybookInkSequence> createState() => _StorybookInkSequenceState();
}

class _StorybookInkSequenceState extends State<_StorybookInkSequence>
    with SingleTickerProviderStateMixin {
  static const _drawingCueStart = 0.11;

  late final AnimationController _controller;
  var _shouldReveal = false;
  var _incomingTransitionObserved = false;
  var _drawingCuePlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _controller.addListener(_handleRevealTick);
    widget.animation.addListener(_handlePrimaryTick);
    widget.animation.addStatusListener(_handlePrimaryStatus);
    widget.secondaryAnimation.addStatusListener(_handleSecondaryStatus);
    unawaited(widget.soundEffects?.preload());
    _beginIncomingTransition();
  }

  @override
  void didUpdateWidget(covariant _StorybookInkSequence oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_handlePrimaryTick);
      oldWidget.animation.removeStatusListener(_handlePrimaryStatus);
      widget.animation.addListener(_handlePrimaryTick);
      widget.animation.addStatusListener(_handlePrimaryStatus);
      _incomingTransitionObserved = false;
    }
    if (oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      oldWidget.secondaryAnimation.removeStatusListener(_handleSecondaryStatus);
      widget.secondaryAnimation.addStatusListener(_handleSecondaryStatus);
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      _shouldReveal = false;
      _controller.value = 1;
      unawaited(widget.soundEffects?.stopDrawing());
    } else if (oldWidget.enabled != widget.enabled) {
      _incomingTransitionObserved = false;
    }
    if (oldWidget.soundEffects != widget.soundEffects) {
      unawaited(oldWidget.soundEffects?.stopDrawing());
      unawaited(widget.soundEffects?.preload());
    }

    _beginIncomingTransition();
  }

  void _handlePrimaryTick() {
    _beginIncomingTransition();
  }

  void _beginIncomingTransition() {
    if (_incomingTransitionObserved ||
        widget.animation.value >= 1 ||
        widget.animation.status == AnimationStatus.reverse) {
      return;
    }

    _incomingTransitionObserved = true;
    _drawingCuePlayed = false;
    unawaited(widget.soundEffects?.playPageTurn());

    if (!widget.enabled) return;

    _shouldReveal = true;
    _controller.value = 0;
  }

  void _handleRevealTick() {
    if (_drawingCuePlayed ||
        !_shouldReveal ||
        _controller.value < _drawingCueStart) {
      return;
    }

    _drawingCuePlayed = true;
    unawaited(widget.soundEffects?.playDrawing());
  }

  void _handlePrimaryStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _beginIncomingTransition();
    } else if (status == AnimationStatus.completed && _shouldReveal) {
      _controller.forward();
    } else if (status == AnimationStatus.reverse) {
      _controller.stop();
      unawaited(widget.soundEffects?.stopDrawing());
    }
  }

  void _handleSecondaryStatus(AnimationStatus status) {
    if (status != AnimationStatus.forward) return;

    unawaited(widget.soundEffects?.stopDrawing());
    if (_controller.isCompleted) return;

    _shouldReveal = false;
    _controller.value = 1;
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handlePrimaryTick);
    widget.animation.removeStatusListener(_handlePrimaryStatus);
    widget.secondaryAnimation.removeStatusListener(_handleSecondaryStatus);
    _controller.removeListener(_handleRevealTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, page) {
        final sketchProgress = const Interval(
          0.11,
          0.45,
          curve: Curves.easeOutCubic,
        ).transform(_controller.value);
        final paintProgress = const Interval(
          0.36,
          1,
          curve: Curves.easeInOutCubic,
        ).transform(_controller.value);

        return StorybookRevealScope(
          sketchProgress: sketchProgress,
          paintProgress: paintProgress,
          revealOrigin: widget.revealOrigin,
          child: page!,
        );
      },
    );
  }
}
