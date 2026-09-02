import 'package:flutter/widgets.dart';

/// Configures the three-stage reveal for a page's pencil sketch.
///
/// The [origin] is normalized to the visible artwork rectangle: `(-1, -1)` is
/// its top-left corner, `(0, 0)` is its center, and `(1, 1)` is its bottom-right
/// corner. [artworkAspectRatio] lets [StorybookPage] account for the empty
/// letterbox area created when the artwork is displayed with [BoxFit.contain].
///
/// The circular sketch first grows to [focusRadiusFraction]. The rest of the
/// sketch then fades in during [surroundingFadeFraction], and full color starts
/// only after that fade has completed. The two timing fractions are portions of
/// the active reveal timeline after the initial blank-paper interval; the
/// remaining portion is reserved for the watercolor phase.
@immutable
class StorybookCircularSketchReveal {
  /// Creates a three-stage circular pencil-sketch reveal.
  const StorybookCircularSketchReveal({
    required this.origin,
    required this.artworkAspectRatio,
    this.initialRadiusFraction = 0.055,
    this.focusRadiusFraction = 0.56,
    this.softEdgeFraction = 0.025,
    this.focusLineFraction = 0.38,
    this.surroundingFadeFraction = 0.10,
  }) : assert(artworkAspectRatio > 0 && artworkAspectRatio < double.infinity),
       assert(initialRadiusFraction >= 0 && initialRadiusFraction <= 1),
       assert(focusRadiusFraction > 0 && focusRadiusFraction <= 1),
       assert(softEdgeFraction > 0 && softEdgeFraction <= 1),
       assert(focusLineFraction > 0 && focusLineFraction < 1),
       assert(surroundingFadeFraction > 0 && surroundingFadeFraction < 1),
       assert(focusLineFraction + surroundingFadeFraction < 1);

  /// Normalized reveal center within the fitted artwork rectangle.
  ///
  /// Both components should be between `-1` and `1`, inclusive.
  final Alignment origin;

  /// Width divided by height of the artwork displayed with [BoxFit.contain].
  ///
  /// Only the ratio is used, so this remains independent of image resolution.
  final double artworkAspectRatio;

  /// Initial circle radius as a fraction of the artwork's shortest side.
  final double initialRadiusFraction;

  /// Fraction of the maximum origin-to-page-corner radius reached by the
  /// focused circle before the surrounding sketch begins to fade in.
  final double focusRadiusFraction;

  /// Feather width as a fraction of the artwork's shortest side.
  final double softEdgeFraction;

  /// Portion of the active reveal timeline used by the focused circular line.
  final double focusLineFraction;

  /// Portion of the active reveal timeline used by the surrounding-line fade.
  final double surroundingFadeFraction;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StorybookCircularSketchReveal &&
            origin == other.origin &&
            artworkAspectRatio == other.artworkAspectRatio &&
            initialRadiusFraction == other.initialRadiusFraction &&
            focusRadiusFraction == other.focusRadiusFraction &&
            softEdgeFraction == other.softEdgeFraction &&
            focusLineFraction == other.focusLineFraction &&
            surroundingFadeFraction == other.surroundingFadeFraction;
  }

  @override
  int get hashCode => Object.hash(
    origin,
    artworkAspectRatio,
    initialRadiusFraction,
    focusRadiusFraction,
    softEdgeFraction,
    focusLineFraction,
    surroundingFadeFraction,
  );
}
