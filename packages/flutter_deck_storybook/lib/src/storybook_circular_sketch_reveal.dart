import 'package:flutter/widgets.dart';

/// Configures an optional circular reveal for a page's pencil sketch.
///
/// The [origin] is normalized to the visible artwork rectangle: `(-1, -1)` is
/// its top-left corner, `(0, 0)` is its center, and `(1, 1)` is its bottom-right
/// corner. [artworkAspectRatio] lets [StorybookPage] account for the empty
/// letterbox area created when the artwork is displayed with [BoxFit.contain].
///
/// Radius values are fractions of the fitted artwork's shortest side. The
/// reveal grows far enough to cover the complete page before the existing
/// full-color phase starts.
@immutable
class StorybookCircularSketchReveal {
  /// Creates a circular pencil-sketch reveal.
  const StorybookCircularSketchReveal({
    required this.origin,
    required this.artworkAspectRatio,
    this.initialRadiusFraction = 0.055,
    this.softEdgeFraction = 0.025,
  }) : assert(artworkAspectRatio > 0 && artworkAspectRatio < double.infinity),
       assert(initialRadiusFraction >= 0 && initialRadiusFraction <= 1),
       assert(softEdgeFraction > 0 && softEdgeFraction <= 1);

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

  /// Feather width as a fraction of the artwork's shortest side.
  final double softEdgeFraction;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StorybookCircularSketchReveal &&
            origin == other.origin &&
            artworkAspectRatio == other.artworkAspectRatio &&
            initialRadiusFraction == other.initialRadiusFraction &&
            softEdgeFraction == other.softEdgeFraction;
  }

  @override
  int get hashCode => Object.hash(
    origin,
    artworkAspectRatio,
    initialRadiusFraction,
    softEdgeFraction,
  );
}
