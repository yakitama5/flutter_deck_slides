import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../theme.dart';
import '../widgets/flow_edge_painter.dart';
import '../widgets/service_node.dart';
import '../widgets/slide_headline.dart';

const _speakerNotes = '''
この仕組みを支えるコンポーネント全体図と、それぞれのAIエージェントの役割分担です。ツールは1つではなく、特性に合わせて適材適所で使い分けています。
ローカルバッチは実は3本立てです。①BacklogのQAエクスポートとSlackのやり取りを要約するバッチ、②Dropboxの要件資料を取得して要約するバッチ、そして③Claude Codeの出力をGoogle Driveへ反映するバッチです。
①と②が要約したテキストを「Claude Code」に渡し、一次ソースの差分を読み解きMarkdownへ構造化・編集する『職人』の役割を担わせます。その成果物を③がDriveに同期します。NotebookLMはチームメンバーが自然言語でQ&Aを行うための『SPOC窓口』です。さらに、NotebookLMはAPIを公開していませんが、Geminiの「Notebooks」連携機能を活用することで、Gemini側から複数のNotebookLMの知識を横断して、マクロな設計レビューや実装計画の作成をやらせています。
''';

FlutterDeckSlide buildS05ArchitectureSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/architecture',
      title: '全体像と役割分担',
      steps: 5,
      speakerNotes: _speakerNotes,
    ),
    builder: (context) => const _ArchitectureContent(),
  );
}

const _backlog = Offset(0.07, 0.14);
const _slack = Offset(0.07, 0.36);
const _dropbox = Offset(0.07, 0.68);
const _batch1 = Offset(0.24, 0.22);
const _batch2 = Offset(0.24, 0.68);
const _claude = Offset(0.42, 0.45);
const _batch3 = Offset(0.58, 0.45);
const _drive = Offset(0.74, 0.45);
const _notebookLm = Offset(0.90, 0.45);
const _team = Offset(0.90, 0.16);
const _gemini = Offset(0.90, 0.82);

class _ArchitectureContent extends StatefulWidget {
  const _ArchitectureContent();

  @override
  State<_ArchitectureContent> createState() => _ArchitectureContentState();
}

class _ArchitectureContentState extends State<_ArchitectureContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particles;

  @override
  void initState() {
    super.initState();
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _particles.dispose();
    super.dispose();
  }

  void _onStepChanged(int stepNumber) {
    if (stepNumber >= 5 && !_particles.isAnimating) {
      _particles.repeat();
    } else if (stepNumber < 5 && _particles.isAnimating) {
      _particles.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(text: '全体像とエージェントの役割分担'),
        const SizedBox(height: 12),
        Expanded(
          child: FlutterDeckSlideStepsListener(
            listener: (context, stepNumber) => _onStepChanged(stepNumber),
            child: FlutterDeckSlideStepsBuilder(
              builder: (context, stepNumber) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    Offset abs(Offset f) =>
                        Offset(f.dx * size.width, f.dy * size.height);
                    // ServiceNode はボックス上端から padding(16) + アイコン半径(30) の
                    // 位置にアイコン中心があるため、エッジはその中心座標へ向ける。
                    const iconCenterOffset = Offset(0, -32);
                    Offset node(Offset f) => abs(f) + iconCenterOffset;

                    final edgesStep2 = [
                      FlowEdge(
                        start: node(_backlog),
                        end: node(_batch1),
                        color: AppColors.backlog,
                        curveOffset: -10,
                      ),
                      FlowEdge(
                        start: node(_slack),
                        end: node(_batch1),
                        color: AppColors.slack,
                        curveOffset: 10,
                      ),
                      FlowEdge(
                        start: node(_dropbox),
                        end: node(_batch2),
                        color: AppColors.dropbox,
                      ),
                    ];
                    final edgesStep3 = [
                      FlowEdge(
                        start: node(_batch1),
                        end: node(_claude),
                        color: AppColors.windowsBatch,
                        curveOffset: -10,
                      ),
                      FlowEdge(
                        start: node(_batch2),
                        end: node(_claude),
                        color: AppColors.windowsBatch,
                        curveOffset: 10,
                      ),
                    ];
                    final edgesStep4 = [
                      FlowEdge(
                        start: node(_claude),
                        end: node(_batch3),
                        color: AppColors.claude,
                      ),
                      FlowEdge(
                        start: node(_batch3),
                        end: node(_drive),
                        color: AppColors.windowsBatch,
                      ),
                      FlowEdge(
                        start: node(_drive),
                        end: node(_notebookLm),
                        color: AppColors.drive,
                      ),
                      FlowEdge(
                        start: node(_team),
                        end: node(_notebookLm),
                        color: AppColors.googleBlue,
                        dashed: true,
                      ),
                    ];
                    final edgesStep5 = [
                      FlowEdge(
                        start: node(_gemini),
                        end: node(_notebookLm),
                        color: AppColors.geminiEnd,
                      ),
                    ];

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _AnimatedEdgesLayer(
                          edges: edgesStep2,
                          revealed: stepNumber >= 2,
                        ),
                        _AnimatedEdgesLayer(
                          edges: edgesStep3,
                          revealed: stepNumber >= 3,
                        ),
                        _AnimatedEdgesLayer(
                          edges: edgesStep4,
                          revealed: stepNumber >= 4,
                        ),
                        _AnimatedEdgesLayer(
                          edges: edgesStep5,
                          revealed: stepNumber >= 5,
                        ),
                        if (stepNumber >= 5)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _particles,
                              builder: (context, _) => CustomPaint(
                                painter: FlowEdgePainter(
                                  growth: 1,
                                  particleProgress: _particles.value,
                                  edges: [
                                    ...edgesStep2,
                                    ...edgesStep3,
                                    ...edgesStep4,
                                    ...edgesStep5,
                                  ],
                                ),
                              ),
                            ),
                          ),

                        _node(
                          abs(_backlog),
                          'Backlog\nQAエクスポート',
                          Icons.bug_report,
                          AppColors.backlog,
                          revealAt: 1,
                        ),
                        _node(
                          abs(_slack),
                          'Slack\nQAのやり取り',
                          Icons.tag,
                          AppColors.slack,
                          revealAt: 1,
                        ),
                        _node(
                          abs(_dropbox),
                          'Dropbox\n原本Excel',
                          Icons.cloud,
                          AppColors.dropbox,
                          revealAt: 1,
                        ),
                        _node(
                          abs(_batch1),
                          'バッチ①\nQA要約(差分時)',
                          Icons.schedule,
                          AppColors.windowsBatch,
                          revealAt: 2,
                        ),
                        _node(
                          abs(_batch2),
                          'バッチ②\n要件を要約(差分時)',
                          Icons.schedule,
                          AppColors.windowsBatch,
                          revealAt: 2,
                        ),
                        _node(
                          abs(_claude),
                          'Claude Code\n職人',
                          Icons.smart_toy,
                          AppColors.claude,
                          revealAt: 3,
                        ),
                        _node(
                          abs(_batch3),
                          'バッチ③\nDriveへ反映',
                          Icons.schedule,
                          AppColors.windowsBatch,
                          revealAt: 4,
                          width: 200,
                        ),
                        _node(
                          abs(_drive),
                          'Google Drive\n同期フォルダ',
                          Icons.add_to_drive,
                          AppColors.drive,
                          revealAt: 4,
                        ),
                        _node(
                          abs(_notebookLm),
                          'NotebookLM\nSPOC窓口',
                          Icons.auto_stories,
                          AppColors.notebookLm,
                          revealAt: 4,
                        ),
                        _node(
                          abs(_team),
                          'チーム\n質問',
                          Icons.groups,
                          AppColors.googleBlue,
                          revealAt: 4,
                          width: 160,
                        ),
                        _node(
                          abs(_gemini),
                          'Gemini\n横断レビュー',
                          Icons.auto_awesome,
                          AppColors.geminiEnd,
                          revealAt: 5,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _node(
    Offset center,
    String label,
    IconData icon,
    Color color, {
    required int revealAt,
    double width = 210,
  }) {
    final parts = label.split('\n');

    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - 78,
      child: FlutterDeckSlideStepsBuilder(
        builder: (context, stepNumber) {
          if (stepNumber < revealAt) return const SizedBox.shrink();

          return ServiceNode(
                label: parts.first,
                sublabel: parts.length > 1 ? parts[1] : null,
                icon: icon,
                color: color,
                width: width,
              )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              )
              .fadeIn();
        },
      ),
    );
  }
}

class _AnimatedEdgesLayer extends StatelessWidget {
  const _AnimatedEdgesLayer({required this.edges, required this.revealed});

  final List<FlowEdge> edges;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: revealed ? 1 : 0),
        duration: 700.ms,
        curve: Curves.easeOutCubic,
        builder: (context, growth, _) => CustomPaint(
          painter: FlowEdgePainter(edges: edges, growth: growth),
        ),
      ),
    );
  }
}
