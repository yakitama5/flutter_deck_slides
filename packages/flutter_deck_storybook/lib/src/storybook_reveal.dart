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
    this.inkProgress,
    required super.child,
    super.key,
  }) : assert(inkProgress == null || (inkProgress >= 0 && inkProgress <= 1));

  /// Progress of the faint pencil underdrawing.
  final double sketchProgress;

  /// Progress of the watercolor bloom revealing the final artwork.
  final double paintProgress;

  /// Point from which the watercolor bloom spreads.
  final Alignment revealOrigin;

  /// Normalized progress of the whole blank-paper-to-color sequence.
  ///
  /// This is supplied by the storybook transition for page-specific phases.
  /// It is nullable so older callers that construct a scope directly keep
  /// their existing sketch and paint progress semantics.
  final double? inkProgress;

  /// Returns the closest reveal animation data, if any.
  static StorybookRevealScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StorybookRevealScope>();
  }

  @override
  bool updateShouldNotify(StorybookRevealScope oldWidget) {
    return sketchProgress != oldWidget.sketchProgress ||
        paintProgress != oldWidget.paintProgress ||
        revealOrigin != oldWidget.revealOrigin ||
        inkProgress != oldWidget.inkProgress;
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
    this.inkProgress,
    required super.child,
    super.key,
  }) : assert(sketchProgress >= 0 && sketchProgress <= 1),
       assert(paintProgress >= 0 && paintProgress <= 1),
       assert(inkProgress == null || (inkProgress >= 0 && inkProgress <= 1));

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

  /// Normalized progress of the whole reveal sequence, when provided by the
  /// transition. This is used only by [circularSketchReveal].
  final double? inkProgress;

  @override
  RenderStorybookInkReveal createRenderObject(BuildContext context) {
    return RenderStorybookInkReveal._(
      sketchProgress: sketchProgress,
      paintProgress: paintProgress,
      revealOrigin: revealOrigin,
      circularSketchReveal: circularSketchReveal,
      contentPadding: contentPadding,
      designSize: designSize,
      inkProgress: inkProgress,
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
      ..designSize = designSize
      ..inkProgress = inkProgress;
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
    required this._inkProgress,
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

  double? _inkProgress;
  double? get inkProgress => _inkProgress;
  set inkProgress(double? value) {
    if (_inkProgress == value) return;
    _inkProgress = value;
    markNeedsPaint();
  }

  /// Color progress after enforcing sketch-before-color for circular reveals.
  double get effectivePaintProgress {
    final configuration = circularSketchReveal;
    if (configuration == null) return paintProgress;
    if (inkProgress == null) {
      return sketchProgress < 0.995 ? 0 : paintProgress;
    }
    return _circularSketchPhase.colorProgress;
  }

  /// Progress of the focused circular line phase.
  double get circularFocusLineProgress {
    final configuration = circularSketchReveal;
    if (configuration == null) return 0;
    if (inkProgress == null) return sketchProgress.clamp(0.0, 1.0);
    return _circularSketchPhase.focusLineProgress;
  }

  /// Progress of the short fade that reveals the surrounding line.
  double get circularSurroundingFadeProgress {
    if (circularSketchReveal == null || inkProgress == null) return 0;
    return _circularSketchPhase.surroundingFadeProgress;
  }

  _CircularSketchPhase get _circularSketchPhase {
    final configuration = circularSketchReveal!;
    final sequenceProgress = inkProgress;
    if (sequenceProgress == null) {
      return _CircularSketchPhase(
        focusLineProgress: sketchProgress.clamp(0.0, 1.0),
        surroundingFadeProgress: 0,
        colorProgress: sketchProgress < 0.995
            ? 0
            : paintProgress.clamp(0.0, 1.0),
      );
    }

    // Keep the existing blank-paper interval and drawing sound cue intact.
    // The configurable fractions divide only the active reveal that follows
    // it, so the phase boundaries can be tuned without changing page turns.
    const blankPaperFraction = 0.11;
    final activeProgress =
        ((sequenceProgress - blankPaperFraction) / (1 - blankPaperFraction))
            .clamp(0.0, 1.0);
    final focusEnd = configuration.focusLineFraction;
    final fadeEnd =
        configuration.focusLineFraction + configuration.surroundingFadeFraction;
    final focusRaw = (activeProgress / focusEnd).clamp(0.0, 1.0);
    final fadeRaw =
        ((activeProgress - focusEnd) / configuration.surroundingFadeFraction)
            .clamp(0.0, 1.0);
    const phaseBoundaryEpsilon = 1e-9;
    final colorRaw = activeProgress <= fadeEnd + phaseBoundaryEpsilon
        ? 0.0
        : ((activeProgress - fadeEnd) / (1 - fadeEnd)).clamp(0.0, 1.0);

    return _CircularSketchPhase(
      focusLineProgress: Curves.easeOutCubic.transform(focusRaw),
      surroundingFadeProgress: Curves.easeInOutCubic.transform(fadeRaw),
      colorProgress: Curves.easeInOutCubic.transform(colorRaw),
    );
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
    final phase = _circularSketchPhase;
    final colorProgress = phase.colorProgress;
    if (colorProgress >= 0.995) {
      context.paintChild(renderChild, offset);
      return;
    }

    final bounds = offset & size;
    final canvas = context.canvas;

    if (phase.focusLineProgress > 0 ||
        phase.surroundingFadeProgress > 0 ||
        (inkProgress == null && sketchProgress > 0)) {
      _paintCircularSketch(context, renderChild, offset, bounds, phase);
    }

    if (colorProgress <= 0) return;

    // The sketch and watercolor are each composited once over the paper. The
    // surrounding fade is part of the single sketch mask, avoiding a second
    // translucent copy of the page that could flash against the paper.
    canvas.saveLayer(bounds, Paint());
    context.paintChild(renderChild, offset);

    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _paintWatercolorMask(canvas, bounds, paintProgress: colorProgress);
    canvas.restore();
    canvas.restore();
  }

  void _paintCircularSketch(
    PaintingContext context,
    RenderBox renderChild,
    Offset offset,
    Rect bounds,
    _CircularSketchPhase phase,
  ) {
    final configuration = circularSketchReveal!;
    final geometry = resolveStorybookCircularSketchGeometry(
      bounds: bounds,
      contentPadding: contentPadding,
      designSize: designSize,
      configuration: configuration,
      progress: phase.focusLineProgress,
      // A scope created directly by an older caller has no whole-sequence
      // progress. Preserve the pre-phase circular behavior in that case; the
      // three-stage radius is used only when the transition supplies it.
      focusRadiusFraction: inkProgress == null
          ? 1
          : configuration.focusRadiusFraction,
      surroundingFadeProgress: phase.surroundingFadeProgress,
    );
    final sketchProgress = phase.surroundingFadeProgress > 0
        ? 1.0
        : phase.focusLineProgress;

    if (geometry.isComplete) {
      _paintSketch(context, renderChild, offset, bounds, sketchProgress: 1);
      return;
    }

    context.canvas.saveLayer(bounds, Paint());
    _paintSketch(
      context,
      renderChild,
      offset,
      bounds,
      sketchProgress: sketchProgress,
    );
    context.canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _paintCircularSketchMask(context.canvas, bounds, geometry);
    context.canvas.restore();
    context.canvas.restore();
  }

  void _paintCircularSketchMask(
    Canvas canvas,
    Rect bounds,
    StorybookCircularSketchGeometry geometry,
  ) {
    final surroundingFade = geometry.surroundingFadeProgress;
    if (surroundingFade > 0) {
      canvas.drawRect(
        bounds,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: surroundingFade),
      );
    }

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
    Rect bounds, {
    double? sketchProgress,
  }) {
    final progress = (sketchProgress ?? this.sketchProgress).clamp(0.0, 1.0);
    final strength = Curves.easeOutCubic.transform(progress);
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

  void _paintWatercolorMask(
    Canvas canvas,
    Rect bounds, {
    double? paintProgress,
  }) {
    final progress = (paintProgress ?? this.paintProgress).clamp(0.0, 1.0);
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

class _CircularSketchPhase {
  const _CircularSketchPhase({
    required this.focusLineProgress,
    required this.surroundingFadeProgress,
    required this.colorProgress,
  });

  final double focusLineProgress;
  final double surroundingFadeProgress;
  final double colorProgress;
}

/// Geometry shared by the circular sketch painter and its structural tests.
class StorybookCircularSketchGeometry {
  const StorybookCircularSketchGeometry({
    required this.artworkRect,
    required this.origin,
    required this.radius,
    required this.softEdge,
    required this.surroundingFadeProgress,
    required this.isComplete,
  });

  final Rect artworkRect;
  final Offset origin;
  final double radius;
  final double softEdge;
  final double surroundingFadeProgress;
  final bool isComplete;

  /// Returns the circular mask opacity at [position].
  double opacityAt(Offset position) {
    if (isComplete) return 1;

    final distance = (position - origin).distance;
    final innerRadius = math.max(0.0, radius - softEdge);
    final outerRadius = radius + softEdge;
    final circularOpacity = distance <= innerRadius
        ? 1.0
        : distance >= outerRadius
        ? 0.0
        : 1 - (distance - innerRadius) / (outerRadius - innerRadius);
    return math.max(circularOpacity, surroundingFadeProgress);
  }
}

/// Resolves a normalized circular reveal against the fitted artwork rectangle.
StorybookCircularSketchGeometry resolveStorybookCircularSketchGeometry({
  required Rect bounds,
  required EdgeInsets contentPadding,
  required Size designSize,
  required StorybookCircularSketchReveal configuration,
  required double progress,
  double focusRadiusFraction = 1,
  double surroundingFadeProgress = 0,
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
  final normalizedFocusRadius = focusRadiusFraction.clamp(0.0, 1.0);
  final normalizedSurroundingFade = surroundingFadeProgress.clamp(0.0, 1.0);
  final targetRadius =
      initialRadius +
      (farthestCornerDistance + softEdge - initialRadius) *
          normalizedFocusRadius;
  final radius =
      initialRadius + (targetRadius - initialRadius) * normalizedProgress;

  return StorybookCircularSketchGeometry(
    artworkRect: artworkRect,
    origin: origin,
    radius: radius,
    softEdge: softEdge,
    surroundingFadeProgress: normalizedSurroundingFade,
    isComplete:
        normalizedSurroundingFade >= 0.995 ||
        (normalizedProgress >= 0.995 && normalizedFocusRadius >= 0.995),
  );
}
