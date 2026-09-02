import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'storybook_circular_sketch_reveal.dart';

/// Animation values supplied by the page transition to [StorybookPage].
///
/// This type lives in `src/` intentionally. It lets the transition and page
/// surface coordinate without exposing animation plumbing as public API.
class StorybookRevealScope extends InheritedWidget {
  /// Creates reveal animation data for the subtree.
  const StorybookRevealScope({
    required this.sketchProgress,
    required this.paintProgress,
    required this.revealOrigin,
    required super.child,
    super.key,
  });

  /// Progress of the faint pencil underdrawing.
  final double sketchProgress;

  /// Progress of the watercolor bloom revealing the final artwork.
  final double paintProgress;

  /// Point from which the watercolor bloom spreads.
  final Alignment revealOrigin;

  /// Returns the closest reveal animation data, if any.
  static StorybookRevealScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StorybookRevealScope>();
  }

  @override
  bool updateShouldNotify(StorybookRevealScope oldWidget) {
    return sketchProgress != oldWidget.sketchProgress ||
        paintProgress != oldWidget.paintProgress ||
        revealOrigin != oldWidget.revealOrigin;
  }
}

/// Paints [child] first as a faint sketch, then reveals its full color through
/// an irregular, soft-edged watercolor mask.
class StorybookInkReveal extends SingleChildRenderObjectWidget {
  /// Creates a storybook ink reveal.
  const StorybookInkReveal({
    required this.sketchProgress,
    required this.paintProgress,
    required this.revealOrigin,
    required this.circularSketchReveal,
    required this.contentPadding,
    required this.designSize,
    required super.child,
    super.key,
  }) : assert(sketchProgress >= 0 && sketchProgress <= 1),
       assert(paintProgress >= 0 && paintProgress <= 1);

  /// Progress of the pencil underdrawing.
  final double sketchProgress;

  /// Progress of the full-color watercolor reveal.
  final double paintProgress;

  /// Point from which the watercolor mask spreads.
  final Alignment revealOrigin;

  /// Optional circular mask used while the pencil sketch develops.
  final StorybookCircularSketchReveal? circularSketchReveal;

  /// Padding around the logical artwork canvas.
  final EdgeInsets contentPadding;

  /// Logical canvas fitted inside [contentPadding].
  final Size designSize;

  @override
  RenderStorybookInkReveal createRenderObject(BuildContext context) {
    return RenderStorybookInkReveal._(
      sketchProgress: sketchProgress,
      paintProgress: paintProgress,
      revealOrigin: revealOrigin,
      circularSketchReveal: circularSketchReveal,
      contentPadding: contentPadding,
      designSize: designSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderStorybookInkReveal renderObject,
  ) {
    renderObject
      ..sketchProgress = sketchProgress
      ..paintProgress = paintProgress
      ..revealOrigin = revealOrigin
      ..circularSketchReveal = circularSketchReveal
      ..contentPadding = contentPadding
      ..designSize = designSize;
  }
}

/// Render object used by [StorybookInkReveal].
class RenderStorybookInkReveal extends RenderProxyBox {
  /// Creates a render object for the procedural ink reveal.
  RenderStorybookInkReveal._({
    required this._sketchProgress,
    required this._paintProgress,
    required this._revealOrigin,
    required this._circularSketchReveal,
    required this._contentPadding,
    required this._designSize,
  });

  double _sketchProgress;
  double get sketchProgress => _sketchProgress;
  set sketchProgress(double value) {
    if (_sketchProgress == value) return;
    _sketchProgress = value;
    markNeedsPaint();
  }

  double _paintProgress;
  double get paintProgress => _paintProgress;
  set paintProgress(double value) {
    if (_paintProgress == value) return;
    _paintProgress = value;
    markNeedsPaint();
  }

  Alignment _revealOrigin;
  Alignment get revealOrigin => _revealOrigin;
  set revealOrigin(Alignment value) {
    if (_revealOrigin == value) return;
    _revealOrigin = value;
    markNeedsPaint();
  }

  StorybookCircularSketchReveal? _circularSketchReveal;
  StorybookCircularSketchReveal? get circularSketchReveal =>
      _circularSketchReveal;
  set circularSketchReveal(StorybookCircularSketchReveal? value) {
    if (_circularSketchReveal == value) return;
    _circularSketchReveal = value;
    markNeedsPaint();
  }

  EdgeInsets _contentPadding;
  EdgeInsets get contentPadding => _contentPadding;
  set contentPadding(EdgeInsets value) {
    if (_contentPadding == value) return;
    _contentPadding = value;
    markNeedsPaint();
  }

  Size _designSize;
  Size get designSize => _designSize;
  set designSize(Size value) {
    if (_designSize == value) return;
    _designSize = value;
    markNeedsPaint();
  }

  /// Color progress after enforcing sketch-before-color for circular reveals.
  double get effectivePaintProgress {
    if (circularSketchReveal != null && sketchProgress < 0.995) return 0;
    return paintProgress;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final renderChild = child;
    if (renderChild == null) return;

    if (circularSketchReveal == null) {
      _paintLegacyReveal(context, renderChild, offset);
      return;
    }

    _paintCircularReveal(context, renderChild, offset);
  }

  void _paintLegacyReveal(
    PaintingContext context,
    RenderBox renderChild,
    Offset offset,
  ) {
    // Keep the original rendering path isolated so an omitted circular reveal
    // cannot change existing pages' pixels, timing, or phase overlap.

    if (paintProgress >= 0.995) {
      context.paintChild(renderChild, offset);
      return;
    }

    final bounds = offset & size;
    final canvas = context.canvas;

    if (sketchProgress > 0) {
      _paintSketch(context, renderChild, offset, bounds);
    }

    if (paintProgress <= 0) return;

    canvas.saveLayer(bounds, Paint());
    context.paintChild(renderChild, offset);

    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _paintWatercolorMask(canvas, bounds);
    canvas.restore();
    canvas.restore();
  }

  void _paintCircularReveal(
    PaintingContext context,
    RenderBox renderChild,
    Offset offset,
  ) {
    final colorProgress = effectivePaintProgress;
    if (colorProgress >= 0.995) {
      context.paintChild(renderChild, offset);
      return;
    }

    final bounds = offset & size;
    final canvas = context.canvas;

    if (sketchProgress > 0) {
      _paintCircularSketch(context, renderChild, offset, bounds);
    }

    if (colorProgress <= 0) return;

    canvas.saveLayer(bounds, Paint());
    context.paintChild(renderChild, offset);

    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _paintWatercolorMask(canvas, bounds);
    canvas.restore();
    canvas.restore();
  }

  void _paintCircularSketch(
    PaintingContext context,
    RenderBox renderChild,
    Offset offset,
    Rect bounds,
  ) {
    if (sketchProgress >= 0.995) {
      _paintSketch(context, renderChild, offset, bounds);
      return;
    }

    final geometry = resolveStorybookCircularSketchGeometry(
      bounds: bounds,
      contentPadding: contentPadding,
      designSize: designSize,
      configuration: circularSketchReveal!,
      progress: sketchProgress,
    );

    context.canvas.saveLayer(bounds, Paint());
    _paintSketch(context, renderChild, offset, bounds);
    context.canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _paintCircularSketchMask(context.canvas, geometry);
    context.canvas.restore();
    context.canvas.restore();
  }

  void _paintCircularSketchMask(
    Canvas canvas,
    StorybookCircularSketchGeometry geometry,
  ) {
    final outerRadius = geometry.radius + geometry.softEdge;
    final innerRadius = math.max(0.0, geometry.radius - geometry.softEdge);
    final innerStop = (innerRadius / outerRadius).clamp(0.0, 1.0);
    final shaderBounds = Rect.fromCircle(
      center: geometry.origin,
      radius: outerRadius,
    );

    canvas.drawCircle(
      geometry.origin,
      outerRadius,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, innerStop, 1],
        ).createShader(shaderBounds),
    );
  }

  void _paintSketch(
    PaintingContext context,
    RenderBox renderChild,
    Offset offset,
    Rect bounds,
  ) {
    final strength = Curves.easeOutCubic.transform(sketchProgress);
    final edgeTint = ColorFilter.matrix(<double>[
      0.22 * strength,
      0.22 * strength,
      0.22 * strength,
      0,
      0,
      0.16 * strength,
      0.16 * strength,
      0.16 * strength,
      0,
      0,
      0.11 * strength,
      0.11 * strength,
      0.11 * strength,
      0,
      0,
      0.30 * strength,
      0.30 * strength,
      0.30 * strength,
      0,
      0,
    ]);
    const grayscale = ColorFilter.matrix(<double>[
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);

    context.canvas.saveLayer(bounds, Paint()..colorFilter = edgeTint);
    context.canvas.saveLayer(bounds, Paint()..colorFilter = grayscale);
    context.paintChild(renderChild, offset);
    context.canvas.restore();

    context.canvas.saveLayer(
      bounds,
      Paint()
        ..blendMode = BlendMode.difference
        ..colorFilter = grayscale,
    );
    context.paintChild(
      renderChild,
      offset + Offset(size.shortestSide * 0.0032, size.shortestSide * 0.0024),
    );
    context.canvas.restore();
    context.canvas.restore();
  }

  void _paintWatercolorMask(Canvas canvas, Rect bounds) {
    final progress = paintProgress.clamp(0.0, 1.0);
    final shortestSide = bounds.shortestSide;
    final origin = bounds.topLeft + revealOrigin.alongSize(bounds.size);
    final fringePath = Path();
    final bodyPath = Path();

    const columns = 13;
    const rows = 8;

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final noiseX = _noise(column, row, 1) - 0.5;
        final noiseY = _noise(column, row, 2) - 0.5;
        final normalizedX = (column + 0.5 + noiseX * 0.72) / columns;
        final normalizedY = (row + 0.5 + noiseY * 0.72) / rows;
        final center = Offset(
          bounds.left + normalizedX * bounds.width,
          bounds.top + normalizedY * bounds.height,
        );

        final normalizedDistance = _normalizedDistance(
          center: center,
          origin: origin,
          bounds: bounds,
        );
        final timingNoise = (_noise(column, row, 3) - 0.5) * 0.17;
        final threshold = (normalizedDistance * 0.78 + timingNoise).clamp(
          0.0,
          0.86,
        );
        final localProgress = _smoothStep(
          ((progress - threshold) / 0.18).clamp(0.0, 1.0),
        );

        if (localProgress <= 0) continue;

        final radiusNoise = _noise(column, row, 4);
        final baseRadius = shortestSide * (0.065 + radiusNoise * 0.045);
        final radius = baseRadius * (0.24 + localProgress * 1.06);
        final oval = Rect.fromCenter(
          center: center,
          width: radius * (1.25 + _noise(column, row, 5) * 0.9),
          height: radius * (0.85 + _noise(column, row, 6) * 0.7),
        );

        fringePath.addOval(oval.inflate(shortestSide * 0.012));
        if (localProgress > 0.34) {
          bodyPath.addOval(
            Rect.fromCenter(
              center: center,
              width: oval.width * (0.58 + localProgress * 0.42),
              height: oval.height * (0.58 + localProgress * 0.42),
            ),
          );
        }
      }
    }

    final branchPath = _buildBranchPath(
      bounds: bounds,
      origin: origin,
      progress: progress,
    );

    canvas.drawPath(
      fringePath,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortestSide * 0.022),
    );
    canvas.drawPath(
      branchPath,
      Paint()
        ..color = const Color(0xD8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = shortestSide * 0.036
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortestSide * 0.014),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortestSide * 0.008),
    );

    if (progress > 0.84) {
      final finishProgress = _smoothStep((progress - 0.84) / 0.16);
      canvas.drawRect(
        bounds,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: finishProgress),
      );
    }
  }

  Path _buildBranchPath({
    required Rect bounds,
    required Offset origin,
    required double progress,
  }) {
    final path = Path();

    for (var index = 0; index < 9; index++) {
      final angle = -math.pi + (math.pi * 2 * index / 9);
      final reach = 0.42 + _noise(index, 0, 7) * 0.5;
      final target = Offset(
        origin.dx + math.cos(angle) * bounds.width * reach,
        origin.dy + math.sin(angle) * bounds.height * reach,
      );
      final threshold = 0.08 + index * 0.018;
      final branchProgress = _smoothStep(
        ((progress - threshold) / 0.62).clamp(0.0, 1.0),
      );
      if (branchProgress <= 0) continue;

      final end = Offset.lerp(origin, target, branchProgress)!;
      final perpendicular = Offset(-math.sin(angle), math.cos(angle));
      final bend =
          perpendicular *
          bounds.shortestSide *
          (_noise(index, 0, 8) - 0.5) *
          0.32;
      final control = Offset.lerp(origin, end, 0.52)! + bend;

      path
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    }

    return path;
  }

  double _normalizedDistance({
    required Offset center,
    required Offset origin,
    required Rect bounds,
  }) {
    final dx = (center.dx - origin.dx) / bounds.width;
    final dy = (center.dy - origin.dy) / bounds.height;
    final farthestX = math.max(
      (origin.dx - bounds.left) / bounds.width,
      (bounds.right - origin.dx) / bounds.width,
    );
    final farthestY = math.max(
      (origin.dy - bounds.top) / bounds.height,
      (bounds.bottom - origin.dy) / bounds.height,
    );
    final farthestDistance = math.sqrt(
      farthestX * farthestX + farthestY * farthestY,
    );

    return math.sqrt(dx * dx + dy * dy) / farthestDistance;
  }

  double _noise(int x, int y, int seed) {
    final value =
        math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453;
    return value - value.floorToDouble();
  }

  double _smoothStep(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}

/// Geometry shared by the circular sketch painter and its structural tests.
class StorybookCircularSketchGeometry {
  const StorybookCircularSketchGeometry({
    required this.artworkRect,
    required this.origin,
    required this.radius,
    required this.softEdge,
    required this.isComplete,
  });

  final Rect artworkRect;
  final Offset origin;
  final double radius;
  final double softEdge;
  final bool isComplete;

  /// Returns the circular mask opacity at [position].
  double opacityAt(Offset position) {
    if (isComplete) return 1;

    final distance = (position - origin).distance;
    final innerRadius = math.max(0.0, radius - softEdge);
    final outerRadius = radius + softEdge;
    if (distance <= innerRadius) return 1;
    if (distance >= outerRadius) return 0;
    return 1 - (distance - innerRadius) / (outerRadius - innerRadius);
  }
}

/// Resolves a normalized circular reveal against the fitted artwork rectangle.
StorybookCircularSketchGeometry resolveStorybookCircularSketchGeometry({
  required Rect bounds,
  required EdgeInsets contentPadding,
  required Size designSize,
  required StorybookCircularSketchReveal configuration,
  required double progress,
}) {
  final paddedBounds = Rect.fromLTRB(
    bounds.left + contentPadding.left,
    bounds.top + contentPadding.top,
    bounds.right - contentPadding.right,
    bounds.bottom - contentPadding.bottom,
  );
  final availableBounds = paddedBounds.width > 0 && paddedBounds.height > 0
      ? paddedBounds
      : bounds;
  final fittedDesignSize = applyBoxFit(
    BoxFit.contain,
    designSize,
    availableBounds.size,
  ).destination;
  final designRect = Alignment.center.inscribe(
    fittedDesignSize,
    availableBounds,
  );
  final fittedArtworkSize = applyBoxFit(
    BoxFit.contain,
    Size(configuration.artworkAspectRatio, 1),
    designRect.size,
  ).destination;
  final artworkRect = Alignment.center.inscribe(fittedArtworkSize, designRect);
  final origin =
      artworkRect.topLeft + configuration.origin.alongSize(artworkRect.size);
  final artworkShortestSide = artworkRect.shortestSide;
  final softEdge = artworkShortestSide * configuration.softEdgeFraction;
  final initialRadius =
      artworkShortestSide * configuration.initialRadiusFraction;
  final farthestCornerDistance = <Offset>[
    bounds.topLeft,
    bounds.topRight,
    bounds.bottomLeft,
    bounds.bottomRight,
  ].map((corner) => (corner - origin).distance).reduce(math.max);
  final normalizedProgress = progress.clamp(0.0, 1.0);
  final radius =
      initialRadius +
      (farthestCornerDistance + softEdge - initialRadius) * normalizedProgress;

  return StorybookCircularSketchGeometry(
    artworkRect: artworkRect,
    origin: origin,
    radius: radius,
    softEdge: softEdge,
    isComplete: normalizedProgress >= 0.995,
  );
}
