import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PaintingContextCallback;

/// Direction in which the physical sheet travels.
enum StorybookPageCurlDirection { forward, backward }

/// Paints a snapshotted page as a flexible, lightly twisted sheet.
///
/// [SnapshotWidget] turns an arbitrary slide into a texture once. The painter
/// then deforms that texture as a small triangle mesh, which avoids rebuilding
/// the slide content for every animation frame.
class StorybookCurlSheet extends StatefulWidget {
  const StorybookCurlSheet({
    required this.progress,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
    required this.child,
    super.key,
  });

  final double progress;
  final StorybookPageCurlDirection direction;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;
  final Widget child;

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
    return SnapshotWidget(
      controller: _snapshotController,
      painter: _painter,
      mode: SnapshotMode.permissive,
      autoresize: true,
      child: widget.child,
    );
  }
}

/// Reveals the new paper along the same flexible edge as [StorybookCurlSheet].
class StorybookCurlReveal extends StatelessWidget {
  const StorybookCurlReveal({
    required this.progress,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
    required this.child,
    this.clipKey,
    super.key,
  });

  final double progress;
  final StorybookPageCurlDirection direction;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;
  final Widget child;
  final Key? clipKey;

  @override
  Widget build(BuildContext context) {
    final geometry = _StorybookCurlGeometry(
      progress: progress,
      direction: direction,
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
                painter: _StorybookCurlShadowPainter(geometry),
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
    required double perspective,
    required double maxRotation,
    required double flex,
    required double twist,
    required int columns,
    required int rows,
  }) : _geometry = _StorybookCurlGeometry(
         progress: progress,
         direction: direction,
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

    context.canvas
      ..save()
      ..clipRect(offset & size)
      ..drawVertices(mesh.vertices, BlendMode.modulate, paint)
      ..drawPath(
        mesh.freeEdge,
        Paint()
          ..color = const Color(0xFFFFFDF8)
              .withValues(alpha: 0.72 * _geometry.turnEnvelope)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, size.width / 900)
          ..isAntiAlias = true,
      )
      ..restore();

    mesh.vertices.dispose();
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

class _StorybookCurlShadowPainter extends CustomPainter {
  const _StorybookCurlShadowPainter(this.geometry);

  final _StorybookCurlGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = geometry.turnEnvelope;
    if (strength <= 0.001) return;

    final edge = geometry.freeEdgePath(size);
    final width = size.width;
    canvas.drawPath(
      edge,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24 * strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(20, width * 0.105)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(14, width * 0.065),
        )
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      edge,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12 * strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, width / 800)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _StorybookCurlShadowPainter oldDelegate) {
    return geometry != oldDelegate.geometry;
  }
}

@immutable
class _StorybookCurlGeometry {
  const _StorybookCurlGeometry({
    required this.progress,
    required this.direction,
    required this.perspective,
    required this.maxRotation,
    required this.flex,
    required this.twist,
    required this.columns,
    required this.rows,
  });

  final double progress;
  final StorybookPageCurlDirection direction;
  final double perspective;
  final double maxRotation;
  final double flex;
  final double twist;
  final int columns;
  final int rows;

  double get normalizedProgress => progress.clamp(0.0, 1.0);

  double get turnEnvelope => math.sin(normalizedProgress * math.pi).abs();

  _StorybookCurlMesh buildMesh({
    required Offset offset,
    required Size size,
    required Size sourceSize,
  }) {
    final positions = <Offset>[];
    final textureCoordinates = <Offset>[];
    final colors = <Color>[];
    final indices = <int>[];
    final edgePoints = <Offset>[];

    for (var row = 0; row <= rows; row++) {
      final v = row / rows;
      final rowPoints = _projectRow(size, v);
      for (var column = 0; column <= columns; column++) {
        final u = column / columns;
        final point = rowPoints[column] + offset;
        positions.add(point);
        textureCoordinates.add(
          Offset(
            (direction == StorybookPageCurlDirection.forward ? u : 1 - u) *
                sourceSize.width,
            v * sourceSize.height,
          ),
        );
        colors.add(_lightColor(u, v));

        if (column == columns) edgePoints.add(point);
      }
    }

    final rowLength = columns + 1;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final topLeft = row * rowLength + column;
        final topRight = topLeft + 1;
        final bottomLeft = topLeft + rowLength;
        final bottomRight = bottomLeft + 1;
        indices.addAll([
          topLeft,
          bottomLeft,
          topRight,
          topRight,
          bottomLeft,
          bottomRight,
        ]);
      }
    }

    final vertices = ui.Vertices(
      VertexMode.triangles,
      positions,
      textureCoordinates: textureCoordinates,
      colors: colors,
      indices: indices,
    );
    final freeEdge = Path()..moveTo(edgePoints.first.dx, edgePoints.first.dy);
    for (final point in edgePoints.skip(1)) {
      freeEdge.lineTo(point.dx, point.dy);
    }

    return _StorybookCurlMesh(vertices: vertices, freeEdge: freeEdge);
  }

  Path revealPath(Size size) {
    final top = _projectRow(size, 0);
    final bottom = _projectRow(size, 1);
    final edge = _edgePoints(size);
    final sheet = Path()..moveTo(top.first.dx, top.first.dy);
    for (final point in top.skip(1)) {
      sheet.lineTo(point.dx, point.dy);
    }
    for (final point in edge.skip(1)) {
      sheet.lineTo(point.dx, point.dy);
    }
    for (final point in bottom.reversed.skip(1)) {
      sheet.lineTo(point.dx, point.dy);
    }
    sheet.close();

    // The incoming route is painted above the outgoing one by Navigator. Cut
    // the projected sheet silhouette out of the new paper so the curled old
    // sheet remains visible below it. The areas exposed above and below the
    // bowed sheet are part of the new page too; leaving them out caused dark
    // triangular gaps during the first mesh prototype.
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      sheet,
    );
  }

  Path freeEdgePath(Size size) {
    final edge = _edgePoints(size);
    final path = Path()..moveTo(edge.first.dx, edge.first.dy);
    for (final point in edge.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  List<Offset> _edgePoints(Size size) {
    return [
      for (var row = 0; row <= rows; row++) _projectRow(size, row / rows).last,
    ];
  }

  List<Offset> _projectRow(Size size, double v) {
    final result = <Offset>[Offset(_hingeX(size), v * size.height)];
    final segmentWidth = size.width / columns;
    var distanceFromHinge = 0.0;
    var depth = 0.0;

    for (var column = 1; column <= columns; column++) {
      final u = (column - 0.5) / columns;
      final angle = _localAngle(u, v);
      distanceFromHinge += segmentWidth * math.cos(angle);
      depth += segmentWidth * math.sin(angle);

      final perspectiveScale = 1 + perspective * depth;
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
    final baseAngle = maxRotation * p;
    final envelope = turnEnvelope;

    // The first half of the sheet bends a little more than the free edge. It
    // produces the broad, soft C/S-shaped flex visible in the reference rather
    // than rotating the whole page as one rigid rectangle.
    final horizontalFlex =
        flex *
        envelope *
        (0.78 * math.sin(math.pi * u) + 0.22 * math.sin(2 * math.pi * u));

    // The recording shows the bottom edge leading first, followed by the top
    // edge passing it. A phase-changing twist reproduces that hand-turned feel.
    final verticalPosition = (v - 0.5) * 2;
    final twistPhase =
        0.65 * math.sin(2 * math.pi * p) - 0.35 * math.sin(math.pi * p);
    final verticalTwist = twist * verticalPosition * twistPhase;

    return (baseAngle + horizontalFlex + verticalTwist).clamp(0.0, maxRotation);
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
    final brightness = (broadShade - movingShade + rimLight).clamp(0.26, 1.0);
    final channel = (255 * brightness).round();
    return Color.fromARGB(255, channel, channel, channel);
  }

  @override
  bool operator ==(Object other) {
    return other is _StorybookCurlGeometry &&
        progress == other.progress &&
        direction == other.direction &&
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
    perspective,
    maxRotation,
    flex,
    twist,
    columns,
    rows,
  );
}

class _StorybookCurlMesh {
  const _StorybookCurlMesh({required this.vertices, required this.freeEdge});

  final ui.Vertices vertices;
  final Path freeEdge;
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
