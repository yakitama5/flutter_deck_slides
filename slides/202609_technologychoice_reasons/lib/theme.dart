import 'dart:math' as math;

import 'package:flutter/material.dart';

const paper = Color(0xFFF7F7FC);
const ink = Color(0xFF242D50);
const blue = Color(0xFF4262C5);
const purple = Color(0xFF7962B5);
const muted = Color(0xFF616B87);
const rule = Color(0xFFDCDFF0);
const canvasSize = Size(1920, 1080);

final reasonTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: paper),
  fontFamily: 'Kiwi Maru',
  scaffoldBackgroundColor: paper,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 100,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    displayMedium: TextStyle(
      fontSize: 76,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    displaySmall: TextStyle(
      fontSize: 60,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    headlineMedium: TextStyle(fontSize: 44, height: 1.5),
    titleLarge: TextStyle(fontSize: 36, height: 1.5),
    bodyLarge: TextStyle(fontSize: 36, height: 1.65),
    bodyMedium: TextStyle(fontSize: 30, height: 1.6),
    labelLarge: TextStyle(fontSize: 26, height: 1.4),
  ).apply(bodyColor: ink, displayColor: ink),
);

class ReasonCanvas extends StatelessWidget {
  const ReasonCanvas({required this.child, this.dark = false, super.key});
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Theme(
    data: reasonTheme,
    child: ColoredBox(
      color: dark ? const Color(0xFF252E55) : paper,
      child: Center(
        child: FittedBox(
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Kiwi Maru',
              fontSize: 30,
              color: ink,
            ),
            child: SizedBox.fromSize(size: canvasSize, child: child),
          ),
        ),
      ),
    ),
  );
}

/// Restrained paper and woodland decoration, drawn at presentation resolution.
class PaperBackdrop extends StatelessWidget {
  const PaperBackdrop({required this.child, this.dark = false, super.key});
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(painter: _PaperPainter(dark)),
      child,
    ],
  );
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xFF252E55) : paper,
    );
    final wash = Paint()
      ..color = (dark ? purple : blue).withValues(alpha: dark ? .2 : .045);
    canvas.drawCircle(Offset(size.width * .96, size.height * .07), 410, wash);
    canvas.drawCircle(
      Offset(size.width * .08, size.height * 1.14),
      370,
      Paint()..color = purple.withValues(alpha: dark ? .25 : .065),
    );
    // Quiet printed-paper speckles, deterministic and sparse.
    final random = math.Random(42);
    final dot = Paint()
      ..color = (dark ? Colors.white : ink).withValues(alpha: .035);
    for (var i = 0; i < 1000; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .7,
        dot,
      );
    }
    for (var i = 0; i < 4; i++) {
      final x = size.width - 180 + i * 38;
      final y = size.height - 35 - i * 32;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-.7 + i * .12);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-55, -60, 0, -125)
        ..quadraticBezierTo(55, -60, 0, 0);
      canvas.drawPath(
        leaf,
        Paint()..color = purple.withValues(alpha: dark ? .25 : .09),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PaperPainter oldDelegate) => dark != oldDelegate.dark;
}

/// An open book with blue and violet paper-cut trees, native vector artwork.
class ReasonBookArt extends StatelessWidget {
  const ReasonBookArt({this.chapter = 0, super.key});
  final int chapter;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '青と紫の木々がひらいた本から育つイラスト',
    image: true,
    child: CustomPaint(
      painter: _BookPainter(chapter),
      size: const Size(720, 680),
    ),
  );
}

class _BookPainter extends CustomPainter {
  const _BookPainter(this.chapter);
  final int chapter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 720, size.height / 680);
    canvas.drawOval(
      const Rect.fromLTWH(38, 550, 645, 74),
      Paint()..color = ink.withValues(alpha: .1),
    );
    final left = Path()
      ..moveTo(355, 564)
      ..quadraticBezierTo(210, 482, 48, 535)
      ..lineTo(63, 311)
      ..quadraticBezierTo(209, 260, 355, 334)
      ..close();
    final right = Path()
      ..moveTo(360, 564)
      ..quadraticBezierTo(495, 478, 665, 530)
      ..lineTo(651, 307)
      ..quadraticBezierTo(500, 260, 360, 334)
      ..close();
    canvas.drawPath(left.shift(const Offset(0, 15)), Paint()..color = blue);
    canvas.drawPath(right.shift(const Offset(0, 15)), Paint()..color = purple);
    canvas.drawPath(left, Paint()..color = const Color(0xFFE8EDFC));
    canvas.drawPath(right, Paint()..color = const Color(0xFFF2ECFC));
    canvas.drawLine(
      const Offset(358, 340),
      const Offset(358, 557),
      Paint()
        ..color = const Color(0xFFC0C7E4)
        ..strokeWidth = 3,
    );
    for (var i = 0; i < 4; i++) {
      final y = 440.0 + 22 * i;
      canvas.drawLine(
        Offset(98, y),
        Offset(281, y - 4),
        Paint()
          ..color = blue.withValues(alpha: .17)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(424, y - 4),
        Offset(597, y),
        Paint()
          ..color = purple.withValues(alpha: .17)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    _tree(canvas, 160, 405, 232, blue, round: true);
    _tree(canvas, 505, 398, 296, purple, round: true);
    _tree(canvas, 318, 425, 336, const Color(0xFF667ECE));
    _tree(canvas, 607, 420, 170, const Color(0xFFA59BD3));
    final star = Paint()..color = const Color(0xFFBFC7F0);
    for (final p in [
      const Offset(104, 118),
      const Offset(425, 66),
      const Offset(622, 198),
    ]) {
      canvas.drawLine(
        p - const Offset(0, 10),
        p + const Offset(0, 10),
        star..strokeWidth = 3,
      );
      canvas.drawLine(p - const Offset(10, 0), p + const Offset(10, 0), star);
    }
    canvas.restore();
  }

  void _tree(
    Canvas canvas,
    double x,
    double base,
    double height,
    Color color, {
    bool round = false,
  }) {
    final top = base - height;
    final leaf = Paint()..color = color;
    if (round) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, top + height * .36),
          width: height * .52,
          height: height * .73,
        ),
        leaf,
      );
    } else {
      final path = Path()
        ..moveTo(x, top)
        ..quadraticBezierTo(
          x - height * .5,
          base - height * .22,
          x,
          base - height * .18,
        )
        ..quadraticBezierTo(x + height * .5, base - height * .22, x, top);
      canvas.drawPath(path, leaf);
    }
    canvas.drawLine(
      Offset(x, base),
      Offset(x, top + height * .32),
      Paint()
        ..color = const Color(0xFFE0E5FA)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x, base - height * .34),
      Offset(x - height * .13, base - height * .51),
      Paint()
        ..color = const Color(0xFFE0E5FA)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_BookPainter oldDelegate) =>
      chapter != oldDelegate.chapter;
}
