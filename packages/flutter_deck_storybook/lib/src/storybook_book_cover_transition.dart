import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Internal coordination between the page-turn transition and a book cover.
enum StorybookBookCoverMotion { opening, closing }

/// Supplies rigid-cover animation values to [StorybookBookCover].
class StorybookBookCoverTransitionScope extends InheritedWidget {
  const StorybookBookCoverTransitionScope({
    required this.motion,
    required this.progress,
    this.includeTabletop = true,
    required super.child,
    super.key,
  });

  final StorybookBookCoverMotion motion;
  final double progress;

  /// Whether this cover layer owns the full-screen tabletop.
  ///
  /// The incoming side of a closing route leaves this off so the already
  /// mounted outgoing route can provide the page and tabletop below it.
  final bool includeTabletop;

  static StorybookBookCoverTransitionScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
          StorybookBookCoverTransitionScope
        >();
  }

  @override
  bool updateShouldNotify(StorybookBookCoverTransitionScope oldWidget) {
    return motion != oldWidget.motion ||
        progress != oldWidget.progress ||
        includeTabletop != oldWidget.includeTabletop;
  }
}

/// The geometry used by a rigid book cover during a boundary transition.
///
/// A cover is a board hinged at the spine. It intentionally has no paper-mesh
/// values: the only cover deformation is a single Y-axis half-turn, while the
/// camera values move the whole book scene closer to or farther from the
/// viewer.
@immutable
class StorybookBookCoverMotionValues {
  const StorybookBookCoverMotionValues({
    required this.hingeAlignment,
    required this.rotationY,
    required this.cameraScale,
    required this.cameraOffset,
    this.sceneWidthFactor = 0.93,
    this.sceneHeightFactor = 0.88,
  });

  /// Calculates the rigid-cover and camera values for [progress].
  factory StorybookBookCoverMotionValues.forCover({
    required StorybookBookCoverMotion motion,
    required double progress,
    required bool backCover,
  }) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    // The camera must travel for the whole boundary transition. Delaying the
    // closing move until the cover is almost shut makes the page-to-cover
    // handoff look like a late scale jump instead of one continuous shot.
    final cameraProgress = Curves.easeInOutCubic.transform(normalizedProgress);
    final coverProgress = motion == StorybookBookCoverMotion.opening
        ? Curves.easeInOutCubic.transform(normalizedProgress)
        : 1 - Curves.easeInOutCubic.transform(normalizedProgress);

    // The front board is hinged on the left spine; the back board is mirrored
    // on the right spine. The free edge first rises toward the viewer and then
    // continues through the edge-on position to the other side of the hinge.
    // A complete half-turn is important: stopping at 90 degrees makes a rigid
    // cover disappear instead of reading as a board being opened.
    final rotationSign = backCover ? -1.0 : 1.0;
    return StorybookBookCoverMotionValues(
      hingeAlignment: backCover ? Alignment.centerRight : Alignment.centerLeft,
      rotationY: rotationSign * math.pi * coverProgress,
      cameraScale: motion == StorybookBookCoverMotion.opening
          ? _lerp(0.74, 1.0, cameraProgress)
          : _lerp(1.0, 0.74, cameraProgress),
      cameraOffset: motion == StorybookBookCoverMotion.opening
          ? Offset(0, _lerp(0.018, 0, cameraProgress))
          : Offset(0, _lerp(0, 0.018, cameraProgress)),
      sceneWidthFactor: _lerp(0.93, 1.0, cameraProgress),
      sceneHeightFactor: _lerp(0.88, 1.0, cameraProgress),
    );
  }

  /// The fixed spine edge used by the board.
  final Alignment hingeAlignment;

  /// The board's only rotation, in radians around the Y axis.
  final double rotationY;

  /// Scale applied to the complete book artwork as a camera move.
  final double cameraScale;

  /// Normalized camera translation applied to the complete book artwork.
  final Offset cameraOffset;

  /// Width of the book scene before the camera scale is applied.
  ///
  /// The cover, paper bundle, and route page all use this same interpolated
  /// bound so a camera move cannot expose a differently sized rectangle at a
  /// layer handoff.
  final double sceneWidthFactor;

  /// Height of the book scene before the camera scale is applied.
  final double sceneHeightFactor;

  static double _lerp(double begin, double end, double amount) {
    return begin + (end - begin) * amount;
  }
}
