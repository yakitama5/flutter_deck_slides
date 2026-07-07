import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_deck/flutter_deck.dart';

import '../theme.dart';
import '../widgets/content_card.dart';
import '../widgets/slide_headline.dart';

const _speakerNotes = '''
まず、皆さんのプロジェクトで、画面にあるようなこんな光景を見たことはありませんか？
例えば、「あの仕様どうなったっけ？」と聞いて、「あ、それBacklogのQAで解決したんで、あのチケット見てください！」と言われる。つまり、QAの内容が元の設計資料に全く反映されておらず、資料が陳腐化している状態ですね。
さらに、新規参画者が入ってきた時に「とりあえずここにある資料全部読んどいて！」と共有フォルダを渡すものの、資料が膨大すぎて到底読む気にならず、どこから手をつければいいか分からない。結果として、「結局どれが最新で正しい仕様なんですか？」と、すべてを知っている有識者に毎回聞きに行く羽目になる。探す・聞く・直すという無駄なコストが日々発生しています。
''';

FlutterDeckSlide buildS02ProblemChaosSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/problem-chaos',
      title: '課題：現場のカオス',
      steps: 4,
      speakerNotes: _speakerNotes,
    ),
    builder: (context) => const _ProblemChaosContent(),
  );
}

class _ProblemChaosContent extends StatelessWidget {
  const _ProblemChaosContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SlideHeadline(
          text: '課題：現場のカオス',
          accentColor: AppColors.googleRed,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 11, child: _ChaosCanvas()),
              const SizedBox(width: 32),
              Expanded(flex: 9, child: _ProblemList()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProblemList extends StatelessWidget {
  const _ProblemList();

  static const _items = [
    'QAの内容が元の資料に反映されない\n（Slack/Backlogで解決して放置）',
    '資料が多すぎて新人が絶望する\n（どこから読めばいいかわからない）',
    '結果：「結局どれが最新で正なの？」と\n有識者に質問が集中する',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          FlutterDeckSlideStepsBuilder(
            builder: (context, stepNumber) {
              final revealAt = i + 2;
              if (stepNumber < revealAt) return const SizedBox.shrink();

              final isLast = i == _items.length - 1;
              final card = ContentCard(
                color: isLast
                    ? AppColors.googleRed.withValues(alpha: 0.1)
                    : null,
                borderColor: isLast ? AppColors.googleRed : null,
                child: Text(
                  _items[i],
                  style: FlutterDeckTheme.of(context).textTheme.bodyLarge
                      .copyWith(
                        fontWeight: isLast
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isLast ? AppColors.googleRed : null,
                      ),
                ),
              );

              final animated = card
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  );

              return isLast
                  ? animated.shake(hz: 4, delay: 400.ms, duration: 400.ms)
                  : animated;
            },
          ),
        ],
      ],
    );
  }
}

class _ChaosDoc {
  const _ChaosDoc({
    required this.icon,
    required this.color,
    required this.label,
    required this.base,
    this.size = 92,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Offset base;
  final double size;
}

const _docs = [
  _ChaosDoc(
    icon: Icons.table_chart,
    color: AppColors.excel,
    label: 'Excel',
    base: Offset(0.08, 0.10),
  ),
  _ChaosDoc(
    icon: Icons.table_chart,
    color: AppColors.excel,
    label: 'Excel',
    base: Offset(0.55, 0.06),
    size: 78,
  ),
  _ChaosDoc(
    icon: Icons.table_chart,
    color: AppColors.excel,
    label: 'Excel',
    base: Offset(0.30, 0.38),
  ),
  _ChaosDoc(
    icon: Icons.table_chart,
    color: AppColors.excel,
    label: 'Excel',
    base: Offset(0.78, 0.44),
    size: 84,
  ),
  _ChaosDoc(
    icon: Icons.tag,
    color: AppColors.slack,
    label: 'Slack',
    base: Offset(0.85, 0.14),
  ),
  _ChaosDoc(
    icon: Icons.tag,
    color: AppColors.slack,
    label: 'Slack',
    base: Offset(0.16, 0.62),
    size: 80,
  ),
  _ChaosDoc(
    icon: Icons.tag,
    color: AppColors.slack,
    label: 'Slack',
    base: Offset(0.62, 0.62),
  ),
  _ChaosDoc(
    icon: Icons.bug_report,
    color: AppColors.backlog,
    label: 'Backlog',
    base: Offset(0.06, 0.32),
    size: 80,
  ),
  _ChaosDoc(
    icon: Icons.bug_report,
    color: AppColors.backlog,
    label: 'Backlog',
    base: Offset(0.68, 0.86),
  ),
  _ChaosDoc(
    icon: Icons.bug_report,
    color: AppColors.backlog,
    label: 'Backlog',
    base: Offset(0.40, 0.62),
    size: 76,
  ),
  _ChaosDoc(
    icon: Icons.slideshow,
    color: AppColors.googleRed,
    label: 'PPT',
    base: Offset(0.90, 0.68),
  ),
  _ChaosDoc(
    icon: Icons.slideshow,
    color: AppColors.googleRed,
    label: 'PPT',
    base: Offset(0.22, 0.88),
    size: 76,
  ),
  _ChaosDoc(
    icon: Icons.article,
    color: AppColors.googleBlue,
    label: 'Word',
    base: Offset(0.48, 0.18),
  ),
  _ChaosDoc(
    icon: Icons.article,
    color: AppColors.googleBlue,
    label: 'Word',
    base: Offset(0.04, 0.86),
    size: 78,
  ),
  _ChaosDoc(
    icon: Icons.notes,
    color: AppColors.claude,
    label: 'MD',
    base: Offset(0.92, 0.32),
    size: 78,
  ),
  _ChaosDoc(
    icon: Icons.notes,
    color: AppColors.claude,
    label: 'MD',
    base: Offset(0.55, 0.88),
  ),
];

const _tanglePairs = [
  (0, 6),
  (1, 9),
  (2, 11),
  (3, 13),
  (4, 15),
  (5, 8),
  (7, 12),
  (0, 14),
  (3, 10),
  (6, 15),
];

class _ChaosCanvas extends StatefulWidget {
  const _ChaosCanvas();

  @override
  State<_ChaosCanvas> createState() => _ChaosCanvasState();
}

class _ChaosCanvasState extends State<_ChaosCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggle;
  late List<Offset> _fractions;
  final _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _fractions = _docs.map((d) => d.base).toList();
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _onDragEnd(int index, DraggableDetails details) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final local = renderBox.globalToLocal(details.offset);
    final size = renderBox.size;
    if (size.width == 0 || size.height == 0) return;

    final half = _docs[index].size / 2;
    setState(() {
      _fractions[index] = Offset(
        ((local.dx + half) / size.width).clamp(0.02, 0.94),
        ((local.dy + half) / size.height).clamp(0.02, 0.94),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return AnimatedBuilder(
          animation: _wiggle,
          builder: (context, _) {
            final points = <Offset>[
              for (var i = 0; i < _docs.length; i++)
                Offset(
                      _fractions[i].dx * size.width,
                      _fractions[i].dy * size.height,
                    ) +
                    Offset(
                      // 周波数は整数倍にすることで、_wiggle が 1.0→0.0 で
                      // ループする瞬間も位相が完全に一致し、カクつかず滑らかに繋がる。
                      math.sin(
                            _wiggle.value * 2 * math.pi * (3 + i % 4) + i * 1.7,
                          ) *
                          14,
                      math.sin(
                            _wiggle.value * 2 * math.pi * (2 + i % 5) + i * 2.3,
                          ) *
                          18,
                    ),
            ];

            return Stack(
              key: _canvasKey,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TangleLinesPainter(points: points),
                  ),
                ),
                for (var i = 0; i < _docs.length; i++)
                  Positioned(
                    left: points[i].dx - _docs[i].size / 2,
                    top: points[i].dy - _docs[i].size / 2,
                    child:
                        Draggable<int>(
                              data: i,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.scale(
                                  scale: 1.15,
                                  child: _Bubble(doc: _docs[i]),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.25,
                                child: _Bubble(doc: _docs[i]),
                              ),
                              onDragEnd: (details) => _onDragEnd(i, details),
                              child: _Bubble(doc: _docs[i]),
                            )
                            .animate(delay: (i * 60).ms)
                            .scale(
                              begin: const Offset(0.3, 0.3),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.doc});

  final _ChaosDoc doc;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: doc.size,
          height: doc.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [
                Colors.white.withValues(alpha: 0.95),
                doc.color.withValues(alpha: 0.5),
              ],
            ),
            border: Border.all(
              color: doc.color.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: doc.color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(doc.icon, color: doc.color, size: doc.size * 0.42),
        ),
        const SizedBox(height: 6),
        Text(
          doc.label,
          style: TextStyle(
            color: doc.color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _TangleLinesPainter extends CustomPainter {
  const _TangleLinesPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final (a, b) in _tanglePairs) {
      if (a >= points.length || b >= points.length) continue;

      final p1 = points[a];
      final p2 = points[b];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 + 40);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TangleLinesPainter oldDelegate) => true;
}
