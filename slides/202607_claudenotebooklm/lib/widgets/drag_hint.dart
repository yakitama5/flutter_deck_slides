import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ドラッグ可能な要素に付与する「点滅する手のひらアイコン + 破線ボーダー」のヒント表示。
///
/// [visible] が false になったら（一度ドラッグしたら）非表示にする。
class DragHint extends StatelessWidget {
  const DragHint({required this.child, required this.visible, super.key});

  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          foregroundPainter: visible
              ? _DashedBorderPainter(color: color)
              : null,
          child: child,
        ),
        if (visible)
          Positioned(
            top: -14,
            right: -14,
            child:
                Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.back_hand,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.1, 1.1),
                      duration: 600.ms,
                    ),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 8.0;
    const dashSpace = 5.0;

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
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
