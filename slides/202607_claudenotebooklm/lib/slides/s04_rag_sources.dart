import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../speaker_notes.dart';
import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/doc_chip.dart';
import '../widgets/service_node.dart';
import '../widgets/slide_headline.dart';

FlutterDeckSlide buildS04RagSourcesSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/rag-sources',
      title: 'RAG化の対象ソース',
      steps: 5,
      speakerNotes: SpeakerNotes.ragSources,
    ),
    builder: (context) => const _RagSourcesContent(),
  );
}

class _Phase {
  const _Phase({required this.title, required this.docs});

  final String title;
  final List<DocChip> docs;
}

final _phases = [
  _Phase(
    title: '要件定義',
    docs: const [
      DocChip(
        label: '要件資料(Excel)',
        icon: Icons.table_chart,
        color: AppColors.excel,
      ),
      DocChip(label: 'パワポ', icon: Icons.slideshow, color: AppColors.googleRed),
      DocChip(
        label: 'Markdown',
        icon: Icons.description,
        color: AppColors.claude,
      ),
      DocChip(
        label: 'Word/doc',
        icon: Icons.article,
        color: AppColors.googleBlue,
      ),
    ],
  ),
  _Phase(
    title: '基本設計',
    docs: const [
      DocChip(
        label: 'DB定義(Excel)',
        icon: Icons.table_chart,
        color: AppColors.excel,
      ),
      DocChip(
        label: 'Figma',
        icon: Icons.design_services,
        color: AppColors.geminiEnd,
      ),
      DocChip(
        label: 'BacklogのQA',
        icon: Icons.bug_report,
        color: AppColors.backlog,
      ),
    ],
  ),
  _Phase(
    title: '詳細設計',
    docs: const [
      DocChip(
        label: '処理仕様書(Markdown)',
        icon: Icons.description,
        color: AppColors.claude,
      ),
      DocChip(
        label: 'BacklogのQA',
        icon: Icons.bug_report,
        color: AppColors.backlog,
      ),
      DocChip(
        label: 'PR指摘内容',
        icon: Icons.code,
        color: AppColors.github,
        sublabel: 'Claudeサマリ',
      ),
    ],
  ),
  _Phase(
    title: '製造',
    docs: const [
      DocChip(
        label: 'PR指摘内容',
        icon: Icons.code,
        color: AppColors.github,
        sublabel: 'Claudeサマリ',
      ),
    ],
  ),
];

class _RagSourcesContent extends StatelessWidget {
  const _RagSourcesContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(text: '一気通貫したRAG化の対象ソース'),
        const SizedBox(height: 24),
        Expanded(
          flex: 7,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _phases.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: _PhaseColumn(phase: _phases[i], stepIndex: i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          flex: 4,
          child: Center(
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, stepNumber) {
                // ステップを踏むごとに知見が溜まっていくイメージで、
                // NotebookLM ノードがバウンドしながら大きくなっていく。
                final step = stepNumber.clamp(1, 5);
                final scale = 1.0 + (step - 1) * 0.16;

                final node = ServiceNode(
                  label: 'NotebookLM',
                  sublabel: stepNumber >= 5 ? '全工程の経緯を記憶した窓口' : null,
                  icon: Icons.auto_stories,
                  color: AppColors.notebookLm,
                  width: 400,
                );

                final scaled = AnimatedScale(
                  scale: scale,
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                  child: node,
                );

                return stepNumber >= 5
                    ? scaled
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.04, 1.04),
                            duration: 900.ms,
                            curve: Curves.easeInOut,
                          )
                    : scaled;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PhaseColumn extends StatelessWidget {
  const _PhaseColumn({required this.phase, required this.stepIndex});

  final _Phase phase;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsBuilder(
      builder: (context, stepNumber) {
        final revealAt = stepIndex + 1;
        if (stepNumber < revealAt) return const SizedBox.shrink();

        return ContentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phase.title,
                    style: FlutterDeckTheme.of(context).textTheme.title,
                  ),
                  const SizedBox(height: 12),
                  for (final doc in phase.docs) ...[
                    doc,
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            )
            .animate(delay: (stepIndex * 100).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}
