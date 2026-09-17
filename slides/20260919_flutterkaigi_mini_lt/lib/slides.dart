import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'backdrop.dart';
import 'showcase_video.dart';

/// The presentation artwork lives on a 1920 × 1080 logical canvas.
///
/// The parent supplies navigation, theme, transitions, and the live mascot.
class LtSlide extends StatelessWidget {
  const LtSlide({required this.slideIndex, this.isActive = true, super.key});

  final int slideIndex;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emphasized = slideIndex == 0 || slideIndex == 7 || slideIndex == 15;
    return SizedBox(
      width: 1920,
      height: 1080,
      child: ColoredBox(
        color: scheme.surface,
        child: Stack(
          children: [
            Positioned.fill(child: EventBackdrop(emphasized: emphasized)),
            ..._content(context, scheme),
            _At(
              x: 110,
              y: 1012,
              width: 1450,
              child: Row(
                children: [
                  _Copy(
                    'FlutterKaigi mini #6 / Okayama',
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 30),
                  Container(width: 42, height: 1, color: scheme.outlineVariant),
                  const SizedBox(width: 30),
                  _Copy(
                    '${(slideIndex + 1).toString().padLeft(2, '0')} / 17',
                    size: 22,
                    color: scheme.onSurfaceVariant,
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
    _At(x: 114, y: 76, width: 355, child: _EventBadge(scheme: c)),
    _At(x: 102, y: 300, width: 1740, child: _CoverTitle(c: c)),
    _At(
      x: 112,
      y: 810,
      width: 1500,
      child: _Copy('やくらん  /  2026.09.19', size: 33, color: c.onSurfaceVariant),
    ),
  ];

  List<Widget> _profile(ColorScheme c) => [
    _At(
      x: 114,
      y: 275,
      width: 400,
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(72),
        child: Image.asset('assets/profile/avatar.png', fit: BoxFit.cover),
      ),
    ),
    _At(
      x: 614,
      y: 180,
      width: 1000,
      child: _Copy('やくらん', size: 104, color: c.primary),
    ),
    _At(
      x: 621,
      y: 351,
      width: 1000,
      child: _Copy('岡山.Flutter / FlutterKaigi', size: 38, color: c.secondary),
    ),
    _At(
      x: 622,
      y: 488,
      width: 780,
      child: _ProfileFact(
        icon: Icons.location_on_outlined,
        text: 'Okayama',
        color: c.secondary,
      ),
    ),
    _At(
      x: 622,
      y: 598,
      width: 780,
      child: _ProfileFact(
        icon: Icons.code_rounded,
        text: 'Flutter / Dart / Web',
        color: c.secondary,
      ),
    ),
    _At(
      x: 622,
      y: 708,
      width: 790,
      child: _ProfileFact(
        icon: Icons.sports_esports_outlined,
        text: 'SSBU（スマブラSP） / 個人開発',
        color: c.secondary,
      ),
    ),
    _At(
      x: 1480,
      y: 432,
      width: 300,
      height: 300,
      child: Semantics(
        label: 'Xのプロフィール @yakuran1 のQRコード',
        child: InkWell(
          onTap: () => launchUrl(
            Uri.parse('https://x.com/yakuran1'),
            mode: LaunchMode.externalApplication,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: QrImageView(
              data: 'https://x.com/yakuran1',
              size: 300,
              padding: const EdgeInsets.all(24),
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: c.surface,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: c.surface,
              ),
            ),
          ),
        ),
      ),
    ),
    _At(
      x: 1480,
      y: 754,
      width: 320,
      child: _Copy('X / @yakuran1', size: 30, color: c.onSurfaceVariant),
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
        '少し目を離すと「もう、そこまでできるの？」',
        size: 38,
        color: c.onSurfaceVariant,
      ),
    ),
  ];

  List<Widget> _scene(ColorScheme c) => [
    _heading('半年前に紹介したFlutter Scene'),
    _At(
      x: 115,
      y: 296,
      width: 800,
      child: _Copy('2026/03 / 岡山.Flutter', size: 32, color: c.secondary),
    ),
    _At(
      x: 110,
      y: 374,
      width: 800,
      height: 450,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceContainer.withValues(alpha: .72),
          border: Border.all(color: c.outlineVariant, width: 2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 72, color: c.secondary),
            const SizedBox(height: 26),
            const _Copy('2026/03の発表資料', size: 36),
            const SizedBox(height: 12),
            _Copy('画像をここに差し替え', size: 26, color: c.onSurfaceVariant),
          ],
        ),
      ),
    ),
    _At(
      x: 1040,
      y: 340,
      width: 740,
      child: _Copy('0.9.2-0', size: 98, color: c.secondary),
    ),
    _At(
      x: 1047,
      y: 507,
      width: 700,
      child: Row(
        children: [
          Icon(Icons.south_rounded, size: 48, color: c.outline),
          const SizedBox(width: 25),
          _Copy('今回使ったバージョン', size: 29, color: c.onSurfaceVariant),
        ],
      ),
    ),
    _At(
      x: 1033,
      y: 590,
      width: 755,
      child: _Copy('0.23.0', size: 125, color: c.primary),
    ),
    _At(
      x: 1042,
      y: 799,
      width: 750,
      child: const _Copy('Web対応も サンプルも充実', size: 36),
    ),
    const _At(
      x: 115,
      y: 927,
      width: 1650,
      child: _SourceLink(
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
      child: _Copy('Astraで3Dの表現もぐっと身近に', size: 38, color: c.primary),
    ),
    _At(
      x: 110,
      y: 369,
      width: 830,
      height: 472,
      child: ShowcaseVideo(
        posterAsset: 'assets/showcase/scene_materials.jpg',
        title: '質感と水面',
        videoUrl: 'https://fscene.dev/media/feat-pbr.mp4',
        isActive: isActive,
      ),
    ),
    _At(
      x: 980,
      y: 369,
      width: 830,
      height: 472,
      child: ShowcaseVideo(
        posterAsset: 'assets/showcase/scene_lighting.jpg',
        title: '光と影',
        videoUrl: 'https://fscene.dev/media/feat-lighting.mp4',
        isActive: isActive,
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
      child: _Copy('知識がなくても\nモデル作成から\nサンプルまで', size: 73, color: c.primary),
    ),
  ];

  List<Widget> _idea(ColorScheme c) => [
    _At(
      x: 110,
      y: 165,
      width: 1660,
      child: _Copy('アイデアがそのまま\n動くものに', size: 104, color: c.primary),
    ),
    _At(
      x: 112,
      y: 624,
      width: 1350,
      child: _Copy('「こんなのが欲しい」をすぐに試せる', size: 59, color: c.secondary),
    ),
  ];

  List<Widget> _question(ColorScheme c) => [
    _At(
      x: 110,
      y: 0,
      width: 1650,
      height: 1080,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _Copy('技術の勉強は、\nもういらない？', size: 120, color: c.onSurface),
      ),
    ),
  ];

  List<Widget> _priorities(ColorScheme c) => [
    _heading('このアプリで「なに」を優先させるか？', size: 75),
    _At(
      x: 118,
      y: 442,
      width: 730,
      child: _ChoiceLine(text: '早く試したい？', color: c.primary),
    ),
    _At(
      x: 1010,
      y: 442,
      width: 760,
      child: _ChoiceLine(text: '長く育てたい？', color: c.secondary),
    ),
  ];

  List<Widget> _delegate(ColorScheme c) => [
    _At(
      x: 110,
      y: 182,
      width: 1660,
      child: _Copy('「なぜ」を考える\n時間を増やしたい', size: 106, color: c.primary),
    ),
    _At(
      x: 118,
      y: 581,
      width: 1280,
      child: _Copy('細かいコードはもっとAIに任せて', size: 45, color: c.onSurfaceVariant),
    ),
    _At(
      x: 118,
      y: 714,
      width: 1280,
      child: _Copy('得たい効果と、引き受ける手間を考える', size: 48, color: c.secondary),
    ),
  ];

  List<Widget> _transition(ColorScheme c) => [
    _heading('よく聞く設計の話を、3つの問いに', size: 76),
    _At(
      x: 115,
      y: 338,
      width: 1290,
      child: _DesignQuestion(
        topic: 'feature / layer first',
        question: 'どこに置く？',
        color: c.secondary,
      ),
    ),
    _At(
      x: 115,
      y: 522,
      width: 1290,
      child: _DesignQuestion(
        topic: 'MVVM',
        question: '画面の責務をどう分ける？',
        color: c.primary,
      ),
    ),
    _At(
      x: 115,
      y: 706,
      width: 1290,
      child: _DesignQuestion(
        topic: 'Clean Architecture',
        question: '何を変更から守る？',
        color: c.tertiary,
      ),
    ),
  ];

  List<Widget> _layers(ColorScheme c) => [
    _heading('feature first / layer first', size: 81),
    _At(
      x: 115,
      y: 267,
      width: 600,
      height: 342,
      child: _OrganizationExample(
        title: 'feature first',
        description: '機能のまとまりを先に見る',
        rows: const ['検索 → UI・業務ルール・データ', '詳細 → UI・業務ルール・データ'],
        chosen: false,
        scheme: c,
      ),
    ),
    _At(
      x: 790,
      y: 267,
      width: 600,
      height: 342,
      child: _OrganizationExample(
        title: 'layer first',
        description: '責務の境界を先に見る',
        rows: const ['UI → 検索・詳細', '業務ルール → 検索・詳細'],
        chosen: true,
        scheme: c,
      ),
    ),
    _At(
      x: 116,
      y: 660,
      width: 1270,
      child: _Copy(
        '自分は、機能をまたぐ責務の変化を\n追いやすくしたくて layer first',
        size: 45,
        color: c.primary,
      ),
    ),
    _At(
      x: 118,
      y: 858,
      width: 1280,
      child: _Copy(
        '引き受ける手間：1つの機能の変更でも複数の層をたどる',
        size: 28,
        color: c.onSurfaceVariant,
      ),
    ),
  ];

  List<Widget> _organization(ColorScheme c) => [
    _heading('MVVMで、何を分けたい？', size: 81),
    _At(
      x: 116,
      y: 293,
      width: 1260,
      child: _Copy('表示と、画面の状態・操作を分けたい', size: 52, color: c.primary),
    ),
    _At(
      x: 115,
      y: 425,
      width: 1270,
      height: 195,
      child: Row(
        children: [
          Expanded(
            child: _ResponsibilityBox(
              title: 'View',
              description: '状態を表示する',
              color: c.secondaryContainer,
              foreground: c.onSecondaryContainer,
            ),
          ),
          SizedBox(
            width: 150,
            child: Icon(Icons.sync_alt_rounded, size: 76, color: c.secondary),
          ),
          Expanded(
            child: _ResponsibilityBox(
              title: 'ViewModel',
              description: '状態と操作を受け持つ',
              color: c.primaryContainer,
              foreground: c.onPrimaryContainer,
            ),
          ),
        ],
      ),
    ),
    _At(
      x: 117,
      y: 704,
      width: 1270,
      child: const _Copy('Widgetの外で、画面の振る舞いを確かめる', size: 42),
    ),
    _At(
      x: 119,
      y: 808,
      width: 1270,
      child: _Copy('ただし、同じ責務を二重に持たせない', size: 37, color: c.secondary),
    ),
    _At(
      x: 120,
      y: 897,
      width: 1280,
      child: _Copy(
        'アプリ状態は Application Provider へ集約\n画面専用の ViewModel は追加しなかった',
        size: 24,
        color: c.onSurfaceVariant,
      ),
    ),
  ];

  List<Widget> _motivation(ColorScheme c) => [
    _heading('Clean Architectureで、何を守る？', size: 75),
    _At(
      x: 115,
      y: 278,
      width: 1290,
      child: _Copy('業務ルールを、UIや外部の変更から守る', size: 49, color: c.primary),
    ),
    _At(
      x: 115,
      y: 395,
      width: 1270,
      height: 258,
      child: _DependencyDiagram(scheme: c),
    ),
    _At(
      x: 117,
      y: 725,
      width: 1260,
      child: const _Copy('境界を作る効果は、その手間に見合う？', size: 45),
    ),
    _At(
      x: 119,
      y: 824,
      width: 1260,
      child: _Copy(
        '引き受ける手間：境界の定義やデータの変換を保つ',
        size: 29,
        color: c.onSurfaceVariant,
      ),
    ),
    _At(
      x: 119,
      y: 903,
      width: 1270,
      child: _Copy(
        '自分の採用例は、内側への依存を重視した Onion Architecture',
        size: 25,
        color: c.secondary,
      ),
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
      child: _Copy('AIと書いたコードに、\n自分の「なぜ」を。', size: 55, color: c.onSurface),
    ),
  ];

  List<Widget> _thanks(ColorScheme c) => [
    _At(x: 114, y: 132, width: 355, child: _EventBadge(scheme: c)),
    _At(
      x: 110,
      y: 353,
      width: 1020,
      child: _Copy('ご清聴\nありがとうございました', size: 82, color: c.primary),
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
  Widget build(BuildContext context) {
    final weight = size >= 70
        ? FontWeight.w700
        : size >= 48
        ? FontWeight.w600
        : FontWeight.w400;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        color: color ?? Theme.of(context).colorScheme.onSurface,
        height: 1.48,
        letterSpacing: 0,
      ),
    );
  }
}

class _CoverTitle extends StatelessWidget {
  const _CoverTitle({required this.c, this.compact = false});

  final ColorScheme c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displayLarge!.copyWith(
      fontSize: compact ? 105 : 113,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      height: 1.45,
      letterSpacing: -1.5,
      color: c.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'その'),
              TextSpan(
                text: 'Flutter',
                style: TextStyle(color: c.secondary),
              ),
              const TextSpan(text: 'コード、'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              LinearGradient(colors: [c.primary, c.tertiary])
                  .createShader(bounds),
          child: Text(
            'なぜ書いた？',
            style: style.copyWith(fontSize: compact ? 141 : 158),
          ),
        ),
      ],
    );
  }
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: [scheme.tertiary, scheme.secondary]),
    ),
    child: Text(
      'FlutterKaigi mini #6',
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontSize: 27,
        color: scheme.onSecondary,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
      ),
    ),
  );
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 45),
      const SizedBox(width: 27),
      Expanded(child: _Copy(text, size: 36)),
    ],
  );
}

class _DesignQuestion extends StatelessWidget {
  const _DesignQuestion({
    required this.topic,
    required this.question,
    required this.color,
  });
  final String topic;
  final String question;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          SizedBox(width: 540, child: _Copy(topic, size: 42, color: color)),
          Icon(Icons.arrow_forward_rounded, color: color, size: 36),
          const SizedBox(width: 28),
          Expanded(child: _Copy(question, size: 40)),
        ],
      ),
      const SizedBox(height: 32),
      Container(height: 2, color: color.withValues(alpha: .24)),
    ],
  );
}

class _ResponsibilityBox extends StatelessWidget {
  const _ResponsibilityBox({
    required this.title,
    required this.description,
    required this.color,
    required this.foreground,
  });
  final String title;
  final String description;
  final Color color;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 27),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Copy(title, size: 48, color: foreground),
        const SizedBox(height: 10),
        _Copy(description, size: 29, color: foreground),
      ],
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
      _Copy(text, size: 88, color: color),
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
