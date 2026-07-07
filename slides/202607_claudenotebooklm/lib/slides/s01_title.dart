import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../theme.dart';

const _speakerNotes = '''
皆さんお疲れ様です。本日は「要件・ソースを"生きたナレッジ"に」と題しまして、Claude CodeとNotebookLM、そしてGeminiを組み合わせた、自動RAG化ナレッジパイプラインの構築と、それを1ヶ月運用して得られた知見について共有します。
本日の発表のゴールは、散らばった社内資産をどうやってAIが扱える形に集約し、開発チームの強力な窓口として育成するか、その具体的な方法を持ち帰っていただくことです。よろしくお願いいたします。
''';

FlutterDeckSlide buildS01TitleSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/intro',
      title: 'タイトル',
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      speakerNotes: _speakerNotes,
    ),
    builder: (context) => const _TitleSlideContent(),
  );
}

class _TitleSlideContent extends StatefulWidget {
  const _TitleSlideContent();

  @override
  State<_TitleSlideContent> createState() => _TitleSlideContentState();
}

class _TitleSlideContentState extends State<_TitleSlideContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) =>
              CustomPaint(painter: _DriftingBlobsPainter(t: _controller.value)),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                      '要件・ソースを"生きたナレッジ"に',
                      textAlign: TextAlign.center,
                      style: FlutterDeckTheme.of(context).textTheme.display,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                Text(
                      '— Claude × NotebookLM 自動連携パイプライン',
                      textAlign: TextAlign.center,
                      style: FlutterDeckTheme.of(context).textTheme.title
                          .copyWith(
                            color: AppColors.notebookLm,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 32),
                Text(
                      '散在するExcel/ソースを、人手ゼロで最新ナレッジ化しAIで引ける状態に',
                      textAlign: TextAlign.center,
                      style: FlutterDeckTheme.of(context).textTheme.bodyLarge,
                    )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DriftingBlobsPainter extends CustomPainter {
  const _DriftingBlobsPainter({required this.t});

  final double t;

  static const _colors = [
    AppColors.googleBlue,
    AppColors.googleRed,
    AppColors.googleYellow,
    AppColors.googleGreen,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final corners = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.9, size.height * 0.2),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.88, size.height * 0.82),
    ];

    for (var i = 0; i < corners.length; i++) {
      final phase = t * 2 * math.pi + i * (math.pi / 2);
      final offset =
          corners[i] + Offset(math.cos(phase) * 40, math.sin(phase) * 40);
      final paint = Paint()
        ..color = _colors[i].withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

      canvas.drawCircle(offset, 220, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DriftingBlobsPainter oldDelegate) =>
      oldDelegate.t != t;
}
