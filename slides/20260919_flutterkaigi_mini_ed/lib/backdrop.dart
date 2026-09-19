import 'package:flutter/material.dart';

/// Quiet event artwork, kept at the edges of the presentation canvas.
class EventBackdrop extends StatelessWidget {
  const EventBackdrop({required this.emphasized, super.key});

  final bool emphasized;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EventBackdropPainter(
            Theme.of(context).colorScheme,
            emphasized,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _EventBackdropPainter extends CustomPainter {
  const _EventBackdropPainter(this.colors, this.emphasized);

  final ColorScheme colors;
  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1920, size.height / 1080);
    const bounds = Rect.fromLTWH(0, 0, 1920, 1080);
    canvas.clipRect(bounds);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            emphasized ? colors.surfaceContainer : colors.surfaceContainerLow,
          ],
        ).createShader(bounds),
    );

    // Offset 45-degree ribbons echo the geometry of the event artwork.
    for (final (start, width, opacity) in [
      (1670.0, 170.0, .075),
      (1930.0, 55.0, .11),
    ]) {
      // A long diagonal through the upper-right corner, outside the copy.
      final diagonal = Path()
        ..moveTo(start, -100)
        ..lineTo(start + width, -100)
        ..lineTo(start - 530 + width, 430)
        ..lineTo(start - 530, 430)
        ..close();
      canvas.drawPath(
        diagonal,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              colors.secondary.withValues(alpha: opacity),
              colors.secondary.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(1100, 0, 820, 530)),
      );
    }

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = colors.secondary.withValues(alpha: emphasized ? .12 : .075);
    for (var offset = 0; offset < 4; offset++) {
      final inset = offset * 48.0;
      canvas.drawPath(
        Path()
          ..moveTo(1600 + inset, -40)
          ..lineTo(1825 + inset, 185)
          ..lineTo(1600 + inset, 410),
        outline,
      );
    }

    // One large, cropped orbit sits behind the mascot, not behind the text.
    canvas.drawCircle(
      const Offset(1905, 1085),
      360,
      Paint()..color = colors.secondary.withValues(alpha: .025),
    );
    for (final radius in [360.0, 405.0, 450.0]) {
      canvas.drawCircle(
        const Offset(1905, 1085),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = colors.secondary.withValues(alpha: .10),
      );
    }
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawCircle(
          Offset(26 + column * 22.0, 838 + row * 22.0),
          2,
          Paint()..color = colors.onSurface.withValues(alpha: .12),
        );
      }
    }

    // A narrow accent line adds the warm/cool colors without tinting the copy.
    const accent = Rect.fromLTWH(0, 0, 1920, 5);
    canvas.drawRect(
      accent,
      Paint()
        ..shader = LinearGradient(
          colors: [colors.secondary, colors.primary, colors.tertiary],
          stops: const [0, .65, 1],
        ).createShader(accent),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EventBackdropPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.emphasized != emphasized;
}
