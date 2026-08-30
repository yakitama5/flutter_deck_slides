import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Internal coordination between the page-turn transition and a book cover.
enum StorybookBookCoverMotion { opening, closing }

/// Supplies rigid-cover animation values to [StorybookBookCover].
class StorybookBookCoverTransitionScope extends InheritedWidget {
  const StorybookBookCoverTransitionScope({
    required this.motion,
    required this.progress,
    required super.child,
    super.key,
  });

  final StorybookBookCoverMotion motion;
  final double progress;

  static StorybookBookCoverTransitionScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
          StorybookBookCoverTransitionScope
        >();
  }

  @override
  bool updateShouldNotify(StorybookBookCoverTransitionScope oldWidget) {
    return motion != oldWidget.motion || progress != oldWidget.progress;
  }
}

/// The geometry used by a rigid book cover during a boundary transition.
///
/// A cover is a board hinged at the spine. It intentionally has no paper-mesh
/// values: the only cover deformation is a single Y-axis rotation, while the
/// camera values move the whole book scene closer to or farther from the
/// viewer.
@immutable
class StorybookBookCoverMotionValues {
  const StorybookBookCoverMotionValues({
    required this.hingeAlignment,
    required this.rotationY,
    required this.cameraScale,
    required this.cameraOffset,
  });

  /// Calculates the rigid-cover and camera values for [progress].
  factory StorybookBookCoverMotionValues.forCover({
    required StorybookBookCoverMotion motion,
    required double progress,
    required bool backCover,
  }) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final cameraProgress = motion == StorybookBookCoverMotion.opening
        ? Curves.easeInOutCubic.transform(normalizedProgress)
        : Curves.easeInOutCubic.transform(
            ((normalizedProgress - 0.68) / 0.32).clamp(0.0, 1.0),
          );
    final coverProgress = motion == StorybookBookCoverMotion.opening
        ? Curves.easeInCubic.transform(normalizedProgress)
        : 1 - Curves.easeOutCubic.transform(normalizedProgress);

    // The front board is hinged on the left spine; the back board is mirrored
    // on the right spine. With Flutter's camera looking down on the tabletop,
    // the free edge must travel away from the viewer as it rises. The signs
    // below therefore mirror the hinge and keep both boards on the same
    // tabletop-facing side instead of making the free edge balloon toward the
    // camera.
    final rotationSign = backCover ? 1.0 : -1.0;
    return StorybookBookCoverMotionValues(
      hingeAlignment: backCover ? Alignment.centerRight : Alignment.centerLeft,
      rotationY: rotationSign * math.pi / 2 * coverProgress,
      cameraScale: motion == StorybookBookCoverMotion.opening
          ? _lerp(0.90, 1.04, cameraProgress)
          : _lerp(1.04, 0.90, cameraProgress),
      cameraOffset: motion == StorybookBookCoverMotion.opening
          ? Offset(0, _lerp(0.022, -0.006, cameraProgress))
          : Offset(0, _lerp(-0.006, 0.022, cameraProgress)),
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

  static double _lerp(double begin, double end, double amount) {
    return begin + (end - begin) * amount;
  }
}
