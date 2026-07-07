import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../speaker_notes.dart';
import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/drag_hint.dart';
import '../widgets/flow_edge_painter.dart';
import '../widgets/service_node.dart';

FlutterDeckSlide buildS03ConceptSpocSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/concept-spoc',
      title: 'コンセプト：SPOC',
      steps: 4,
      speakerNotes: SpeakerNotes.conceptSpoc,
    ),
    builder: (context) => const _ConceptSpocContent(),
  );
}

class _Island {
  const _Island({
    required this.label,
    required this.icon,
    required this.color,
    required this.center,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Offset center; // fractional
}

const _islands = [
  _Island(
    label: 'Excel島',
    icon: Icons.table_chart,
    color: AppColors.excel,
    center: Offset(0.11, 0.16),
  ),
  _Island(
    label: 'Word島',
    icon: Icons.article,
    color: AppColors.googleBlue,
    center: Offset(0.5, 0.16),
  ),
  _Island(
    label: 'Slack島',
    icon: Icons.tag,
    color: AppColors.slack,
    center: Offset(0.89, 0.16),
  ),
  _Island(
    label: 'Backlog島',
    icon: Icons.bug_report,
    color: AppColors.backlog,
    center: Offset(0.11, 0.68),
  ),
  _Island(
    label: 'パワポ島',
    icon: Icons.slideshow,
    color: AppColors.googleRed,
    center: Offset(0.5, 0.68),
  ),
  _Island(
    label: 'GitHub島',
    icon: Icons.code,
    color: AppColors.github,
    center: Offset(0.89, 0.68),
  ),
];

const _conciergeCenter = Offset(0.5, 0.5);

class _ConceptSpocContent extends StatefulWidget {
  const _ConceptSpocContent();

  @override
  State<_ConceptSpocContent> createState() => _ConceptSpocContentState();
}

class _ConceptSpocContentState extends State<_ConceptSpocContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple;
  bool _answered = false;
  Timer? _autoFireTimer;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ripple.dispose();
    _autoFireTimer?.cancel();
    super.dispose();
  }

  void _fireAnswer() {
    if (_answered) return;
    setState(() => _answered = true);
  }

  void _onStepChanged(int stepNumber) {
    if (stepNumber >= 4 && !_answered) {
      _autoFireTimer?.cancel();
      _autoFireTimer = Timer(600.ms, _fireAnswer);
    } else if (stepNumber < 4) {
      _autoFireTimer?.cancel();
      if (_answered) setState(() => _answered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterDeckSlideStepsListener(
      listener: (context, stepNumber) => _onStepChanged(stepNumber),
      child: FlutterDeckSlideStepsBuilder(
        builder: (context, stepNumber) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              Offset abs(Offset f) =>
                  Offset(f.dx * size.width, f.dy * size.height);
              // _IslandWidget は ServiceNode をボックス上端(center.dy-65)に置いており、
              // アイコン中心はそこから padding(16)+半径(30) 下にあるため補正する。
              Offset islandIconCenter(Offset f) => abs(f) - const Offset(0, 19);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.shade50,
                            Colors.lightBlue.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),

                  // 破線パス（島 → コンシェルジュ）
                  if (stepNumber >= 3)
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                        builder: (context, growth, _) {
                          return CustomPaint(
                            painter: FlowEdgePainter(
                              growth: growth,
                              edges: [
                                for (final island in _islands)
                                  FlowEdge(
                                    start: islandIconCenter(island.center),
                                    end: abs(_conciergeCenter),
                                    color: island.color.withValues(alpha: 0.6),
                                    dashed: true,
                                    curveOffset: 30,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // 島
                  for (var i = 0; i < _islands.length; i++)
                    Positioned(
                      left: abs(_islands[i].center).dx - 100,
                      top: abs(_islands[i].center).dy - 65,
                      child: _IslandWidget(island: _islands[i])
                          .animate(delay: (i * 150).ms)
                          .scale(
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(),
                    ),

                  // コンシェルジュ + 波紋
                  if (stepNumber >= 2)
                    Positioned(
                      left: abs(_conciergeCenter).dx - 70,
                      top: abs(_conciergeCenter).dy - 70,
                      child:
                          DragTarget<String>(
                            onAcceptWithDetails: (_) => _fireAnswer(),
                            builder: (context, candidateData, rejectedData) {
                              return SizedBox(
                                width: 140,
                                height: 140,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _ripple,
                                      builder: (context, _) {
                                        final t = _ripple.value;
                                        return Container(
                                          width: 90 + t * 60,
                                          height: 90 + t * 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.notebookLm
                                                  .withValues(
                                                    alpha: (1 - t) * 0.6,
                                                  ),
                                              width: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.notebookLm,
                                            boxShadow: candidateData.isNotEmpty
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .notebookLm
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      blurRadius: 24,
                                                      spreadRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: const Icon(
                                            Icons.support_agent,
                                            color: Colors.white,
                                            size: 44,
                                          ),
                                        )
                                        .animate(target: _answered ? 1 : 0)
                                        .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.15, 1.15),
                                          curve: Curves.easeOut,
                                          duration: 250.ms,
                                        ),
                                    if (_answered)
                                      Positioned(
                                        top: -76,
                                        child:
                                            ContentCard(
                                                  color: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 14,
                                                      ),
                                                  child: const Text(
                                                    '○○でチェックしています',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 24,
                                                    ),
                                                  ),
                                                )
                                                .animate()
                                                .scale(
                                                  begin: const Offset(0.5, 0.5),
                                                  end: const Offset(1, 1),
                                                  curve: Curves.easeOutBack,
                                                )
                                                .fadeIn(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ).animate().scale(
                            begin: const Offset(0.3, 0.3),
                            end: const Offset(1, 1),
                            curve: Curves.elasticOut,
                            duration: 700.ms,
                          ),
                    ),

                  // SPOC ラベル
                  if (stepNumber >= 3)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Center(
                        child:
                            ContentCard(
                                  color: Colors.white,
                                  child: Text(
                                    'SPOC = Single Point of Contact（単一の連絡窓口）',
                                    style: FlutterDeckTheme.of(
                                      context,
                                    ).textTheme.title,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0),
                      ),
                    ),

                  // 質問チップ（ドラッグ or 自動発火。回答後も表示し続ける）
                  if (stepNumber >= 4)
                    Positioned(
                      right: 24,
                      top: 24,
                      child: DragHint(
                        visible: !_answered,
                        child: Draggable<String>(
                          data: 'question',
                          feedback: const Material(
                            color: Colors.transparent,
                            child: _QuestionChip(),
                          ),
                          childWhenDragging: const Opacity(
                            opacity: 0.3,
                            child: _QuestionChip(),
                          ),
                          child: const _QuestionChip(),
                        ),
                      ).animate().fadeIn().slideX(begin: 0.3, end: 0),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip();

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      color: Colors.white,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, color: AppColors.googleBlue, size: 28),
          SizedBox(width: 10),
          Text(
            '○○画面の□□項目のバリデーション仕様を教えて',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _IslandWidget extends StatelessWidget {
  const _IslandWidget({required this.island});

  final _Island island;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 200,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFE8D9A0),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: AppColors.googleGreen.withValues(alpha: 0.4),
                width: 4,
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: ServiceNode(
              label: island.label,
              icon: island.icon,
              color: island.color,
              width: 160,
            ),
          ),
        ],
      ),
    );
  }
}
