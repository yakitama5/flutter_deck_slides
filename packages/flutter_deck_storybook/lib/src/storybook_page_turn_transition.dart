import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

import 'storybook_reveal.dart';

enum _PageTurnDirection { forward, backward }

/// A page-turn transition for [FlutterDeckApp].
///
/// Reuse a single instance as the deck's global transition. The instance keeps
/// track of the current slide number so that previous navigation turns the page
/// in the opposite direction.
class StorybookPageTurnTransitionBuilder extends FlutterDeckTransitionBuilder {
  /// Creates a storybook page-turn transition builder.
  StorybookPageTurnTransitionBuilder({
    this.perspective = 0.0014,
    this.maxRotation = math.pi / 2,
    this.reverseOnPrevious = true,
    this.usePerspective = true,
    this.enableInkReveal = true,
    this.inkRevealDuration = const Duration(milliseconds: 2750),
    this.inkRevealOrigin = const Alignment(0, 0.25),
  }) : assert(perspective > 0),
       assert(maxRotation > 0 && maxRotation <= math.pi / 2),
       assert(inkRevealDuration > Duration.zero);

  /// Perspective applied to the page transform.
  final double perspective;

  /// Maximum Y-axis rotation in radians.
  final double maxRotation;

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
        child: child,
      );
    }

    return _StorybookPageTurnTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      direction: _direction,
      perspective: perspective,
      maxRotation: maxRotation,
      enableInkReveal: enableInkReveal,
      inkRevealDuration: inkRevealDuration,
      inkRevealOrigin: inkRevealOrigin,
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
    required this.enableInkReveal,
    required this.inkRevealDuration,
    required this.inkRevealOrigin,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PageTurnDirection direction;
  final double perspective;
  final double maxRotation;
  final bool enableInkReveal;
  final Duration inkRevealDuration;
  final Alignment inkRevealOrigin;
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
        child: child,
      ),
      builder: (context, page) {
        final incoming = Curves.easeInOutCubic.transform(
          animation.value.clamp(0.0, 1.0),
        );
        final outgoing = Curves.easeInOutCubic.transform(
          secondaryAnimation.value.clamp(0.0, 1.0),
        );
        final directionSign = direction == _PageTurnDirection.forward
            ? 1.0
            : -1.0;

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

          return ClipRect(
            key: const ValueKey('storybook-page-turn-incoming-reveal'),
            clipper: _IncomingPageRevealClipper(
              progress: revealProgress,
              direction: direction,
              perspective: perspective,
              maxRotation: maxRotation,
            ),
            child: page,
          );
        }

        final turnProgress = turnsOutWithPrimary ? 1 - incoming : outgoing;
        final angle = -directionSign * turnProgress * maxRotation;
        final shadowStrength = math.sin(turnProgress * math.pi).abs();
        final alignment = direction == _PageTurnDirection.forward
            ? Alignment.centerLeft
            : Alignment.centerRight;

        return Transform(
          key: const ValueKey('storybook-page-turn-outgoing-sheet'),
          alignment: alignment,
          transform: Matrix4.identity()
            ..setEntry(3, 2, perspective)
            ..rotateY(angle),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34 * shadowStrength),
                  blurRadius: 42 * shadowStrength,
                  spreadRadius: 3 * shadowStrength,
                  offset: Offset(directionSign * 16 * shadowStrength, 4),
                ),
              ],
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: direction == _PageTurnDirection.forward
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  end: direction == _PageTurnDirection.forward
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  colors: [
                    Colors.black.withValues(alpha: 0.22 * shadowStrength),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.12 * shadowStrength),
                  ],
                  stops: const [0, 0.72, 1],
                ),
              ),
              child: page,
            ),
          ),
        );
      },
    );
  }
}

class _IncomingPageRevealClipper extends CustomClipper<Rect> {
  const _IncomingPageRevealClipper({
    required this.progress,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
  });

  final double progress;
  final _PageTurnDirection direction;
  final double perspective;
  final double maxRotation;

  @override
  Rect getClip(Size size) {
    final turnAngle = progress.clamp(0.0, 1.0) * maxRotation;
    // This is the same perspective divide used by the outgoing Matrix4. Using
    // only cos(angle) would leave a visible gap between the two page edges.
    final perspectiveScale = 1 + perspective * size.width * math.sin(turnAngle);
    final coveredFraction = (math.cos(turnAngle) / perspectiveScale).clamp(
      0.0,
      1.0,
    );

    if (direction == _PageTurnDirection.forward) {
      return Rect.fromLTRB(
        size.width * coveredFraction,
        0,
        size.width,
        size.height,
      );
    }

    return Rect.fromLTRB(0, 0, size.width * (1 - coveredFraction), size.height);
  }

  @override
  bool shouldReclip(covariant _IncomingPageRevealClipper oldClipper) {
    return progress != oldClipper.progress ||
        direction != oldClipper.direction ||
        perspective != oldClipper.perspective ||
        maxRotation != oldClipper.maxRotation;
  }
}

class _StorybookInkSequence extends StatefulWidget {
  const _StorybookInkSequence({
    required this.animation,
    required this.secondaryAnimation,
    required this.enabled,
    required this.duration,
    required this.revealOrigin,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool enabled;
  final Duration duration;
  final Alignment revealOrigin;
  final Widget child;

  @override
  State<_StorybookInkSequence> createState() => _StorybookInkSequenceState();
}

class _StorybookInkSequenceState extends State<_StorybookInkSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late bool _shouldReveal;

  @override
  void initState() {
    super.initState();
    _shouldReveal = widget.enabled && widget.animation.value < 1;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _shouldReveal ? 0 : 1,
    );
    widget.animation.addStatusListener(_handlePrimaryStatus);
    widget.secondaryAnimation.addStatusListener(_handleSecondaryStatus);
  }

  @override
  void didUpdateWidget(covariant _StorybookInkSequence oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_handlePrimaryStatus);
      widget.animation.addStatusListener(_handlePrimaryStatus);
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
    }
  }

  void _handlePrimaryStatus(AnimationStatus status) {
    if (!_shouldReveal) return;

    if (status == AnimationStatus.completed) {
      _controller.forward();
    } else if (status == AnimationStatus.reverse) {
      _controller.stop();
    }
  }

  void _handleSecondaryStatus(AnimationStatus status) {
    if (status != AnimationStatus.forward || _controller.isCompleted) return;

    _shouldReveal = false;
    _controller.value = 1;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handlePrimaryStatus);
    widget.secondaryAnimation.removeStatusListener(_handleSecondaryStatus);
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
