import 'package:flutter/widgets.dart';
import 'package:flutter_deck/src/transitions/flutter_deck_transition_builders.dart';

/// A transtion class used to define the transition between slides.
class FlutterDeckTransition {
  /// The default duration used by flutter_deck slide transitions.
  static const defaultDuration = Duration(milliseconds: 300);

  /// Creates a [FlutterDeckTransition] that uses a custom transition.
  ///
  /// The [_transitionBuilder] is required and is used to build the transition.
  const FlutterDeckTransition.custom({
    required FlutterDeckTransitionBuilder transitionBuilder,
    this.duration = defaultDuration,
    this.reverseDuration,
  }) : assert(duration > Duration.zero),
       assert(reverseDuration == null || reverseDuration > Duration.zero),
       _transitionBuilder = transitionBuilder;

  /// Creates a [FlutterDeckTransition] that uses a [FadeTransition].
  const FlutterDeckTransition.fade()
    : duration = defaultDuration,
      reverseDuration = null,
      _transitionBuilder = const FlutterDeckFadeTransitionBuilder();

  /// Creates a [FlutterDeckTransition] that uses a [ScaleTransition].
  const FlutterDeckTransition.scale()
    : duration = defaultDuration,
      reverseDuration = null,
      _transitionBuilder = const FlutterDeckScaleTransitionBuilder();

  /// Creates a [FlutterDeckTransition] that uses a [SlideTransition].
  const FlutterDeckTransition.slide()
    : duration = defaultDuration,
      reverseDuration = null,
      _transitionBuilder = const FlutterDeckSlideTransitionBuilder();

  /// Creates a [FlutterDeckTransition] that uses a [RotationTransition].
  const FlutterDeckTransition.rotation()
    : duration = defaultDuration,
      reverseDuration = null,
      _transitionBuilder = const FlutterDeckRotationTransitionBuilder();

  /// Creates a [FlutterDeckTransition] that does not use any transition.
  const FlutterDeckTransition.none()
    : duration = defaultDuration,
      reverseDuration = null,
      _transitionBuilder = const FlutterDeckNoTransitionBuilder();

  /// How long a slide takes to enter.
  final Duration duration;

  /// How long a slide takes to leave when navigation is reversed.
  ///
  /// Defaults to [duration].
  final Duration? reverseDuration;

  /// The builder used to build the transition.
  final FlutterDeckTransitionBuilder _transitionBuilder;

  /// Builds the transition between slides.
  Widget build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _transitionBuilder.build(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
