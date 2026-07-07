import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../speaker_notes.dart';
import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/slide_headline.dart';

FlutterDeckSlide buildS06DataFlowSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/data-flow',
      title: '5ステップのデータフロー',
      steps: 5,
      speakerNotes: SpeakerNotes.dataFlow,
    ),
    builder: (context) => const _DataFlowContent(),
  );
}

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _steps = [
  _Step(icon: Icons.radar, title: '①変更検知', description: 'state.jsonと比較'),
  _Step(icon: Icons.file_copy, title: '②原本コピー', description: 'リファレンス残す'),
  _Step(icon: Icons.data_object, title: '③テキスト化', description: 'Pythonダンプ'),
  _Step(icon: Icons.smart_toy, title: '④Claude反映', description: '差分のみピンポイント編集'),
  _Step(
    icon: Icons.add_to_drive,
    title: '⑤Driveコピー',
    description: 'robocopyで同期・自動取込',
  ),
];

class _DataFlowContent extends StatelessWidget {
  const _DataFlowContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(text: '仕組み — 5ステップのデータフロー'),
        const SizedBox(height: 40),
        Expanded(
          child: FlutterDeckSlideStepsBuilder(
            builder: (context, stepNumber) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: stepNumber / _steps.length),
                      duration: 500.ms,
                      builder: (context, value, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(color: Colors.grey.shade300),
                                Container(
                                  width:
                                      constraints.maxWidth * value.clamp(0, 1),
                                  color: AppColors.notebookLm,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _steps.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _StepCard(
                            step: _steps[i],
                            index: i,
                            active: stepNumber >= i + 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (stepNumber == 1)
                    Column(
                      children: [
                        const ContentCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            '⏰ 12:00 自動起動',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 8),
                        Text(
                          '変更なし → 即終了（APIコスト ¥0）',
                          style: FlutterDeckTheme.of(
                            context,
                          ).textTheme.bodyMedium,
                        ).animate(delay: 200.ms).fadeIn(),
                      ],
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.index,
    required this.active,
  });

  final _Step step;
  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final card = ContentCard(
      color: active ? AppColors.notebookLm.withValues(alpha: 0.08) : null,
      borderColor: active ? AppColors.notebookLm : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            step.icon,
            size: 32,
            color: active ? AppColors.notebookLm : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: active ? AppColors.notebookLm : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: active ? null : Colors.grey),
          ),
        ],
      ),
    );

    return AnimatedScale(
      scale: active ? 1.05 : 1.0,
      duration: 300.ms,
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.5,
        duration: 300.ms,
        child: card,
      ),
    );
  }
}
