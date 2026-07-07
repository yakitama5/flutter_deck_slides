import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/slide_headline.dart';

const _speakerNotes = '''
この仕組みを導入した狙い、そして実際に得られた価値についてまとめます。
最大の効果は、ナレッジの最新性が「機械的に保証されるようになった」ことです。原本が変わればAIの記憶も自動追従するため、資料のメンテナンス漏れが構造的に起きなくなりました。また、開発時の細かい仕様確認が「有識者へのチャット」から「NotebookLMへの質問」にシフトしたことで、質問された側の有識者が集中を切らされることなく、自身の開発に専念できるようになりました。さらに、すべてをAPIコストの高いClaudeに頼るのではなく、複数工程を横断したマクロなレビューや実装計画の一次出力はGeminiのNotebooks連携に任せることで、トークンコストを大幅に抑えつつ、多角的な品質向上を実現しています。
''';

FlutterDeckSlide buildS09ValueSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/value',
      title: '得られた価値',
      steps: 4,
      speakerNotes: _speakerNotes,
    ),
    builder: (context) => const _ValueContent(),
  );
}

class _Value {
  const _Value({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;
}

const _values = [
  _Value(icon: Icons.autorenew, title: '最新性の自動担保', detail: '反映漏れ・陳腐化の構造的防止'),
  _Value(icon: Icons.savings, title: 'トークン節約と品質向上', detail: 'マクロレビューはGeminiに'),
  _Value(
    icon: Icons.rocket_launch,
    title: '問い合わせ高速化',
    detail: '有識者ボトルネック解消・新規参画者が自走',
  ),
];

class _ValueContent extends StatelessWidget {
  const _ValueContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(text: '狙い（得られた価値）'),
        const SizedBox(height: 24),
        Expanded(
          child: FlutterDeckSlideStepsBuilder(
            builder: (context, stepNumber) {
              final compact = stepNumber >= 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: compact ? 3 : 5,
                    child: Center(
                      child: AnimatedScale(
                        scale: compact ? 0.55 : 1.0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¥0',
                              style: FlutterDeckTheme.of(context)
                                  .textTheme
                                  .display
                                  .copyWith(
                                    color: AppColors.googleGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ).animate().scale(
                              begin: const Offset(0.3, 0.3),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '無変更日の API コスト',
                              style: FlutterDeckTheme.of(
                                context,
                              ).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (compact)
                    Expanded(
                      flex: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _values.length; i++) ...[
                            if (i > 0) const SizedBox(width: 24),
                            Expanded(
                              child: _ValueCard(
                                value: _values[i],
                                revealAt: i + 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.value, required this.revealAt});

  final _Value value;
  final int revealAt;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        if (stepNumber < revealAt) return const SizedBox.shrink();

        return ContentCard(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(value.icon, size: 64, color: AppColors.notebookLm),
                    const SizedBox(height: 20),
                    Text(
                      value.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value.detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}
