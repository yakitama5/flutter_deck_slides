import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/slide_headline.dart';

const _speakerNotes = '''
最後に、今後の展望についてです。
まず、BacklogやSlackのAPIと連携することで、今は一部ローカルバッチが担っている要約・検知の部分も含めて全自動化していきたいと考えています。また、もし社内でNotebookLMのAPI連携が使えるようになれば、Gemini経由の連携もさらに自動化できます。さらに、今はローカルPCで動かしているバッチをGoogle Drive連携を使ってクラウド実行化し、特定のPCに依存しない仕組みにしていきたいです。
そして何より伝えたいのは、この仕組みは特定のプロジェクトだけのものではないということです。会社全体で促進すれば、他のプロジェクトでも同じように全自動化できる仕組みだと考えています。
''';

FlutterDeckSlide buildS11FutureOutlookSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/future-outlook',
      title: '今後の展望',
      steps: 4,
      speakerNotes: _speakerNotes,
    ),
    builder: (context) => const _FutureOutlookContent(),
  );
}

class _Roadmap {
  const _Roadmap({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;
}

const _roadmap = [
  _Roadmap(
    icon: Icons.api,
    title: 'Backlog/Slack API連携',
    detail: '要約・検知も含めて全自動化',
  ),
  _Roadmap(
    icon: Icons.auto_stories,
    title: 'NotebookLM API連携',
    detail: '会社連携が使えれば全自動化',
  ),
  _Roadmap(
    icon: Icons.cloud_sync,
    title: 'Google Drive連携',
    detail: 'クラウド実行化しPC非依存に',
  ),
];

class _FutureOutlookContent extends StatelessWidget {
  const _FutureOutlookContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.geminiEnd.withValues(alpha: 0.06),
                  AppColors.googleBlue.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SlideHeadline(text: '今後の展望'),
            const SizedBox(height: 32),
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < _roadmap.length; i++) ...[
                    if (i > 0) _RoadmapArrow(revealAt: i + 1),
                    Expanded(
                      child: _RoadmapCard(item: _roadmap[i], revealAt: i + 1),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              flex: 2,
              child: FlutterDeckSlideStepsBuilder(
                builder: (context, stepNumber) {
                  if (stepNumber < 4) return const SizedBox.shrink();

                  return Center(
                    child:
                        ContentCard(
                              color: AppColors.notebookLm.withValues(
                                alpha: 0.08,
                              ),
                              borderColor: AppColors.notebookLm,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.notebookLm,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '会社全体で促進すれば、他PJでも全自動化可能な仕組み',
                                    textAlign: TextAlign.center,
                                    style: FlutterDeckTheme.of(context)
                                        .textTheme
                                        .title
                                        .copyWith(
                                          color: AppColors.notebookLm,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                              duration: 500.ms,
                            )
                            .fadeIn(duration: 400.ms)
                            .animate(
                              onPlay: (c) => c.repeat(reverse: true),
                              delay: 500.ms,
                            )
                            .tint(
                              color: AppColors.notebookLm,
                              begin: 0,
                              end: 0.06,
                              duration: 1200.ms,
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoadmapArrow extends StatelessWidget {
  const _RoadmapArrow({required this.revealAt});

  final int revealAt;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        if (stepNumber < revealAt) {
          return const SizedBox(width: 48);
        }

        return SizedBox(
          width: 48,
          child:
              Icon(Icons.arrow_forward, size: 32, color: AppColors.googleBlue)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(
                    begin: 0,
                    end: 6,
                    duration: 700.ms,
                    curve: Curves.easeInOut,
                  ),
        );
      },
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.item, required this.revealAt});

  final _Roadmap item;
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
                    Icon(item.icon, size: 64, color: AppColors.googleBlue)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 20),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 400.ms);
      },
    );
  }
}
