import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PaintingContextCallback;

/// Direction in which the physical sheet travels.
enum StorybookPageCurlDirection { forward, backward }

/// Physical role played by the sheet during navigation.
///
/// A forward page [turnAway] uncovers the next page below it. A backward
/// [coverPrevious] page travels over the current page and settles on top.
enum StorybookPageCurlMotion { turnAway, coverPrevious }

/// Paints a snapshotted page as a flexible, lightly twisted sheet.
///
/// [SnapshotWidget] turns an arbitrary slide into a texture once. The painter
/// then deforms that texture as a small triangle mesh, which avoids rebuilding
/// the slide content for every animation frame.
class StorybookCurlSheet extends StatefulWidget {
  const StorybookCurlSheet({
    required this.progress,
    required this.direction,
    required this.motion,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
    required this.child,
    this.paperOnly = false,
    super.key,
  });

  final double progress;
  final StorybookPageCurlDirection direction;
  final StorybookPageCurlMotion motion;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;
  final Widget child;

  /// Paints a paper-only sheet without creating a texture snapshot.
  ///
  /// Book boundary animations use several blank sheets. Those sheets have no
  /// child artwork to preserve, so rasterizing them can briefly expose a
  /// renderer fallback while the snapshot is being created. Keeping this
  /// opt-in leaves ordinary story pages on the snapshot path while making the
  /// boundary paper deterministic from its very first frame.
  @visibleForTesting
  final bool paperOnly;

  /// Whether this frame contains triangles facing the unprinted paper back.
  ///
  /// Exposed only for geometry regression tests; production painting uses the
  /// same orientation check when splitting front and back vertex batches.
  @visibleForTesting
  bool get debugHasBackFacingSurface => _StorybookCurlGeometry(
    progress: progress,
    direction: direction,
    motion: motion,
    perspective: perspective,
    maxRotation: maxRotation,
    flex: flex,
    twist: twist,
    columns: columns,
    rows: rows,
  ).hasBackFacingSurface;

  @override
  State<StorybookCurlSheet> createState() => _StorybookCurlSheetState();
}

class _StorybookCurlSheetState extends State<StorybookCurlSheet> {
  late final SnapshotController _snapshotController;
  late final _StorybookCurlSnapshotPainter _painter;

  @override
  void initState() {
    super.initState();
    // Let the child complete one ordinary layout/paint pass before asking
    // SnapshotWidget to turn it into a texture. Web's CPU renderer can reach
    // the route transition before a freshly inserted slide has a valid
    // RenderBox size; snapshotting immediately then produces a non-fatal
    // "RenderBox was not laid out" exception and skips the first curl frame.
    _snapshotController = SnapshotController();
    _painter = _StorybookCurlSnapshotPainter(
      progress: widget.progress,
      direction: widget.direction,
      motion: widget.motion,
      perspective: widget.perspective,
      maxRotation: widget.maxRotation,
      flex: widget.flex,
      twist: widget.twist,
      columns: widget.columns,
      rows: widget.rows,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _snapshotController.allowSnapshotting = true;
    });
  }

  @override
  void didUpdateWidget(covariant StorybookCurlSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _painter.update(
      progress: widget.progress,
      direction: widget.direction,
      motion: widget.motion,
      perspective: widget.perspective,
      maxRotation: widget.maxRotation,
      flex: widget.flex,
      twist: widget.twist,
      columns: widget.columns,
      rows: widget.rows,
    );
  }

  @override
  void dispose() {
    _snapshotController.dispose();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paperOnly) {
      final paper = CustomPaint(
        painter: _StorybookPaperCurlPainter(
          _StorybookCurlGeometry(
            progress: widget.progress,
            direction: widget.direction,
            motion: widget.motion,
            perspective: widget.perspective,
            maxRotation: widget.maxRotation,
            flex: widget.flex,
            twist: widget.twist,
            columns: widget.columns,
            rows: widget.rows,
          ),
        ),
        child: const SizedBox.expand(),
      );

      if (widget.motion != StorybookPageCurlMotion.coverPrevious) {
        return paper;
      }

      return ClipPath(
        key: const ValueKey('storybook-page-cover-sheet-clip'),
        clipper: _StorybookCurlSheetClipper(
          _StorybookCurlGeometry(
            progress: widget.progress,
            direction: widget.direction,
            motion: widget.motion,
            perspective: widget.perspective,
            maxRotation: widget.maxRotation,
            flex: widget.flex,
            twist: widget.twist,
            columns: widget.columns,
            rows: widget.rows,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: paper,
      );
    }

    final snapshot = SnapshotWidget(
      controller: _snapshotController,
      painter: _painter,
      mode: SnapshotMode.permissive,
      autoresize: true,
      child: widget.child,
    );

    if (widget.motion != StorybookPageCurlMotion.coverPrevious) {
      return snapshot;
    }

    // SnapshotWidget intentionally paints its live child once before its first
    // texture is available. For an incoming covering page that ordinary frame
    // would expose the destination page across the whole screen for a moment.
    // Keep every paint path, including that pre-snapshot frame, inside the
    // physical silhouette of the sheet from the very first route frame.
    return ClipPath(
      key: const ValueKey('storybook-page-cover-sheet-clip'),
      clipper: _StorybookCurlSheetClipper(
        _StorybookCurlGeometry(
          progress: widget.progress,
          direction: widget.direction,
          motion: widget.motion,
          perspective: widget.perspective,
          maxRotation: widget.maxRotation,
          flex: widget.flex,
          twist: widget.twist,
          columns: widget.columns,
          rows: widget.rows,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: snapshot,
    );
  }
}

/// Reveals the new paper along the same flexible edge as [StorybookCurlSheet].
class StorybookCurlReveal extends StatelessWidget {
  const StorybookCurlReveal({
    required this.progress,
    required this.direction,
    required this.motion,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
    required this.child,
    this.clipKey,
    this.shadowFactor = 1,
    super.key,
  }) : assert(shadowFactor >= 0 && shadowFactor <= 1);

  final double progress;
  final StorybookPageCurlDirection direction;
  final StorybookPageCurlMotion motion;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;
  final Widget child;
  final Key? clipKey;

  /// Scales the fold shadow without changing the paper geometry.
  ///
  /// Boundary scenes use a lighter value because their blank paper sheets
  /// already paint a narrow edge shadow. Keeping the broad default preserves
  /// the stronger depth cue for ordinary illustrated page turns.
  final double shadowFactor;

  @override
  Widget build(BuildContext context) {
    final geometry = _StorybookCurlGeometry(
      progress: progress,
      direction: direction,
      motion: motion,
      perspective: perspective,
      maxRotation: maxRotation,
      flex: flex,
      twist: twist,
      columns: columns,
      rows: rows,
    );

    return ClipPath(
      key: clipKey,
      clipper: _StorybookCurlRevealClipper(geometry),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _StorybookCurlShadowPainter(
                  geometry,
                  shadowFactor: shadowFactor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorybookCurlSnapshotPainter extends SnapshotPainter {
  _StorybookCurlSnapshotPainter({
    required double progress,
    required StorybookPageCurlDirection direction,
    required StorybookPageCurlMotion motion,
    required double perspective,
    required double maxRotation,
    required double flex,
    required double twist,
    required int columns,
    required int rows,
  }) : _geometry = _StorybookCurlGeometry(
         progress: progress,
         direction: direction,
         motion: motion,
         perspective: perspective,
         maxRotation: maxRotation,
         flex: flex,
         twist: twist,
         columns: columns,
         rows: rows,
       );

  _StorybookCurlGeometry _geometry;

  void update({
    required double progress,
    required StorybookPageCurlDirection direction,
    required StorybookPageCurlMotion motion,
    required double perspective,
    required double maxRotation,
    required double flex,
    required double twist,
    required int columns,
    required int rows,
  }) {
    final next = _StorybookCurlGeometry(
      progress: progress,
      direction: direction,
      motion: motion,
      perspective: perspective,
      maxRotation: maxRotation,
      flex: flex,
      twist: twist,
      columns: columns,
      rows: rows,
    );
    if (next == _geometry) return;

    _geometry = next;
    notifyListeners();
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    if (size.isEmpty) return;

    final mesh = _geometry.buildMesh(
      offset: offset,
      size: size,
      sourceSize: sourceSize,
    );
    final shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList(_identityMatrix4),
      filterQuality: FilterQuality.medium,
    );
    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    final canvas = context.canvas
      ..save()
      ..clipRect(offset & size);

    if (_geometry.motion == StorybookPageCurlMotion.coverPrevious &&
        _geometry.turnEnvelope > 0.001) {
      // During backward navigation this mesh is the previous page travelling
      // above the current one. Its advancing edge must cast onto the page
      // below; without this shadow the motion reads as another reveal/peel.
      canvas
        ..drawPath(
          mesh.visibleEdge,
          Paint()
            ..color = Colors.black.withValues(
              alpha: 0.28 * _geometry.turnEnvelope,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(22, size.width * 0.115)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              math.max(15, size.width * 0.070),
            )
            ..isAntiAlias = true,
        )
        ..drawPath(
          mesh.visibleEdge,
          Paint()
            ..color = Colors.black.withValues(
              alpha: 0.14 * _geometry.turnEnvelope,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2, size.width / 650)
            ..isAntiAlias = true,
        );
    }

    if (mesh.frontVertices case final frontVertices?) {
      canvas.drawVertices(frontVertices, BlendMode.modulate, paint);
    }
    if (mesh.backVertices case final backVertices?) {
      // Past 90 degrees the free section folds towards the viewer, so its
      // unprinted paper back sits above the still-visible front surface.
      canvas.drawVertices(
        backVertices,
        BlendMode.modulate,
        Paint()
          ..color = const Color(0xFFFFFDF8)
          ..isAntiAlias = true,
      );
    }
    if (!mesh.foldEdge.getBounds().isEmpty) {
      canvas
        ..drawPath(
          mesh.foldEdge,
          Paint()
            ..color = Colors.black.withValues(
              alpha: 0.17 * _geometry.turnEnvelope,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(8, size.width * 0.022)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              math.max(5, size.width * 0.014),
            )
            ..isAntiAlias = true,
        )
        ..drawPath(
          mesh.foldEdge,
          Paint()
            ..color = const Color(0xFFFFFDF8)
                .withValues(alpha: 0.82 * _geometry.turnEnvelope)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, size.width / 720)
            ..isAntiAlias = true,
        );
    }
    canvas
      ..drawPath(
        mesh.visibleEdge,
        Paint()
          ..color = const Color(0xFFFFFDF8)
              .withValues(alpha: 0.72 * _geometry.turnEnvelope)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, size.width / 900)
          ..isAntiAlias = true,
      )
      ..restore();

    mesh.dispose();
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    // Platform views cannot be converted to a texture. Keep them usable instead
    // of failing the whole transition; ordinary Flutter slides use the mesh.
    // A covering page is clipped to its projected silhouette so that the first
    // pre-snapshot frame cannot flash as a fully opaque previous page.
    if (_geometry.motion == StorybookPageCurlMotion.coverPrevious) {
      context.canvas
        ..save()
        ..clipPath(_geometry.sheetPath(size).shift(offset));
      painter(context, offset);
      context.canvas.restore();
      return;
    }

    painter(context, offset);
  }

  @override
  bool shouldRepaint(covariant _StorybookCurlSnapshotPainter oldPainter) {
    return _geometry != oldPainter._geometry;
  }
}

class _StorybookCurlRevealClipper extends CustomClipper<Path> {
  const _StorybookCurlRevealClipper(this.geometry);

  final _StorybookCurlGeometry geometry;

  @override
  Path getClip(Size size) => geometry.revealPath(size);

  @override
  bool shouldReclip(covariant _StorybookCurlRevealClipper oldClipper) {
    return geometry != oldClipper.geometry;
  }
}

class _StorybookCurlSheetClipper extends CustomClipper<Path> {
  const _StorybookCurlSheetClipper(this.geometry);

  final _StorybookCurlGeometry geometry;

  @override
  Path getClip(Size size) => geometry.sheetPath(size);

  @override
  bool shouldReclip(covariant _StorybookCurlSheetClipper oldClipper) {
    return geometry != oldClipper.geometry;
  }
}

class _StorybookCurlShadowPainter extends CustomPainter {
  const _StorybookCurlShadowPainter(
    this.geometry, {
    required this.shadowFactor,
  });

  final _StorybookCurlGeometry geometry;
  final double shadowFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = geometry.turnEnvelope;
    final factor = shadowFactor.clamp(0.0, 1.0);
    if (strength <= 0.001 || factor <= 0.001) return;

    final edge = geometry.freeEdgePath(size);
    final width = size.width;
    final widthFactor = 0.035 + 0.070 * factor;
    final blurFactor = 0.022 + 0.043 * factor;
    canvas.drawPath(
      edge,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24 * strength * factor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(10, width * widthFactor)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(6, width * blurFactor),
        )
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      edge,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12 * strength * factor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, width / 800 * factor)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _StorybookCurlShadowPainter oldDelegate) {
    return geometry != oldDelegate.geometry ||
        shadowFactor != oldDelegate.shadowFactor;
  }
}

/// Paints a blank sheet directly from the curl mesh.
///
/// Boundary pages are deliberately content-free. Drawing their paper surface
/// directly avoids asking [SnapshotWidget] for a texture that has no useful
/// artwork and, more importantly, guarantees an opaque paper fallback while a
/// cover is moving over the tabletop.
class _StorybookPaperCurlPainter extends CustomPainter {
  const _StorybookPaperCurlPainter(this.geometry);

  final _StorybookCurlGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final mesh = geometry.buildMesh(
      offset: Offset.zero,
      size: size,
      sourceSize: size,
    );
    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    if (geometry.turnEnvelope > 0.001) {
      canvas.drawPath(
        mesh.visibleEdge,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08 * geometry.turnEnvelope)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(7, size.width * 0.018)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(4, size.width * 0.010),
          )
          ..isAntiAlias = true,
      );
    }

    if (mesh.frontVertices case final frontVertices?) {
      canvas.drawVertices(
        frontVertices,
        BlendMode.srcOver,
        Paint()..isAntiAlias = true,
      );
    }
    if (mesh.backVertices case final backVertices?) {
      canvas.drawVertices(
        backVertices,
        BlendMode.srcOver,
        Paint()..isAntiAlias = true,
      );
    }

    if (!mesh.foldEdge.getBounds().isEmpty) {
      canvas.drawPath(
        mesh.foldEdge,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08 * geometry.turnEnvelope)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3, size.width * 0.008)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(2, size.width * 0.004),
          )
          ..isAntiAlias = true,
      );
    }

    canvas.restore();
    mesh.dispose();
  }

  @override
  bool shouldRepaint(covariant _StorybookPaperCurlPainter oldDelegate) {
    return geometry != oldDelegate.geometry;
  }
}

@immutable
class _StorybookCurlGeometry {
  const _StorybookCurlGeometry({
    required this.progress,
    required this.direction,
    required this.motion,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
  });

  final double progress;
  final StorybookPageCurlDirection direction;
  final StorybookPageCurlMotion motion;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;

  double get normalizedProgress => progress.clamp(0.0, 1.0);

  double get turnEnvelope => math.sin(normalizedProgress * math.pi).abs();

  bool get hasBackFacingSurface {
    for (var row = 0; row < rows; row++) {
      final v = (row + 0.5) / rows;
      for (var column = 0; column < columns; column++) {
        final u = (column + 0.5) / columns;
        if (math.cos(_localAngle(u, v)) < 0) return true;
      }
    }
    return false;
  }

  _StorybookCurlMesh buildMesh({
    required Offset offset,
    required Size size,
    required Size sourceSize,
  }) {
    final projectedRows = <List<Offset>>[
      for (var row = 0; row <= rows; row++) _projectRow(size, row / rows),
    ];
    final frontPositions = <Offset>[];
    final frontTextureCoordinates = <Offset>[];
    final frontColors = <Color>[];
    final frontIndices = <int>[];
    final backPositions = <Offset>[];
    final backColors = <Color>[];
    final backIndices = <int>[];

    double textureX(double u) {
      final sourceU = direction == StorybookPageCurlDirection.forward
          ? u
          : 1 - u;
      return sourceU * sourceSize.width;
    }

    for (var row = 0; row < rows; row++) {
      final v0 = row / rows;
      final v1 = (row + 1) / rows;
      for (var column = 0; column < columns; column++) {
        final u0 = column / columns;
        final u1 = (column + 1) / columns;
        final points = <Offset>[
          projectedRows[row][column] + offset,
          projectedRows[row][column + 1] + offset,
          projectedRows[row + 1][column] + offset,
          projectedRows[row + 1][column + 1] + offset,
        ];
        final isBackFacing =
            math.cos(_localAngle((u0 + u1) / 2, (v0 + v1) / 2)) < 0;

        if (isBackFacing) {
          final base = backPositions.length;
          backPositions.addAll(points);
          backColors.addAll([
            _backLightColor(u0, v0),
            _backLightColor(u1, v0),
            _backLightColor(u0, v1),
            _backLightColor(u1, v1),
          ]);
          backIndices.addAll([
            base,
            base + 2,
            base + 1,
            base + 1,
            base + 2,
            base + 3,
          ]);
          continue;
        }

        final base = frontPositions.length;
        frontPositions.addAll(points);
        frontTextureCoordinates.addAll([
          Offset(textureX(u0), v0 * sourceSize.height),
          Offset(textureX(u1), v0 * sourceSize.height),
          Offset(textureX(u0), v1 * sourceSize.height),
          Offset(textureX(u1), v1 * sourceSize.height),
        ]);
        frontColors.addAll([
          _lightColor(u0, v0),
          _lightColor(u1, v0),
          _lightColor(u0, v1),
          _lightColor(u1, v1),
        ]);
        frontIndices.addAll([
          base,
          base + 2,
          base + 1,
          base + 1,
          base + 2,
          base + 3,
        ]);
      }
    }

    final visibleEdgePoints = <Offset>[];
    final foldEdge = Path();
    var foldStarted = false;
    for (var row = 0; row <= rows; row++) {
      final v = row / rows;
      final projectedRow = projectedRows[row];
      var visiblePoint = projectedRow.first;
      for (final point in projectedRow.skip(1)) {
        final isFurtherIntoPage =
            direction == StorybookPageCurlDirection.forward
            ? point.dx > visiblePoint.dx
            : point.dx < visiblePoint.dx;
        if (isFurtherIntoPage) visiblePoint = point;
      }
      visibleEdgePoints.add(visiblePoint + offset);

      var minimumAngle = double.infinity;
      var maximumAngle = double.negativeInfinity;
      var foldColumn = 0;
      var foldError = double.infinity;
      for (var column = 1; column <= columns; column++) {
        final angle = _localAngle((column - 0.5) / columns, v);
        minimumAngle = math.min(minimumAngle, angle);
        maximumAngle = math.max(maximumAngle, angle);
        final error = (angle - math.pi / 2).abs();
        if (error < foldError) {
          foldError = error;
          foldColumn = column;
        }
      }
      if (minimumAngle <= math.pi / 2 && maximumAngle >= math.pi / 2) {
        final point = projectedRow[foldColumn] + offset;
        if (foldStarted) {
          foldEdge.lineTo(point.dx, point.dy);
        } else {
          foldEdge.moveTo(point.dx, point.dy);
          foldStarted = true;
        }
      }
    }

    final visibleEdge = Path()
      ..moveTo(visibleEdgePoints.first.dx, visibleEdgePoints.first.dy);
    for (final point in visibleEdgePoints.skip(1)) {
      visibleEdge.lineTo(point.dx, point.dy);
    }

    return _StorybookCurlMesh(
      frontVertices: frontPositions.isEmpty
          ? null
          : ui.Vertices(
              VertexMode.triangles,
              frontPositions,
              textureCoordinates: frontTextureCoordinates,
              colors: frontColors,
              indices: frontIndices,
            ),
      backVertices: backPositions.isEmpty
          ? null
          : ui.Vertices(
              VertexMode.triangles,
              backPositions,
              colors: backColors,
              indices: backIndices,
            ),
      visibleEdge: visibleEdge,
      foldEdge: foldEdge,
    );
  }

  Path revealPath(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      sheetPath(size),
    );
  }

  Path sheetPath(Size size) {
    final edge = _visibleEdgePoints(size);
    final hingeX = _hingeX(size);
    final sheet = Path()..moveTo(hingeX, 0);
    for (final point in edge) {
      sheet.lineTo(point.dx, point.dy);
    }
    return sheet
      ..lineTo(hingeX, size.height)
      ..close();
  }

  Path freeEdgePath(Size size) {
    final edge = _visibleEdgePoints(size);
    final path = Path()..moveTo(edge.first.dx, edge.first.dy);
    for (final point in edge.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  List<Offset> _visibleEdgePoints(Size size) {
    return [
      for (var row = 0; row <= rows; row++)
        _visiblePoint(_projectRow(size, row / rows)),
    ];
  }

  Offset _visiblePoint(List<Offset> rowPoints) {
    var visiblePoint = rowPoints.first;
    for (final point in rowPoints.skip(1)) {
      final isFurtherIntoPage = direction == StorybookPageCurlDirection.forward
          ? point.dx > visiblePoint.dx
          : point.dx < visiblePoint.dx;
      if (isFurtherIntoPage) visiblePoint = point;
    }
    return visiblePoint;
  }

  List<Offset> _projectRow(Size size, double v) {
    final result = <Offset>[Offset(_hingeX(size), v * size.height)];
    final segmentWidth = size.width / columns;
    var distanceFromHinge = 0.0;
    var depth = 0.0;

    for (var column = 1; column <= columns; column++) {
      final segmentU = (column - 0.5) / columns;
      final vertexU = column / columns;
      final angle = _localAngle(segmentU, v);
      distanceFromHinge += segmentWidth * math.cos(angle);
      depth += segmentWidth * math.sin(angle);

      final horizontalRidgeDepth =
          size.width *
          0.10 *
          _gripEnvelope *
          _horizontalGrip(vertexU) *
          _horizontalRidge(v);
      final projectedDepth = depth + horizontalRidgeDepth;
      final perspectiveScale = 1 + perspective * projectedDepth;
      final projectedDistance = distanceFromHinge / perspectiveScale;
      final baseY = v * size.height;
      final projectedY =
          size.height / 2 + (baseY - size.height / 2) / perspectiveScale;
      final projectedX = direction == StorybookPageCurlDirection.forward
          ? projectedDistance
          : size.width - projectedDistance;
      result.add(Offset(projectedX, projectedY));
    }

    return result;
  }

  double _hingeX(Size size) {
    return direction == StorybookPageCurlDirection.forward ? 0 : size.width;
  }

  double _localAngle(double u, double v) {
    final p = normalizedProgress;
    final envelope = turnEnvelope;

    // The reference reads like a hand sliding under the horizontal midpoint
    // of the free edge. Broad rotation therefore propagates inwards from that
    // edge; the horizontal ridge itself is modelled as depth and lighting,
    // rather than over-rotating only the middle row into an hourglass shape.
    final verticalDistance = ((v - 0.5).abs() * 2).clamp(0.0, 1.0);
    // A page is not a rigid door: the fold created under the free edge travels
    // horizontally towards the binding. Keeping a sizeable phase difference
    // across `u` leaves the bound half front-facing while the lifted half has
    // already passed 90 degrees, which is what exposes the real paper back.
    // The smaller vertical delay makes the hand-height row lead the corners
    // without pinching the silhouette into an hourglass.
    final horizontalTravelDelay = 0.30 * math.pow(1 - u, 1.15).toDouble();
    final handHeightDelay = 0.04 * math.pow(verticalDistance, 1.45).toDouble();
    final propagationDelay = horizontalTravelDelay + handHeightDelay;
    final propagatedProgress = ((p - propagationDelay) / (1 - propagationDelay))
        .clamp(0.0, 1.0);
    final broadTurn =
        maxRotation * (0.5 - 0.5 * math.cos(math.pi * propagatedProgress));

    final gripLift =
        flex * 0.08 * _gripEnvelope * _horizontalGrip(u) * _horizontalRidge(v);

    // Once the central lift has formed, retain a broad C-shaped bend while the
    // lifted ridge travels across the page.
    final broadFlex =
        flex *
        0.34 *
        envelope *
        _smoothStep(0.20, 0.58, p) *
        math.sin(math.pi * u);

    // A restrained late twist prevents the sheet from reading as an extruded
    // vertical strip without stealing the initial motion from the midpoint.
    final verticalPosition = (v - 0.5) * 2;
    final twistPhase =
        0.65 * math.sin(2 * math.pi * p) - 0.35 * math.sin(math.pi * p);
    final verticalTwist =
        twist * verticalPosition * twistPhase * _smoothStep(0.24, 0.48, p);

    return (broadTurn + gripLift + broadFlex + verticalTwist).clamp(
      0.0,
      maxRotation,
    );
  }

  double _smoothStep(double edge0, double edge1, double value) {
    final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  double get _gripEnvelope {
    final timeline = (normalizedProgress / 0.82).clamp(0.0, 1.0);
    return math.sin(math.pi * timeline);
  }

  double get _gripReach {
    final travel = _smoothStep(0.02, 0.62, normalizedProgress);
    return 0.20 + 0.80 * travel;
  }

  double _horizontalGrip(double u) {
    final ridgeStart = 1 - _gripReach;
    return _smoothStep(ridgeStart - 0.06, ridgeStart + 0.18, u);
  }

  double get _ridgeWidth {
    return 0.13 + 0.62 * _smoothStep(0.08, 0.40, normalizedProgress);
  }

  double _horizontalRidge(double v) {
    return math.exp(-0.5 * math.pow((v - 0.5) / _ridgeWidth, 2));
  }

  Color _lightColor(double u, double v) {
    final angle = _localAngle(u, v);
    final facing = math.cos(angle).abs();
    final broadShade = 0.22 + 0.78 * math.pow(facing, 0.80);
    final movingShade = 0.20 * turnEnvelope * math.sin(math.pi * u).abs();
    final rimLight =
        0.08 *
        turnEnvelope *
        math.exp(-math.pow((1 - u) / 0.075, 2).toDouble());
    final ridgePosition = (v - 0.5) / _ridgeWidth;
    final ridgeSlope =
        ridgePosition *
        _horizontalRidge(v) *
        _horizontalGrip(u) *
        _gripEnvelope;
    final ridgeBand = _horizontalRidge(v) * _horizontalGrip(u) * _gripEnvelope;
    final brightness =
        (broadShade -
                movingShade +
                rimLight -
                0.07 * ridgeBand -
                0.20 * ridgeSlope)
            .clamp(0.26, 1.0);
    final channel = (255 * brightness).round();
    return Color.fromARGB(255, channel, channel, channel);
  }

  Color _backLightColor(double u, double v) {
    final angle = _localAngle(u, v);
    final facing = math.cos(angle).abs();
    final foldShade = math.exp(
      -math.pow((angle - math.pi / 2) / 0.26, 2).toDouble(),
    );
    final verticalWarmth = 0.025 * turnEnvelope * math.cos((v - 0.5) * math.pi);
    final brightness =
        (0.70 +
                0.30 * math.pow(facing, 0.48) -
                0.18 * foldShade +
                verticalWarmth)
            .clamp(0.42, 1.0);
    return Color.fromARGB(
      255,
      (255 * brightness).round(),
      (253 * brightness).round(),
      (248 * brightness).round(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _StorybookCurlGeometry &&
        progress == other.progress &&
        direction == other.direction &&
        motion == other.motion &&
        perspective == other.perspective &&
        maxRotation == other.maxRotation &&
        flex == other.flex &&
        twist == other.twist &&
        columns == other.columns &&
        rows == other.rows;
  }

  @override
  int get hashCode => Object.hash(
    progress,
    direction,
    motion,
    perspective,
    maxRotation,
    flex,
    twist,
    columns,
    rows,
  );
}

class _StorybookCurlMesh {
  const _StorybookCurlMesh({
    required this.frontVertices,
    required this.backVertices,
    required this.visibleEdge,
    required this.foldEdge,
  });

  final ui.Vertices? frontVertices;
  final ui.Vertices? backVertices;
  final Path visibleEdge;
  final Path foldEdge;

  void dispose() {
    frontVertices?.dispose();
    backVertices?.dispose();
  }
}

const _identityMatrix4 = <double>[
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  1,
];
