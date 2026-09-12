import 'package:flutter/material.dart';

import 'pages.dart';
import 'sources.dart';
import 'theme.dart';

class ChoiceTalkPage extends StatelessWidget {
  const ChoiceTalkPage({required this.page, super.key});
  final ChoicePage page;

  String get _eyebrow => switch (page.kind) {
    PageKind.bridge => '絵本から 技術の話へ',
    PageKind.exam => 'コーディング試験での実践',
    PageKind.architecture => '選んだ理由',
    PageKind.melos => '選ばなかった理由',
    PageKind.learning => '学ぶための選択',
    PageKind.record => '判断を言葉にする',
    PageKind.review => '納得を保つために',
    PageKind.takeaway => '今日の持ち帰り',
    _ => '',
  };

  String? get _source => switch (page.kind) {
    PageKind.exam || PageKind.architecture =>
      '出典：material_github_searcher / technical-decisions.md・retrospective.md',
    PageKind.melos => '出典：technical-decisions.md ／ flutter_deck_slides / IMPLEMENTATION_PLAN.md',
    PageKind.learning ||
    PageKind.record ||
    PageKind.review => '出典：material_github_searcher / technical-decisions.md',
    _ => null,
  };

  @override
  Widget build(BuildContext context) => OsoMaterialSlide(
    eyebrow: _eyebrow,
    title: page.title,
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _body()),
          if (_source != null) ...[
            const SizedBox(height: 20),
            Text(
              _source!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _body() => switch (page.kind) {
    PageKind.bridge => const _Bridge(),
    PageKind.exam => _Exam(asset: page.asset!),
    PageKind.architecture => const _Comparison(
      leftLabel: '重視したこと',
      leftTitle: 'AIが生成しても\n構造を把握できる',
      leftBody: 'オニオンアーキテクチャ\nレイヤーを先に分ける構成',
      rightLabel: '引き受けた負担',
      rightTitle: '要件に対しては\n過剰な設計',
      rightBody: '業務で使う設計を試す機会\n構成や設定が増える負担もある',
      conclusion: '目的と負担を分かったうえで選ぶ',
    ),
    PageKind.melos => const _Comparison(
      leftLabel: 'コーディング試験',
      leftTitle: 'Melosは見送った',
      leftBody: 'Pub Workspaceを利用\n固有の知識を共有する\nコストを抑えたい',
      rightLabel: 'このスライド集',
      rightTitle: 'Melosを採用した',
      rightBody: '複数の資料を選んで起動\n検査とビルドのコマンドを\nまとめたい',
      conclusion: '同じ人でも 条件が変われば選択は変わる',
    ),
    PageKind.learning => const _Learning(),
    PageKind.record => const _Record(),
    PageKind.review => const _Review(),
    PageKind.takeaway => const _Takeaway(),
    _ => const SizedBox.shrink(),
  };
}

class _Bridge extends StatelessWidget {
  const _Bridge();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const _LargeText('知るきっかけは みんなから'),
      const SizedBox(height: 28),
      const _LargeText('選ぶ理由は 自分たちの条件から', accent: true),
      const SizedBox(height: 72),
      const _BodyText('「なぜそうしたか」を言葉にした\nコーディング試験の話'),
      const SizedBox(height: 36),
      Text('やくらん / @yakitama5', style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _Exam extends StatelessWidget {
  const _Exam({required this.asset});
  final String asset;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 440,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          semanticLabel: '試験で実装したGitHubリポジトリ検索アプリの画面',
        ),
      ),
      const SizedBox(width: 84),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LargeText('GitHub検索アプリを\nFlutterで実装'),
            SizedBox(height: 38),
            _BodyText('実装には AIを活用'),
            SizedBox(height: 22),
            _LargeText('選定理由と振り返りは\n自分で書く', accent: true),
          ],
        ),
      ),
    ],
  );
}

class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.leftLabel,
    required this.leftTitle,
    required this.leftBody,
    required this.rightLabel,
    required this.rightTitle,
    required this.rightBody,
    required this.conclusion,
  });
  final String leftLabel;
  final String leftTitle;
  final String leftBody;
  final String rightLabel;
  final String rightTitle;
  final String rightBody;
  final String conclusion;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ChoiceCard(
                label: leftLabel,
                title: leftTitle,
                body: leftBody,
                primary: true,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _ChoiceCard(
                label: rightLabel,
                title: rightTitle,
                body: rightBody,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 34),
      _BodyText(conclusion, accent: true),
    ],
  );
}

/// Card geometry and colours follow the two existing OSO decks.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.title,
    required this.body,
    this.primary = false,
  });
  final String label;
  final String title;
  final String body;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = primary ? colors.onPrimaryContainer : colors.onSurface;
    return Card.filled(
      color: primary ? colors.primaryContainer : colors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(color: ink),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: ink,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              body,
              style: theme.textTheme.titleLarge?.copyWith(
                color: ink,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Learning extends StatelessWidget {
  const _Learning();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const _BodyText('Swift Package Managerを選んだとき'),
      const SizedBox(height: 40),
      const _LargeText('まだ使ったことがなかった\nだから 試してみたかった', accent: true),
      const SizedBox(height: 38),
      const _BodyText('CocoaPods周りの苦労を減らしたい\n未対応パッケージへの懸念も記録した'),
      const SizedBox(height: 36),
      Text(
        '選定した当時の理由と見立て',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _Record extends StatelessWidget {
  const _Record();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _ReasonRow(label: '決定', text: '何を決めたか'),
      _ReasonRow(label: '比較', text: '何と比べたか'),
      _ReasonRow(label: '理由', text: 'なぜ その決定に至ったか'),
      _ReasonRow(label: '不採用', text: '何を選ばず なぜ見送ったか'),
      SizedBox(height: 32),
      _BodyText('未来の自分が 判断の経緯をたどれるように', accent: true),
    ],
  );
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      children: [
        SizedBox(
          width: 220,
          child: Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: _BodyText(text)),
      ],
    ),
  );
}

class _Review extends StatelessWidget {
  const _Review();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _LargeText('当時の理由は いまも成り立つ？', accent: true),
      SizedBox(height: 44),
      _ReasonRow(label: 'Lint', text: 'AIの進化で 別のルールも検討し始めた'),
      _ReasonRow(label: 'Flavor', text: '再調査して 以前の好みから判断を変えた'),
      SizedBox(height: 44),
      _BodyText('迷いも残す\n自分の納得を チームにも説明する'),
    ],
  );
}

class _Takeaway extends StatelessWidget {
  const _Takeaway();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const _LargeText('今回は こういう理由で\nこれを選んだ', accent: true),
      const SizedBox(height: 46),
      const _BodyText('次の選択で 一文だけ残してみる'),
      const SizedBox(height: 60),
      Text('選定メモと振り返り', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      SelectableText(
        codingRepository,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(height: 30),
      Text('やくらん / @yakitama5', style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _LargeText extends StatelessWidget {
  const _LargeText(this.text, {this.accent = false});
  final String text;
  final bool accent;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
      color: accent ? Theme.of(context).colorScheme.primary : null,
      height: 1.4,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text, {this.accent = false});
  final String text;
  final bool accent;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: accent ? Theme.of(context).colorScheme.primary : null,
      height: 1.55,
    ),
  );
}
