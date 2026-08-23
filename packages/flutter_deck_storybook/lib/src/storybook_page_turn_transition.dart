import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

enum _PageTurnDirection { forward, backward }

/// A three-dimensional page-turn transition for [FlutterDeckApp].
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
  }) : assert(perspective > 0),
       assert(maxRotation > 0 && maxRotation <= math.pi / 2);

  /// Perspective applied to the page transform.
  final double perspective;

  /// Maximum Y-axis rotation in radians.
  final double maxRotation;

  /// Whether previous navigation should turn the page in reverse.
  final bool reverseOnPrevious;

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

    return _StorybookPageTurnTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      direction: _direction,
      perspective: perspective,
      maxRotation: maxRotation,
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

class _StorybookPageTurnTransition extends StatelessWidget {
  const _StorybookPageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PageTurnDirection direction;
  final double perspective;
  final double maxRotation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: RepaintBoundary(child: child),
      builder: (context, page) {
        final incoming = Curves.easeOutCubic.transform(
          animation.value.clamp(0.0, 1.0),
        );
        final outgoing = Curves.easeInCubic.transform(
          secondaryAnimation.value.clamp(0.0, 1.0),
        );
        final directionSign = direction == _PageTurnDirection.forward
            ? 1.0
            : -1.0;
        final angle = directionSign * ((1 - incoming) - outgoing) * maxRotation;
        final turnAmount = math.max(1 - incoming, outgoing);
        final shadowStrength = math.sin(turnAmount * math.pi).abs();
        final alignment = direction == _PageTurnDirection.forward
            ? Alignment.centerLeft
            : Alignment.centerRight;
        final pageOpacity = (animation.value * 8).clamp(0.0, 1.0);

        return Opacity(
          opacity: pageOpacity,
          child: Transform(
            alignment: alignment,
            filterQuality: FilterQuality.high,
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspective)
              ..rotateY(angle),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.34 * shadowStrength,
                    ),
                    blurRadius: 42 * shadowStrength,
                    spreadRadius: 3 * shadowStrength,
                    offset: Offset(directionSign * 16 * shadowStrength, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  page!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: direction == _PageTurnDirection.forward
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            end: direction == _PageTurnDirection.forward
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            colors: [
                              Colors.black.withValues(
                                alpha: 0.22 * shadowStrength,
                              ),
                              Colors.transparent,
                              Colors.white.withValues(
                                alpha: 0.12 * shadowStrength,
                              ),
                            ],
                            stops: const [0, 0.72, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
