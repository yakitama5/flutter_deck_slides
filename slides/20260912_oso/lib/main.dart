import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'speaker_notes.dart';

const _noHeader = FlutterDeckHeaderConfiguration(showHeader: false);
const _noFooter = FlutterDeckFooterConfiguration(showFooter: false);
const _artworkAspectRatio = 1672 / 941;

// The picture book is the opening section of the presentation. Keep these
// numbers in sync with the slide list below because the shared transition
// uses them to distinguish book turns from ordinary presentation slides.
const _frontCoverSlideNumber = 1;
const _firstBookPageSlideNumber = _frontCoverSlideNumber + 1;
const _lastBookPageSlideNumber = 13;
const _backCoverSlideNumber = _lastBookPageSlideNumber + 1;

const _materialSeedColor = Color(0xFF4D6958);
const _bookCoverColor = Color(0xFF31533E);
const _bookAccentColor = Color(0xFFE7C978);

const osoPages = <OsoPageData>[
  OsoPageData(
    number: 1,
    slug: 'title-art',
    title: 'タイトルページ',
    assetPath: 'assets/risukun_hitotsu_no_donguri/00_cover.png',
    speakerNotes: SpeakerNotes.page01,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.02, 0.08),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 2,
    slug: 'first-acorn',
    title: '一粒のどんぐり',
    assetPath: 'assets/risukun_hitotsu_no_donguri/01_page01_pipl.png',
    speakerNotes: SpeakerNotes.page02,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.18, 0.28),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 3,
    slug: 'planting',
    title: 'どんぐりを植える',
    assetPath: 'assets/risukun_hitotsu_no_donguri/02_page02.png',
    speakerNotes: SpeakerNotes.page03,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.36, 0.08),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 4,
    slug: 'daily-care',
    title: '毎日のお世話',
    assetPath: 'assets/risukun_hitotsu_no_donguri/03_page03.png',
    speakerNotes: SpeakerNotes.page04,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.05, 0.18),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 5,
    slug: 'young-tree',
    title: '小さな木と友達',
    assetPath: 'assets/risukun_hitotsu_no_donguri/04_page04_pipl.png',
    speakerNotes: SpeakerNotes.page05,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.12, 0.18),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 6,
    slug: 'big-forest',
    title: '大きな森との出会い',
    assetPath: 'assets/risukun_hitotsu_no_donguri/05_page05.png',
    speakerNotes: SpeakerNotes.page06,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.52, 0.50),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 7,
    slug: 'new-idea',
    title: 'ひらめき',
    assetPath: 'assets/risukun_hitotsu_no_donguri/06_page06.png',
    speakerNotes: SpeakerNotes.page07,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.46, 0.35),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 8,
    slug: 'invite-friends',
    title: '友達を誘う',
    assetPath: 'assets/risukun_hitotsu_no_donguri/07_page07_pipl.png',
    speakerNotes: SpeakerNotes.page08,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.20, 0.06),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 9,
    slug: 'shared-place',
    title: 'みんなの場所',
    assetPath: 'assets/risukun_hitotsu_no_donguri/08_page08_pipl.png',
    speakerNotes: SpeakerNotes.page09,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.02, 0.02),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 10,
    slug: 'pass-the-acorn',
    title: 'どんぐりを渡す',
    assetPath: 'assets/risukun_hitotsu_no_donguri/09_page09.png',
    speakerNotes: SpeakerNotes.page10,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.15, 0.04),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 11,
    slug: 'next-place',
    title: '次の場所へ',
    assetPath: 'assets/risukun_hitotsu_no_donguri/10_page10_pipl.png',
    speakerNotes: SpeakerNotes.page11,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.15, 0.18),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 12,
    slug: 'future-forest',
    title: '育った森',
    assetPath: 'assets/risukun_hitotsu_no_donguri/11_page11_ending_pipl.png',
    speakerNotes: SpeakerNotes.page12,
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.18, 0.12),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
];

void main() => runApp(const OsoStorybookApp());

class OsoStorybookApp extends StatefulWidget {
  const OsoStorybookApp({super.key});

  @override
  State<OsoStorybookApp> createState() => _OsoStorybookAppState();
}

class _OsoStorybookAppState extends State<OsoStorybookApp> {
  late final StorybookSoundEffects _soundEffects;
  late final StorybookPageTurnTransitionBuilder _storybookTransitionBuilder;
  late final FlutterDeckTransition _materialTransition;
  late final FlutterDeckTransition _storybookTransition;

  @override
  void initState() {
    super.initState();
    _soundEffects = StorybookSoundEffects();
    _storybookTransitionBuilder = StorybookPageTurnTransitionBuilder(
      usePerspective: true,
      enableInkReveal: true,
      enableBookOpening: true,
      enableBookClosing: true,
      openingTargetSlideNumber: _firstBookPageSlideNumber,
      closingTargetSlideNumber: _backCoverSlideNumber,
      bookPageStartSlideNumber: _firstBookPageSlideNumber,
      bookPageEndSlideNumber: _lastBookPageSlideNumber,
      useMaterialTransitionForOrdinarySlides: true,
      bookPageCount: 8,
      soundEffects: _soundEffects,
    );
    _materialTransition = FlutterDeckTransition.custom(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 300),
      transitionBuilder: _storybookTransitionBuilder,
    );
    _storybookTransition = FlutterDeckTransition.custom(
      duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
      reverseDuration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
      transitionBuilder: _storybookTransitionBuilder,
    );
  }

  @override
  void dispose() {
    unawaited(_soundEffects.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterDeckApp(
      client: FlutterDeckWebClient(),
      configuration: FlutterDeckConfiguration(
        controls: const FlutterDeckControlsConfiguration(
          presenterToolbarVisible: true,
        ),
        transition: _materialTransition,
      ),
      slides: [
        _buildFrontCoverSlide(),
        for (final page in osoPages) _buildImageSlide(page),
        _buildBackCoverSlide(),
        _buildAfterStoryThanksSlide(),
        _buildAfterStoryBridgeSlide(),
        _buildProfileSlide(),
        _buildStoryMessageSlide(),
        _buildModelStorySlide(),
        _buildTakeawaySlide(),
        _buildCompanySlide(),
        _buildFinalThanksSlide(),
      ],
    );
  }

  FlutterDeckSlide _buildProfileSlide() {
    return _buildMaterialSlide(
      route: '/intro/profile',
      title: '自己紹介',
      eyebrow: 'ABOUT THE SPEAKER',
      subtitle: '竹原 / やくらん / Flutter・Web',
      speakerNotes: SpeakerNotes.introProfile,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            flex: 2,
            child: _ProfileCard(name: '竹原', role: 'やくらん / Flutter・Web'),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '関心のあること',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _TopicChip(label: 'Flutter'),
                      _TopicChip(label: 'Web'),
                      _TopicChip(label: 'つくって試す'),
                      _TopicChip(label: '個人開発'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'つくって試して、面白さを次の人へ。',
                    style: const TextStyle(fontSize: 20, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildCompanySlide() {
    return _buildMaterialSlide(
      route: '/intro/company',
      title: '会社紹介',
      eyebrow: 'PEOPLE SOFTWARE / SPONSOR',
      subtitle: 'ちいさなキッカケを、見つける環境。',
      speakerNotes: SpeakerNotes.introCompany,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoCard(
              number: '01',
              icon: Icons.grass_rounded,
              title: 'ちいさなキッカケ',
              body: '見つける。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '02',
              icon: Icons.explore_outlined,
              title: 'やってみる',
              body: '環境がある。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '03',
              icon: Icons.groups_outlined,
              title: '次の誰かへ',
              body: '広げていく。',
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildFrontCoverSlide() {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: '/storybook/front-cover',
        initial: true,
        title: '絵本の表紙',
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: SpeakerNotes.frontCover,
        transition: _storybookTransition,
      ),
      builder: (context) => const StorybookBookCover(
        coverColor: _bookCoverColor,
        accentColor: _bookAccentColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 72, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 116,
                color: _bookAccentColor,
              ),
              SizedBox(height: 28),
              Text(
                'リスくんと\nひとつのどんぐり',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _bookAccentColor,
                  fontSize: 64,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'ここから、物語で紹介します',
                style: TextStyle(
                  color: Color(0xD1E7C978),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FlutterDeckSlide _buildImageSlide(OsoPageData page) {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route:
            '/storybook/${page.number.toString().padLeft(2, '0')}-${page.slug}',
        title: page.title,
        header: _noHeader,
        footer: _noFooter,
        preloadImages: {page.assetPath},
        speakerNotes: page.speakerNotes,
        transition: _storybookTransition,
      ),
      builder: (context) => StorybookPage(
        key: ValueKey('oso-page-${page.number}'),
        pageNumber: page.number,
        totalPages: osoPages.length,
        paperColor: const Color(0xFFFFFDF5),
        coverColor: const Color(0xFF75523E),
        accentColor: const Color(0xFFB97840),
        outerPadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        borderRadius: 0,
        showPageNumber: false,
        circularSketchReveal: page.circularSketchReveal,
        child: Image.asset(
          page.assetPath,
          key: ValueKey('oso-page-image-${page.number}'),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  FlutterDeckSlide _buildBackCoverSlide() {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: '/storybook/back-cover',
        title: '絵本の裏表紙',
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: SpeakerNotes.backCover,
        transition: _storybookTransition,
      ),
      builder: (context) => const StorybookBookCover(
        backCover: true,
        coverColor: _bookCoverColor,
        accentColor: _bookAccentColor,
      ),
    );
  }

  FlutterDeckSlide _buildAfterStoryThanksSlide() {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: '/after-story/false-thanks',
        title: 'ご清聴ありがとうございました（仮）',
        steps: 2,
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: SpeakerNotes.afterStoryThanks,
        transition: _materialTransition,
      ),
      builder: (context) => const _AfterStoryThanksSlide(),
    );
  }

  FlutterDeckSlide _buildAfterStoryBridgeSlide() {
    return _buildMaterialSlide(
      route: '/after-story/bridge',
      title: 'ここからは、絵本のモデルとなった話と絵本を通して伝えたかった内容の話になります',
      eyebrow: 'AFTER THE STORY',
      subtitle: '絵本の「一粒」を、実際の体験とメッセージに重ねます。',
      speakerNotes: SpeakerNotes.afterStoryBridge,
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: _StatementCard(
              icon: Icons.compare_arrows_rounded,
              title: '絵本から、現実の話へ',
              body: '物語に込めたメッセージと、そのモデルになった体験を振り返ります。',
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 2,
            child: _IconPanel(
              icon: Icons.auto_stories_rounded,
              label: 'NEXT CHAPTER',
              color: _bookCoverColor,
              iconColor: _bookAccentColor,
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildStoryMessageSlide() {
    return _buildMaterialSlide(
      route: '/message/story',
      title: '絵本で伝えたかったこと',
      eyebrow: 'WHAT THE STORY SAYS',
      subtitle: '2つのメッセージ。',
      speakerNotes: SpeakerNotes.storyMessage,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoCard(
              number: '01',
              icon: Icons.grass_rounded,
              title: 'ちいさな一粒',
              body: '最初の一歩。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '02',
              icon: Icons.auto_awesome_rounded,
              title: 'おもしろい',
              body: '次の誰かへ広がる。',
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildModelStorySlide() {
    return _buildMaterialSlide(
      route: '/message/model-story',
      title: '絵本のモデルとなった話',
      eyebrow: 'THE STORY BEHIND THE STORY',
      subtitle: '4つの出来事。',
      speakerNotes: SpeakerNotes.modelStory,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoCard(
              number: '01',
              icon: Icons.emoji_events_outlined,
              title: '会社のコンテスト',
              body: 'Flutterを始める。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '02',
              icon: Icons.code_rounded,
              title: '個人開発',
              body: '人とのつながりが広がる。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '03',
              icon: Icons.local_fire_department_outlined,
              title: 'FlutterKaigi',
              body: 'コミュニティの熱を感じる。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '04',
              icon: Icons.groups_rounded,
              title: '広げる側へ',
              body: '岡山.Flutter / コアスタッフ。',
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildTakeawaySlide() {
    return _buildMaterialSlide(
      route: '/experience/takeaway',
      title: '持ち帰り',
      eyebrow: 'TAKEAWAY',
      subtitle: '些細なキッカケを、大事に。',
      speakerNotes: SpeakerNotes.takeaway,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StatementCard(
            icon: Icons.park_rounded,
            title: 'まず、やってみる。',
            body: '「おもしろい」を、次の一歩へ。',
          ),
          const SizedBox(height: 28),
          Text(
            'あなたの「一粒」を、大切に。',
            style: const TextStyle(
              color: _materialSeedColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildFinalThanksSlide() {
    return _buildMaterialSlide(
      route: '/closing/thanks',
      title: 'ご清聴ありがとうございました',
      eyebrow: 'THANK YOU',
      subtitle: '小さな一歩が、次の誰かへつながりますように。',
      speakerNotes: SpeakerNotes.finalThanks,
      child: Center(
        child: Text(
          'ありがとうございました！',
          style: const TextStyle(
            color: _materialSeedColor,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  FlutterDeckSlide _buildMaterialSlide({
    required String route,
    required String title,
    required String eyebrow,
    required Widget child,
    String? subtitle,
    String? stepLabel,
    String? speakerNotes,
    bool initial = false,
  }) {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: route,
        initial: initial,
        title: title,
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: speakerNotes ?? '',
        transition: _materialTransition,
      ),
      builder: (context) => OsoMaterialSlide(
        eyebrow: eyebrow,
        title: title,
        subtitle: subtitle,
        stepLabel: stepLabel,
        child: child,
      ),
    );
  }
}

class OsoPageData {
  const OsoPageData({
    required this.number,
    required this.slug,
    required this.title,
    required this.assetPath,
    required this.speakerNotes,
    required this.circularSketchReveal,
  });

  final int number;
  final String slug;
  final String title;
  final String assetPath;
  final String speakerNotes;
  final StorybookCircularSketchReveal circularSketchReveal;
}

class OsoMaterialSlide extends StatelessWidget {
  const OsoMaterialSlide({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.subtitle,
    this.stepLabel,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? stepLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _materialSeedColor,
          brightness: Brightness.light,
        ),
      ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          return DecoratedBox(
            decoration: BoxDecoration(color: colors.surface),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 36, 44, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        eyebrow,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      if (stepLabel != null)
                        _SmallPill(
                          label: stepLabel!,
                          color: colors.primaryContainer,
                          textColor: colors.onPrimaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Expanded(child: child),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 16,
                        color: colors.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FlutterDeck / リスくんとひとつのどんぐり',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AfterStoryThanksSlide extends StatelessWidget {
  const _AfterStoryThanksSlide();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bookCoverColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ご清聴ありがとうございました',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _bookAccentColor,
                fontSize: 68,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            FlutterDeckSlideStepsBuilder(
              builder: (context, stepNumber) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  child: stepNumber < 2
                      ? const SizedBox(
                          key: ValueKey('after-story-thanks-placeholder'),
                          height: 54,
                        )
                      : const Text(
                          'とはいかず……',
                          key: ValueKey('after-story-thanks-not-yet'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: colors.onPrimaryContainer),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.onPrimaryContainer, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPanel extends StatelessWidget {
  const _IconPanel({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 92, color: iconColor),
            const SizedBox(height: 18),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 52,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              role,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.check_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(label),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 36, color: colors.primary),
                Text(
                  number,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.outline,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
