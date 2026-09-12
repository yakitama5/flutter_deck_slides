import 'package:flutter/material.dart';

import 'demos.dart';
import 'pages.dart';
import 'theme.dart';

const chapterNames = ['', '設計を選ぶ', '開発環境を選ぶ', '品質の守り方を選ぶ', 'UIを選ぶ', '判断を振り返る'];
const chapterIcons = [
  Icons.auto_stories_outlined,
  Icons.layers_outlined,
  Icons.terminal_rounded,
  Icons.fact_check_outlined,
  Icons.palette_outlined,
  Icons.bookmark_border_rounded,
];

class ReasonSlide extends StatelessWidget {
  const ReasonSlide({required this.page, super.key});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) {
    final dark =
        page.kind == ReasonKind.cover || page.kind == ReasonKind.takeaway;
    return ReasonCanvas(
      dark: dark,
      child: PaperBackdrop(
        dark: dark,
        child: Builder(
          builder: (context) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(100, 64, 100, 110),
                    child: switch (page.kind) {
                      ReasonKind.cover => _Cover(page: page),
                      ReasonKind.chapter => _Chapter(page: page),
                      ReasonKind.agenda => _Agenda(page: page),
                      ReasonKind.takeaway => _Takeaway(page: page),
                      ReasonKind.references => _References(page: page),
                      ReasonKind.appendix => _Appendix(page: page),
                      _ => _ReasonBody(page: page),
                    },
                  ),
                ),
                Positioned(
                  left: 100,
                  right: 100,
                  bottom: 34,
                  child: _Footer(page: page, dark: dark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.page, required this.dark});
  final ReasonPage page;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? const Color(0xFFBDC8ED) : muted;
    return Column(
      children: [
        Container(height: 1, color: color.withValues(alpha: .25)),
        const SizedBox(height: 15),
        Row(
          children: [
            Text(
              page.sourceLabel.isEmpty ? '技術選定に、自分の理由を。' : page.sourceLabel,
              style: TextStyle(fontSize: 20, color: color),
            ),
            const Spacer(),
            for (var i = 1; i <= 5; i++)
              Container(
                width: 25,
                height: 4,
                margin: const EdgeInsets.only(left: 7),
                color: page.chapter == i
                    ? (dark ? Colors.white : blue)
                    : color.withValues(alpha: .2),
              ),
            const SizedBox(width: 30),
            Text(
              '${reasonPages.indexOf(page) + 1}'.padLeft(2, '0'),
              style: TextStyle(fontSize: 24, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 88),
            const Text(
              'コーディング試験の 振り返りから',
              style: TextStyle(
                fontSize: 28,
                color: Color(0xFFC6CEEE),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 56),
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 88,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 38),
            Container(
              width: 145,
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9DAEE9), Color(0xFFBD9ADD)],
                ),
              ),
            ),
            const SizedBox(height: 38),
            Text(
              page.lead,
              style: const TextStyle(
                fontSize: 32,
                height: 1.65,
                color: Color(0xFFD2D9F1),
              ),
            ),
            const Spacer(),
            const Text(
              'やくらん  /  @yakitama5',
              style: TextStyle(fontSize: 27, color: Color(0xFFBFC9EA)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      const Expanded(
        flex: 5,
        child: Padding(
          padding: EdgeInsets.only(top: 75),
          child: ReasonBookArt(),
        ),
      ),
    ],
  );
}

class _Chapter extends StatelessWidget {
  const _Chapter({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CHAPTER  ${page.chapter.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 4,
                color: purple,
              ),
            ),
            const SizedBox(height: 36),
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 80,
                height: 1.4,
                color: ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 44),
            Container(width: 100, height: 4, color: purple),
            const SizedBox(height: 38),
            Text(
              page.lead,
              style: const TextStyle(fontSize: 38, height: 1.7, color: muted),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '0${page.chapter}',
              style: const TextStyle(
                fontSize: 190,
                height: 1,
                color: Color(0xFFD9DEF1),
              ),
            ),
            SizedBox(height: 510, child: ReasonBookArt(chapter: page.chapter)),
          ],
        ),
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(chapterIcons[page.chapter], size: 29, color: purple),
          const SizedBox(width: 14),
          Text(
            page.kicker.isNotEmpty ? page.kicker : chapterNames[page.chapter],
            style: const TextStyle(
              fontSize: 25,
              color: purple,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 25),
      Text(
        page.title,
        style: const TextStyle(
          fontSize: 66,
          height: 1.3,
          color: ink,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _Agenda extends StatelessWidget {
  const _Agenda({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Heading(page: page),
      const SizedBox(height: 50),
      Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '0$i',
                            style: const TextStyle(fontSize: 35, color: purple),
                          ),
                          const SizedBox(width: 34),
                          Icon(chapterIcons[i], color: blue, size: 42),
                          const SizedBox(width: 24),
                          Text(
                            chapterNames[i],
                            style: const TextStyle(fontSize: 39, color: ink),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 110),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.lead,
                    style: const TextStyle(
                      fontSize: 43,
                      height: 1.7,
                      color: blue,
                    ),
                  ),
                  const SizedBox(height: 45),
                  Text(
                    page.reason,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.7,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 45),
                  const Row(
                    children: [
                      Icon(Icons.touch_app_outlined, color: purple, size: 33),
                      SizedBox(width: 16),
                      Text(
                        '第4章は、触って試せるサンプル付き',
                        style: TextStyle(fontSize: 27, color: purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ReasonBody extends StatelessWidget {
  const _ReasonBody({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Heading(page: page),
      const SizedBox(height: 42),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選んだこと',
                      style: TextStyle(fontSize: 24, color: purple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.decision,
                      style: const TextStyle(
                        fontSize: 36,
                        height: 1.5,
                        color: blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'その理由',
                      style: TextStyle(fontSize: 24, color: purple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.reason,
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.6,
                        color: ink,
                      ),
                    ),
                    const Spacer(),
                    if (page.tradeoff.isNotEmpty) ...[
                      Container(
                        width: 60,
                        height: 3,
                        color: const Color(0xFFC6B9E0),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        page.tradeoff,
                        style: const TextStyle(
                          fontSize: 27,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: rule),
            const SizedBox(width: 46),
            SizedBox(width: 790, child: _Evidence(page: page)),
          ],
        ),
      ),
    ],
  );
}

class _Evidence extends StatelessWidget {
  const _Evidence({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) {
    final demo = switch (page.kind) {
      ReasonKind.theme => const ThemeChoiceDemo(),
      ReasonKind.responsive => const ResponsiveChoiceDemo(),
      ReasonKind.localization => const LocalizationChoiceDemo(),
      _ => null,
    };
    if (demo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 28, color: blue),
              SizedBox(width: 12),
              Text('動かして確かめる', style: TextStyle(fontSize: 26, color: blue)),
              Spacer(),
              Text('説明用ミニサンプル', style: TextStyle(fontSize: 21, color: muted)),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: SizedBox(width: 760, height: 620, child: demo),
            ),
          ),
        ],
      );
    }
    return switch (page.kind) {
      ReasonKind.architecture => _Architecture(page: page),
      ReasonKind.workspace => _Workspace(page: page),
      ReasonKind.investment => _Investment(page: page),
      _ => _ReasonNotes(page: page),
    };
  }
}

class _Architecture extends StatelessWidget {
  const _Architecture({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        '責務ごとに、置き場所を決める',
        style: TextStyle(fontSize: 32, color: purple),
      ),
      const SizedBox(height: 32),
      for (final (label, sub, tint) in [
        ('Presentation', '画面と操作', const Color(0xFFEEF0FA)),
        ('Application', 'ユースケースを組み立てる', const Color(0xFFE0E7FA)),
        ('Domain', 'ルールと抽象', const Color(0xFFDCD4F0)),
      ]) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 33, color: ink)),
              const Spacer(),
              Text(sub, style: const TextStyle(fontSize: 26, color: muted)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            label == 'Domain' ? Icons.north_rounded : Icons.south_rounded,
            size: 24,
            color: blue,
          ),
        ),
      ],
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: purple.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Infrastructure は Domain の抽象を実装',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, color: purple),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        '矢印は依存方向。外側から Domain の抽象へ',
        style: TextStyle(fontSize: 22, color: muted),
      ),
    ],
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.page});
  final ReasonPage page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        '同じ道具でも、条件で変わる',
        style: TextStyle(fontSize: 32, color: purple),
      ),
      const SizedBox(height: 36),
      _ChoiceRow(
        label: 'コーディング試験',
        title: 'Pub Workspace',
        detail: 'Melos固有の知識を共有する負担を抑える',
        color: blue,
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Divider(color: rule),
      ),
      _ChoiceRow(
        label: 'このスライド集',
        title: 'Pub Workspace + Melos',
        detail: '資料の選択・検査・ビルドをまとめる',
        color: purple,
      ),
      const SizedBox(height: 40),
      const Text('採用も、不採用も、理由がある', style: TextStyle(fontSize: 34, color: ink)),
    ],
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.title,
    required this.detail,
    required this.color,
  });
  final String label;
  final String title;
  final String detail;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 25, color: color)),
      const SizedBox(height: 15),
      Text(title, style: TextStyle(fontSize: 38, color: color)),
      const SizedBox(height: 15),
      Text(
        detail,
        style: const TextStyle(fontSize: 28, height: 1.6, color: muted),
      ),
    ],
  );
}

class _ReasonNotes extends StatelessWidget {
  const _ReasonNotes({required this.page});
  final ReasonPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (page.lead.isNotEmpty) ...[
        Text(
          page.lead,
          style: const TextStyle(fontSize: 39, height: 1.6, color: blue),
        ),
        const SizedBox(height: 38),
      ],
      for (var i = 0; i < page.items.length; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(
                switch (page.kind) {
                  ReasonKind.environment => Icons.terminal_rounded,
                  ReasonKind.spm => Icons.explore_outlined,
                  ReasonKind.quality => Icons.check_circle_outline,
                  ReasonKind.harness => Icons.tune_rounded,
                  ReasonKind.reconsider => Icons.edit_note_rounded,
                  _ => Icons.bookmark_border_rounded,
                },
                size: 34,
                color: i.isEven ? blue : purple,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                page.items[i],
                style: const TextStyle(fontSize: 33, height: 1.65, color: ink),
              ),
            ),
          ],
        ),
        if (i < page.items.length - 1)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: rule),
          ),
      ],
    ],
  );
}

class _Investment extends StatelessWidget {
  const _Investment({required this.page});
  final ReasonPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('今回の「セーブポイント」', style: TextStyle(fontSize: 40, color: blue)),
      const SizedBox(height: 48),
      for (var i = 0; i < page.items.length; i++) ...[
        Text(
          i == 0
              ? '残せたもの'
              : i == 1
              ? '反省したこと'
              : '次に試したいこと',
          style: const TextStyle(fontSize: 24, color: purple),
        ),
        const SizedBox(height: 12),
        Text(
          page.items[i],
          style: const TextStyle(fontSize: 34, height: 1.6, color: ink),
        ),
        const SizedBox(height: 36),
      ],
    ],
  );
}

class _Takeaway extends StatelessWidget {
  const _Takeaway({required this.page});
  final ReasonPage page;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '次の選択に、持っていくこと',
              style: TextStyle(fontSize: 27, color: Color(0xFFBFC8EA)),
            ),
            const SizedBox(height: 43),
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 78,
                height: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 45),
            Text(
              page.lead,
              style: const TextStyle(
                fontSize: 36,
                height: 1.8,
                color: Color(0xFFD0D8F0),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              page.reason,
              style: const TextStyle(
                fontSize: 28,
                height: 1.7,
                color: Color(0xFFBFC8EA),
              ),
            ),
          ],
        ),
      ),
      const Expanded(flex: 4, child: ReasonBookArt()),
    ],
  );
}

class _References extends StatelessWidget {
  const _References({required this.page});
  final ReasonPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Heading(page: page),
      const SizedBox(height: 45),
      Text(page.lead, style: const TextStyle(fontSize: 32, color: muted)),
      const SizedBox(height: 42),
      for (final item in page.items) ...[
        Text(
          item,
          style: const TextStyle(fontSize: 32, height: 1.6, color: ink),
        ),
        const SizedBox(height: 25),
      ],
      const Spacer(),
      const SelectableText(
        'github.com/yakitama5/material_github_searcher\ngithub.com/yakitama5/flutter_deck_slides',
        style: TextStyle(fontSize: 30, height: 1.8, color: blue),
      ),
      const SizedBox(height: 24),
      Text(
        page.reason,
        style: const TextStyle(fontSize: 25, height: 1.7, color: muted),
      ),
    ],
  );
}

class _Appendix extends StatelessWidget {
  const _Appendix({required this.page});
  final ReasonPage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Heading(page: page),
      const SizedBox(height: 40),
      Expanded(
        child: Column(
          children: [
            for (var i = 0; i < page.items.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            '0${i + 1}',
                            style: const TextStyle(fontSize: 33, color: purple),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            page.items[i],
                            style: const TextStyle(
                              fontSize: 34,
                              height: 1.6,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    if (i < page.items.length - 1) const Divider(color: rule),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
