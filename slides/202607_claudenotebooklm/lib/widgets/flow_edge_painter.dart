import 'package:flutter/material.dart';

/// 構成図のノード間を結ぶ1本のエッジ定義。
class FlowEdge {
  const FlowEdge({
    required this.start,
    required this.end,
    this.color = Colors.grey,
    this.dashed = false,
    this.curveOffset = 0,
    this.width = 3,
  });

  final Offset start;
  final Offset end;
  final Color color;

  /// true の場合は破線で描画する（S3 の点線パス用）。
  final bool dashed;

  /// 0 なら直線。0 以外なら中点から垂直方向にこの距離だけ膨らんだ二次ベジェ曲線。
  final double curveOffset;
  final double width;

  Path toPath() {
    if (curveOffset == 0) {
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
    }

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final dir = end - start;
    final normal = dir.distance == 0
        ? Offset.zero
        : Offset(-dir.dy, dir.dx) / dir.distance;
    final control = mid + normal * curveOffset;

    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }
}

/// エッジの「線が伸びる」入場アニメーションと、エッジ上を流れる粒子ループを描画する。
///
/// - [growth]: 0..1。エッジの描画割合（線が伸びる演出）。
/// - [particleProgress]: null なら粒子なし。0..1 でループする値を渡すと、
///   エッジごとに [particlePhaseStep] だけ位相をずらして粒子を描画する。
class FlowEdgePainter extends CustomPainter {
  const FlowEdgePainter({
    required this.edges,
    this.growth = 1.0,
    this.particleProgress,
    this.particlePhaseStep = 0.18,
    this.particleRadius = 5,
  });

  final List<FlowEdge> edges;
  final double growth;
  final double? particleProgress;
  final double particlePhaseStep;
  final double particleRadius;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final metrics = edge.toPath().computeMetrics().toList();
      if (metrics.isEmpty) continue;

      final metric = metrics.first;
      final drawLength = metric.length * growth.clamp(0, 1);
      final visiblePath = metric.extractPath(0, drawLength);

      final paint = Paint()
        ..color = edge.color
        ..strokeWidth = edge.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (edge.dashed) {
        _drawDashed(canvas, visiblePath, paint);
      } else {
        canvas.drawPath(visiblePath, paint);
      }

      final progress = particleProgress;
      if (progress != null && drawLength >= metric.length) {
        final t = (progress + i * particlePhaseStep) % 1.0;
        final tangent = metric.getTangentForOffset(metric.length * t);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            particleRadius,
            Paint()..color = edge.color,
          );
        }
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant FlowEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.growth != growth ||
        oldDelegate.particleProgress != particleProgress;
  }
}
