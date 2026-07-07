import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../theme.dart';

const _speakerNotes = '''
まとめです。私たちが今回の取り組みで得た最大の教訓は、「情報を綺麗に1箇所にまとめ直す必要はない」ということです。情報はExcelやGitHubなど、それぞれの最適な場所に散らばったままで構いません。大切なのは、人間がアクセスする窓口をAIによって一本化（SPOC化）し、全工程の文脈を記憶したAI窓口を育てることです。
そしてそれを実現するために、重厚なAPI連携を作り込むのではなく、既存のGoogle Drive同期などの仕組みに上手く"相乗り"する。このアプローチをとることで、開発コストを最小限に抑えつつ、現場の課題をエレガントに解決することができました。
皆さんのプロジェクトでも、散在するドキュメントに悩まされている方がいれば、ぜひこの「SPOC窓口を自動で育てる型」を試してみてください。ご清聴ありがとうございました。質疑応答に移ります。
''';

FlutterDeckSlide buildS12SummarySlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/summary',
      title: 'まとめ',
      steps: 4,
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      speakerNotes: _speakerNotes,
    ),
    builder: (context) => const _SummaryContent(),
  );
}

const _messages = [
  ('SPOC', '情報は散らばっていていい。人間が「聞く窓口」はNotebookLMに一本化する', AppColors.notebookLm),
  ('AI窓口', '人手ゼロで自動最新化される、全工程を網羅した「絶対に退職しないAI窓口」', AppColors.claude),
  ('相乗り', 'API連携を作らない"相乗り"精神で、開発・保守コストを最小限に', AppColors.googleGreen),
];

class _SummaryContent extends StatefulWidget {
  const _SummaryContent();

  @override
  State<_SummaryContent> createState() => _SummaryContentState();
}

class _SummaryContentState extends State<_SummaryContent> {
  late final ConfettiController _left;
  late final ConfettiController _right;

  @override
  void initState() {
    super.initState();
    _left = ConfettiController(duration: const Duration(seconds: 3));
    _right = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  void _onStepChanged(int stepNumber) {
    if (stepNumber >= 4) {
      _left.play();
      _right.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsListener(
      listener: (context, stepNumber) => _onStepChanged(stepNumber),
      child: FlutterDeckSlideStepsBuilder(
        builder: (context, stepNumber) {
          return Stack(
            alignment: Alignment.topLeft,
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _messages.length; i++) ...[
                      if (i > 0) const SizedBox(height: 24),
                      if (stepNumber >= i + 1)
                        _MessageRow(index: i, data: _messages[i]),
                    ],
                    if (stepNumber >= 4) ...[
                      const SizedBox(height: 48),
                      Text(
                            'ご清聴ありがとうございました',
                            style: FlutterDeckTheme.of(
                              context,
                            ).textTheme.display,
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(),
                    ],
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: _left,
                  blastDirection: -math.pi / 4,
                  numberOfParticles: 24,
                  shouldLoop: true,
                  colors: const [
                    AppColors.googleBlue,
                    AppColors.googleRed,
                    AppColors.googleYellow,
                    AppColors.googleGreen,
                    AppColors.claude,
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: _right,
                  blastDirection: -math.pi + math.pi / 4,
                  numberOfParticles: 24,
                  shouldLoop: true,
                  colors: const [
                    AppColors.googleBlue,
                    AppColors.googleRed,
                    AppColors.googleYellow,
                    AppColors.googleGreen,
                    AppColors.claude,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.index, required this.data});

  final int index;
  final (String, String, Color) data;

  @override
  Widget build(BuildContext context) {
    final (label, message, color) = data;

    return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: FlutterDeckTheme.of(context).textTheme.title,
                  children: [
                    TextSpan(
                      text: '$label — ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: message),
                  ],
                ),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
