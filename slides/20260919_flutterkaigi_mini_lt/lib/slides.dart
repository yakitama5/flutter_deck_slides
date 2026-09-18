import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'backdrop.dart';
import 'pages.dart';
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
    final emphasized = slideIndex == 0 || slideIndex == 7 || slideIndex == 12;
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
                    '${(slideIndex + 1).toString().padLeft(2, '0')} / ${ltPages.length}',
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
      9 => _architecture(c),
      10 => _learningChoices(c),
      11 => _practice(c),
      12 => _closing(c),
      13 => _thanks(c),
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
  ];

  List<Widget> _scene(ColorScheme c) => [
    _heading('半年前に紹介したFlutter Scene'),
    _At(
      x: 115,
      y: 273,
      width: 800,
      child: _Copy('2026/03 / 岡山.Flutter', size: 32, color: c.secondary),
    ),
    _At(
      x: 110,
      y: 340,
      width: 800,
      height: 582,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/showcase/flutter_scene_202603.png',
          fit: BoxFit.contain,
          semanticLabel: '2026年3月の岡山.Flutter発表資料。Flutter UIと3D表示の組み合わせを紹介した画面',
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
      y: 944,
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
      child: _Copy('3Dの知識がなくても\nモデル作成から\nサンプルまで', size: 73, color: c.primary),
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
    _heading('これから、何を学ぶ？', size: 96),
    _At(
      x: 118,
      y: 433,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.account_tree_outlined,
        text: 'アーキテクチャを理解する',
        color: c.primary,
      ),
    ),
    _At(
      x: 118,
      y: 666,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.explore_outlined,
        text: '選択肢を増やす',
        color: c.secondary,
      ),
    ),
  ];

  List<Widget> _architecture(ColorScheme c) => [
    _heading('アーキテクチャを理解する', size: 88),
    _At(
      x: 118,
      y: 267,
      width: 1660,
      child: _Copy('何を優先するかは、自分たちで決める', size: 40, color: c.primary),
    ),
    _At(
      x: 118,
      y: 430,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.schedule_rounded,
        text: 'アプリの未来を見据える',
        color: c.primary,
      ),
    ),
    _At(
      x: 118,
      y: 580,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.check_circle_outline_rounded,
        text: '条件に合うかを考える',
        color: c.secondary,
      ),
    ),
    _At(
      x: 118,
      y: 730,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.balance_rounded,
        text: '引き受ける負担を知る',
        color: c.tertiary,
      ),
    ),
    _At(
      x: 118,
      y: 890,
      width: 1280,
      child: _Copy('AIと相談し、判断に責任を持つ', size: 37, color: c.secondary),
    ),
  ];

  List<Widget> _learningChoices(ColorScheme c) => [
    _heading('知見として、選択肢を増やす', size: 88),
    _At(
      x: 118,
      y: 267,
      width: 1650,
      child: _Copy('たとえば、Flutterアプリに3Dを加えるなら', size: 40, color: c.primary),
    ),
    _At(
      x: 118,
      y: 430,
      width: 1320,
      child: Row(
        children: [
          Expanded(
            child: _TechnologyOption(
              name: 'Unity',
              description: 'ゲームエンジンを組み込む',
              color: c.primary,
            ),
          ),
          const SizedBox(width: 36),
          Expanded(
            child: _TechnologyOption(
              name: 'Flutter Scene',
              description: 'Flutterから3Dを扱う',
              color: c.secondary,
            ),
          ),
        ],
      ),
    ),
    _At(
      x: 118,
      y: 750,
      width: 1280,
      child: _Copy('存在を知っていれば、選べる', size: 62, color: c.secondary),
    ),
    _At(
      x: 118,
      y: 870,
      width: 1280,
      child: _Copy('実現したい内容やアプリサイズに合わせて', size: 35, color: c.onSurfaceVariant),
    ),
  ];

  List<Widget> _practice(ColorScheme c) => [
    _heading('作るときも、「なぜ？」', size: 96),
    _At(
      x: 118,
      y: 459,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.question_answer_outlined,
        text: '理由を聞く',
        color: c.primary,
      ),
    ),
    _At(
      x: 118,
      y: 612,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.check_circle_outline_rounded,
        text: '目的に合う？',
        color: c.secondary,
      ),
    ),
    _At(
      x: 118,
      y: 765,
      width: 1270,
      child: _PromptQuestion(
        icon: Icons.edit_note_rounded,
        text: '理由を残す',
        color: c.tertiary,
      ),
    ),
  ];

  List<Widget> _closing(ColorScheme c) => [
    _At(x: 105, y: 187, width: 1740, child: _CoverTitle(c: c, compact: true)),
    _At(
      x: 117,
      y: 720,
      width: 1290,
      child: _Copy('判断するために、技術を学ぶ。', size: 55, color: c.onSurface),
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

class _PromptQuestion extends StatelessWidget {
  const _PromptQuestion({
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
      Icon(icon, size: 51, color: color),
      const SizedBox(width: 32),
      Expanded(child: _Copy(text, size: 57)),
    ],
  );
}

class _TechnologyOption extends StatelessWidget {
  const _TechnologyOption({
    required this.name,
    required this.description,
    required this.color,
  });

  final String name;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 34),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Copy(name, size: 62, color: color),
        const SizedBox(height: 18),
        _Copy(description, size: 30),
      ],
    ),
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
