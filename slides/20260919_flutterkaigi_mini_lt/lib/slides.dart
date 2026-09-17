import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The presentation artwork lives on a 1920 × 1080 logical canvas.
///
/// The parent supplies navigation, theme, transitions, and the live mascot.
class LtSlide extends StatelessWidget {
  const LtSlide({required this.slideIndex, super.key});

  final int slideIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tinted = slideIndex == 0 || slideIndex == 7 || slideIndex == 15;
    return SizedBox(
      width: 1920,
      height: 1080,
      child: ColoredBox(
        color: tinted ? scheme.primaryContainer : scheme.surface,
        child: Stack(
          children: [
            ..._content(context, scheme),
            _At(
              x: 110,
              y: 1012,
              width: 1450,
              child: Row(
                children: [
                  _Copy(
                    'FlutterKaigi mini 2026',
                    size: 22,
                    color: tinted
                        ? scheme.onPrimaryContainer.withValues(alpha: .65)
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 30),
                  Container(
                    width: 42,
                    height: 1,
                    color: tinted
                        ? scheme.onPrimaryContainer.withValues(alpha: .4)
                        : scheme.outlineVariant,
                  ),
                  const SizedBox(width: 30),
                  _Copy(
                    (slideIndex + 1).toString().padLeft(2, '0'),
                    size: 22,
                    color: tinted
                        ? scheme.onPrimaryContainer.withValues(alpha: .65)
                        : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, ColorScheme c) {
    return switch (slideIndex) {
      0 => _cover(c),
      1 => _profile(c),
      2 => _pace(c),
      3 => _scene(c),
      4 => _showcase(c),
      5 => _demo(c),
      6 => _idea(c),
      7 => _question(c),
      8 => _priorities(c),
      9 => _delegate(c),
      10 => _transition(c),
      11 => _layers(c),
      12 => _organization(c),
      13 => _motivation(c),
      14 => _sharing(c),
      15 => _closing(c),
      16 => _thanks(c),
      _ => _cover(c),
    };
  }

  List<Widget> _cover(ColorScheme c) => [
    _At(
      x: 114,
      y: 158,
      width: 1600,
      child: _Copy(
        'AIと開発する中で、考えておきたいこと',
        size: 32,
        color: c.onPrimaryContainer,
      ),
    ),
    _At(x: 102, y: 300, width: 1740, child: _CoverTitle(c: c)),
    _At(
      x: 112,
      y: 810,
      width: 1500,
      child: _Copy(
        'やくらん  /  2026.09.19',
        size: 33,
        color: c.onPrimaryContainer,
      ),
    ),
  ];

  List<Widget> _profile(ColorScheme c) => [
    _At(
      x: 144,
      y: 230,
      width: 510,
      height: 510,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(96),
        child: Image.asset(
          'assets/profile/avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(
            color: c.secondaryContainer,
            child: Icon(
              Icons.person_outline_rounded,
              size: 190,
              color: c.secondary,
            ),
          ),
        ),
      ),
    ),
    _At(
      x: 784,
      y: 248,
      width: 1000,
      child: _Copy('やくらん', size: 116, color: c.primary),
    ),
    _At(
      x: 796,
      y: 425,
      width: 1000,
      child: _Copy('岡山.Flutter / FlutterKaigi', size: 42, color: c.secondary),
    ),
    _At(
      x: 798,
      y: 555,
      width: 980,
      child: _Copy('Flutterで、\nおもしろそうなことを\n試しています。', size: 49),
    ),
  ];

  List<Widget> _pace(ColorScheme c) => [
    _At(
      x: 110,
      y: 148,
      width: 1700,
      child: _Copy('最近、\n進化が速すぎませんか', size: 104, color: c.primary),
    ),
    _At(
      x: 114,
      y: 626,
      width: 1670,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Copy('LLM', size: 80, color: c.secondary),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 48,
              color: c.outline,
            ),
          ),
          const _Copy('フレームワーク', size: 55),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 48,
              color: c.outline,
            ),
          ),
          const _Copy('パッケージ', size: 55),
        ],
      ),
    ),
    _At(
      x: 114,
      y: 822,
      width: 1600,
      child: _Copy(
        '少し目を離すと、「もう、そこまでできるの？」',
        size: 38,
        color: c.onSurfaceVariant,
      ),
    ),
  ];

  List<Widget> _scene(ColorScheme c) => [
    _heading('半年前に紹介したFlutter Scene'),
    _At(
      x: 120,
      y: 345,
      width: 700,
      child: _Copy('前回 / 岡山.Flutter', size: 32, color: c.onSurfaceVariant),
    ),
    _At(
      x: 112,
      y: 420,
      width: 700,
      child: _Copy('0.9.2-0', size: 143, color: c.secondary),
    ),
    _At(
      x: 805,
      y: 463,
      width: 180,
      child: Icon(Icons.arrow_forward_rounded, size: 100, color: c.outline),
    ),
    _At(
      x: 1080,
      y: 345,
      width: 700,
      child: _Copy('今回使ったバージョン', size: 32, color: c.onSurfaceVariant),
    ),
    _At(
      x: 1068,
      y: 420,
      width: 760,
      child: _Copy('0.23.0', size: 159, color: c.primary),
    ),
    _At(
      x: 114,
      y: 754,
      width: 1650,
      child: _Copy('Webでも動く。サンプルも充実。', size: 61),
    ),
    _At(
      x: 115,
      y: 939,
      width: 1650,
      child: const _SourceLink(
        label: 'Flutter Scene 0.23.0 / pub.dev',
        url: 'https://pub.dev/packages/flutter_scene/versions/0.23.0',
      ),
    ),
  ];

  List<Widget> _showcase(ColorScheme c) => [
    _heading('これもFlutterなの？', size: 88),
    _At(
      x: 116,
      y: 259,
      width: 1650,
      child: _Copy('Astraで、3Dの表現もぐっと身近に', size: 38, color: c.primary),
    ),
    _At(
      x: 110,
      y: 369,
      width: 830,
      height: 472,
      child: _ShowcaseImage(
        asset: 'assets/showcase/scene_materials.jpg',
        scheme: c,
      ),
    ),
    _At(
      x: 980,
      y: 369,
      width: 830,
      height: 472,
      child: _ShowcaseImage(
        asset: 'assets/showcase/scene_lighting.jpg',
        scheme: c,
      ),
    ),
    _At(
      x: 115,
      y: 870,
      width: 1650,
      child: _Copy(
        'Flutter Scene / Brandon DeRosier',
        size: 24,
        color: c.onSurfaceVariant,
      ),
    ),
    _At(
      x: 115,
      y: 921,
      width: 1690,
      child: const Row(
        children: [
          _SourceLink(label: 'fscene.dev', url: 'https://fscene.dev'),
          SizedBox(width: 40),
          _SourceLink(
            label: '作者の紹介投稿',
            url: 'https://www.linkedin.com/posts/bderosier_flutter-dart-3d-activity-7485347941260496896-sOP7',
          ),
        ],
      ),
    ),
  ];

  List<Widget> _demo(ColorScheme c) => [
    _At(
      x: 110,
      y: 200,
      width: 735,
      child: _Copy('モデルから、\n動くサンプルまで', size: 73, color: c.primary),
    ),
  ];

  List<Widget> _idea(ColorScheme c) => [
    _At(
      x: 110,
      y: 144,
      width: 1630,
      child: _Copy('アイデアを、\n動く形にしやすくなった', size: 88, color: c.primary),
    ),
    _At(
      x: 104,
      y: 516,
      width: 1350,
      child: _Copy('「こんなのが欲しい」', size: 75, color: c.secondary),
    ),
    const _At(x: 117, y: 656, width: 1240, child: _Copy('LLMと、試せる。', size: 61)),
  ];

  List<Widget> _question(ColorScheme c) => [
    _At(
      x: 110,
      y: 240,
      width: 1650,
      child: _Copy('技術の勉強は、\nもういらない？', size: 120, color: c.onPrimaryContainer),
    ),
    _At(
      x: 117,
      y: 692,
      width: 1300,
      child: _Copy(
        '作りたいものと、業務の知識があれば十分？',
        size: 38,
        color: c.onPrimaryContainer,
      ),
    ),
  ];

  List<Widget> _priorities(ColorScheme c) => [
    _heading('このアプリで、何を優先するか', size: 75),
    _At(
      x: 118,
      y: 374,
      width: 660,
      child: _ChoiceLine(text: '早く試したい？', color: c.primary),
    ),
    _At(
      x: 917,
      y: 374,
      width: 760,
      child: _ChoiceLine(text: '長く育てたい？', color: c.secondary),
    ),
    const _At(
      x: 116,
      y: 655,
      width: 1230,
      child: _Copy('誰が変更し、\n何を守る？', size: 68),
    ),
  ];

  List<Widget> _delegate(ColorScheme c) => [
    _At(
      x: 109,
      y: 180,
      width: 1680,
      child: _Copy('細かいコードは、\nもっとAIに任せていい', size: 92, color: c.secondary),
    ),
    _At(
      x: 115,
      y: 620,
      width: 1290,
      child: _Copy('自分は、\n構成を選んだ理由を持っておきたい。', size: 47, color: c.primary),
    ),
  ];

  List<Widget> _transition(ColorScheme c) => [
    _At(
      x: 110,
      y: 227,
      width: 1640,
      child: _Copy('では、\n自分はどう選んだか', size: 108, color: c.primary),
    ),
    const _At(
      x: 118,
      y: 630,
      width: 1300,
      child: _Copy('コーディング試験で、\n理由を言葉にした。', size: 48),
    ),
    _At(
      x: 120,
      y: 817,
      width: 1200,
      child: _Copy('GitHubのリポジトリを検索するアプリ', size: 30, color: c.onSurfaceVariant),
    ),
  ];

  List<Widget> _layers(ColorScheme c) => [
    _heading('なぜ、責務を層で分けた？', size: 78),
    _At(
      x: 115,
      y: 247,
      width: 1650,
      child: _Copy('採用：オニオンアーキテクチャ', size: 35, color: c.primary),
    ),
    _At(
      x: 115,
      y: 370,
      width: 1180,
      height: 258,
      child: _DependencyDiagram(scheme: c),
    ),
    _At(
      x: 115,
      y: 704,
      width: 1295,
      child: _Copy('AIが速く生成しても、\n構造を制御しやすくしたい。', size: 51, color: c.primary),
    ),
    _At(
      x: 118,
      y: 896,
      width: 1240,
      child: _Copy(
        '業務ルールを、UIや外部サービスの実装から分離',
        size: 27,
        color: c.onSurfaceVariant,
      ),
    ),
  ];

  List<Widget> _organization(ColorScheme c) => [
    _heading('なぜ、feature firstにしなかった？', size: 72),
    _At(
      x: 115,
      y: 300,
      width: 596,
      height: 342,
      child: _OrganizationExample(
        title: 'feature first',
        description: '機能を先に分ける',
        rows: const ['検索 → UI・業務ルール・データ', '詳細 → UI・業務ルール・データ'],
        chosen: false,
        scheme: c,
      ),
    ),
    _At(
      x: 770,
      y: 300,
      width: 596,
      height: 342,
      child: _OrganizationExample(
        title: 'layer first',
        description: '層を先に分ける',
        rows: const ['UI → 検索・詳細', '業務ルール → 検索・詳細'],
        chosen: true,
        scheme: c,
      ),
    ),
    _At(
      x: 116,
      y: 717,
      width: 1230,
      child: _Copy('業務での機能横断・\n責務の変化を意識した。', size: 53, color: c.primary),
    ),
    _At(
      x: 120,
      y: 909,
      width: 1275,
      child: _Copy(
        '今回の要件なら、feature firstでも問題はなかった。',
        size: 26,
        color: c.onSurfaceVariant,
      ),
    ),
  ];

  List<Widget> _motivation(ColorScheme c) => [
    _heading('「使ってみたい」も、自分の理由', size: 76),
    _At(
      x: 111,
      y: 332,
      width: 1660,
      child: _Copy('流行っているから、使い勝手を学びたい。', size: 51, color: c.secondary),
    ),
    _At(
      x: 111,
      y: 448,
      width: 1660,
      child: _Copy('Flutterが好きだから、可能性を試したい。', size: 51, color: c.primary),
    ),
    const _At(
      x: 115,
      y: 707,
      width: 1270,
      child: _Copy('今回の目的と、\n試せる範囲を言葉にする。', size: 57),
    ),
  ];

  List<Widget> _sharing(ColorScheme c) => [
    _heading('「なぜ？」を共有する', size: 88),
    _At(
      x: 111,
      y: 342,
      width: 1510,
      child: _Copy('「今回は、\n  こういう理由で選びました」', size: 69, color: c.primary),
    ),
    _At(
      x: 115,
      y: 706,
      width: 1280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: 26),
            child: Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 55,
              color: c.secondary,
            ),
          ),
          const Expanded(child: _Copy('別の条件や選択肢を知って、\n考えを更新する。', size: 46)),
        ],
      ),
    ),
  ];

  List<Widget> _closing(ColorScheme c) => [
    _At(x: 105, y: 187, width: 1740, child: _CoverTitle(c: c, compact: true)),
    _At(
      x: 117,
      y: 720,
      width: 1290,
      child: _Copy(
        'AIと書いたコードに、\n自分の「なぜ」を。',
        size: 55,
        color: c.onPrimaryContainer,
      ),
    ),
  ];

  List<Widget> _thanks(ColorScheme c) => [
    _At(
      x: 110,
      y: 265,
      width: 1610,
      child: _Copy('ご清聴\nありがとうございました', size: 94, color: c.primary),
    ),
    _At(
      x: 118,
      y: 655,
      width: 1250,
      child: _Copy('やくらん', size: 36, color: c.onSurfaceVariant),
    ),
  ];

  Widget _heading(String text, {double size = 80}) =>
      _At(x: 109, y: 110, width: 1700, child: _Copy(text, size: size));
}

class _At extends StatelessWidget {
  const _At({
    required this.x,
    required this.y,
    required this.width,
    required this.child,
    this.height,
  });

  final double x;
  final double y;
  final double width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Positioned(left: x, top: y, width: width, height: height, child: child);
}

class _Copy extends StatelessWidget {
  const _Copy(this.text, {this.size = 44, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: 1.48,
      letterSpacing: 0,
    ),
  );
}

class _CoverTitle extends StatelessWidget {
  const _CoverTitle({required this.c, this.compact = false});

  final ColorScheme c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displayLarge!.copyWith(
      fontSize: compact ? 111 : 123,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: -2,
      color: c.onPrimaryContainer,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'その'),
          TextSpan(
            text: 'Flutter',
            style: TextStyle(color: c.secondary),
          ),
          const TextSpan(text: 'コード、\n'),
          TextSpan(
            text: 'なぜ書いた？',
            style: TextStyle(fontSize: compact ? 149 : 169, color: c.primary),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseImage extends StatelessWidget {
  const _ShowcaseImage({required this.asset, required this.scheme});

  final String asset;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: _Copy('Flutter Scene', size: 48, color: scheme.secondary),
        ),
      ),
    ),
  );
}

class _ChoiceLine extends StatelessWidget {
  const _ChoiceLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Copy(text, size: 65, color: color),
      const SizedBox(height: 32),
      Container(height: 3, color: color.withValues(alpha: .36)),
    ],
  );
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 42),
      alignment: Alignment.centerLeft,
      textStyle: Theme.of(context).textTheme.labelLarge!
          .copyWith(fontSize: 21, decoration: TextDecoration.underline),
    ),
    child: Text(label),
  );
}

class _DependencyDiagram extends StatelessWidget {
  const _DependencyDiagram({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 31),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: scheme.secondaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Copy('UI', size: 41, color: scheme.onSecondaryContainer),
              const SizedBox(height: 14),
              _Copy('外部サービスの実装', size: 31, color: scheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
      SizedBox(
        width: 186,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Copy('依存の向き', size: 23, color: scheme.onSurfaceVariant),
            Icon(
              Icons.arrow_forward_rounded,
              size: 81,
              color: scheme.secondary,
            ),
          ],
        ),
      ),
      Expanded(
        child: Container(
          height: 232,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: scheme.primaryContainer,
          ),
          child: _Copy('業務ルール', size: 49, color: scheme.onPrimaryContainer),
        ),
      ),
    ],
  );
}

class _OrganizationExample extends StatelessWidget {
  const _OrganizationExample({
    required this.title,
    required this.description,
    required this.rows,
    required this.chosen,
    required this.scheme,
  });

  final String title;
  final String description;
  final List<String> rows;
  final bool chosen;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final accent = chosen ? scheme.primary : scheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Copy(title, size: 51, color: accent),
            if (chosen) ...[
              const SizedBox(width: 23),
              Icon(Icons.check_circle_outline_rounded, color: accent, size: 36),
            ],
          ],
        ),
        const SizedBox(height: 9),
        _Copy(description, size: 32, color: scheme.onSurfaceVariant),
        const SizedBox(height: 31),
        Container(height: 2, color: accent.withValues(alpha: .4)),
        const SizedBox(height: 27),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _Copy(row, size: 27),
          ),
      ],
    );
  }
}
