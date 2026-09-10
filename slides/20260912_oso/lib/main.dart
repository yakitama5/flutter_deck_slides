import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'speaker_notes.dart';

const _noHeader = FlutterDeckHeaderConfiguration(showHeader: false);
const _noFooter = FlutterDeckFooterConfiguration(showFooter: false);
const _artworkAspectRatio = 1672 / 941;

const _frontCoverSlideNumber = 5;
const _firstBookPageSlideNumber = _frontCoverSlideNumber + 1;
const _lastBookPageSlideNumber = 17;
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
    assetPath: 'assets/risukun_hitotsu_no_donguri/01_page01.png',
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
    assetPath: 'assets/risukun_hitotsu_no_donguri/04_page04.png',
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
    assetPath: 'assets/risukun_hitotsu_no_donguri/07_page07.png',
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
    assetPath: 'assets/risukun_hitotsu_no_donguri/08_page08.png',
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
    assetPath: 'assets/risukun_hitotsu_no_donguri/10_page10.png',
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
    assetPath: 'assets/risukun_hitotsu_no_donguri/11_page11_ending.png',
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
        _buildTitleSlide(),
        _buildProfileSlide(),
        _buildCompanySlide(),
        _buildStoryBridgeSlide(),
        _buildFrontCoverSlide(),
        for (final page in osoPages) _buildImageSlide(page),
        _buildBackCoverSlide(),
        _buildExperienceIntroSlide(),
        _buildExperienceTimelineSlide(),
        _buildTakeawaySlide(),
      ],
    );
  }

  FlutterDeckSlide _buildTitleSlide() {
    return _buildMaterialSlide(
      route: '/intro/title',
      title: '自分でつくる、伝える。',
      eyebrow: 'オープンセミナー岡山 / 2026',
      initial: true,
      subtitle: '「リスくんとひとつのどんぐり」から考える、小さな一歩の育て方',
      stepLabel: '01 / 04',
      speakerNotes: SpeakerNotes.introTitle,
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: _StatementCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'つくったものを、物語として手渡す',
              body: 'プロダクトの話を、まずは一粒のどんぐりから始めます。',
            ),
          ),
          const SizedBox(width: 28),
          const Expanded(
            flex: 2,
            child: _IconPanel(
              icon: Icons.auto_stories_rounded,
              label: 'TODAY\'S STORY',
              color: _bookCoverColor,
              iconColor: _bookAccentColor,
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildProfileSlide() {
    return _buildMaterialSlide(
      route: '/intro/profile',
      title: 'まず、自己紹介',
      eyebrow: 'ABOUT THE SPEAKER',
      subtitle: '試して、観察して、次の人に渡すのが好きです。',
      stepLabel: '02 / 04',
      speakerNotes: SpeakerNotes.introProfile,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            flex: 2,
            child: _ProfileCard(name: 'やきたま', role: 'Flutter / Web / つくって試す人'),
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
                      _TopicChip(label: 'プロトタイプ'),
                      _TopicChip(label: 'チームで学ぶ'),
                      _TopicChip(label: '伝わるデザイン'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '完成品を見せるだけではなく、そこに至る試行錯誤も一緒に共有します。',
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
      eyebrow: 'ABOUT THE COMPANY / SAMPLE',
      subtitle: 'サンプルの会社紹介です。発表前に社名・数字・事例を差し替えて使えます。',
      stepLabel: '03 / 04',
      speakerNotes: SpeakerNotes.introCompany,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoCard(
              number: '01',
              icon: Icons.edit_note_rounded,
              title: '小さくつくる',
              body: 'まず触れる形にして、会話を始めます。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '02',
              icon: Icons.people_alt_outlined,
              title: '一緒に試す',
              body: '使う人の反応を、次の判断に活かします。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '03',
              icon: Icons.forest_outlined,
              title: '学びをひらく',
              body: 'チームの外にも、経験を渡していきます。',
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildStoryBridgeSlide() {
    return _buildMaterialSlide(
      route: '/intro/story-bridge',
      title: 'ここから、1冊の絵本へ',
      eyebrow: 'STORYBOOK MODE',
      subtitle: '説明をいったん物語に預けて、ひとつの体験を追いかけます。',
      stepLabel: '04 / 04',
      speakerNotes: SpeakerNotes.introStoryBridge,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StoryBridgeCard(),
          const SizedBox(height: 26),
          Text(
            '右矢印で本を開きます',
            style: const TextStyle(
              color: _materialSeedColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
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

  FlutterDeckSlide _buildExperienceIntroSlide() {
    return _buildMaterialSlide(
      route: '/experience/intro',
      title: '実体験の紹介',
      eyebrow: 'AFTER THE STORY',
      subtitle: '絵本の「一粒」を、現場で起きたことに重ねてみます。',
      speakerNotes: SpeakerNotes.experienceIntro,
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: _StatementCard(
              icon: Icons.grass_rounded,
              title: '一粒を、次の人へ',
              body: '小さく始めたものが、誰かの反応を受け取り、次の一歩に変わっていきました。',
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 2,
            child: _IconPanel(
              icon: Icons.forum_outlined,
              label: 'REAL EXPERIENCE',
              color: _materialSeedColor,
              iconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildExperienceTimelineSlide() {
    return _buildMaterialSlide(
      route: '/experience/timeline',
      title: '小さく始めて、反応を見ながら育てた',
      eyebrow: 'ONE EXPERIENCE / SAMPLE',
      subtitle: '実体験の紹介フェーズのサンプルです。実際の出来事・数字・写真に差し替えられます。',
      speakerNotes: SpeakerNotes.experienceTimeline,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoCard(
              number: '01',
              icon: Icons.visibility_outlined,
              title: '観察する',
              body: '困りごとと、すでにある工夫を知る。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '02',
              icon: Icons.build_outlined,
              title: '試してみる',
              body: '触れる大きさのプロトタイプを渡す。',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _InfoCard(
              number: '03',
              icon: Icons.sync_alt_rounded,
              title: '受け取る',
              body: '反応を次の一手にして、もう一度育てる。',
            ),
          ),
        ],
      ),
    );
  }

  FlutterDeckSlide _buildTakeawaySlide() {
    return _buildMaterialSlide(
      route: '/experience/takeaway',
      title: '今日、持ち帰ってほしいこと',
      eyebrow: 'TAKEAWAY',
      speakerNotes: SpeakerNotes.experienceTakeaway,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StatementCard(
            icon: Icons.park_rounded,
            title: '完成した大木ではなく、まず一粒を渡す。',
            body: '手渡した人の反応が、次の枝と、次の仲間を連れてきます。',
          ),
          const SizedBox(height: 28),
          Text(
            'あなたの「一粒」は何ですか？',
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
        speakerNotes: speakerNotes,
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

class _StoryBridgeCard extends StatelessWidget {
  const _StoryBridgeCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _BridgeStep(
              icon: Icons.business_center_outlined,
              label: '会社の話',
            ),
            _BridgeArrow(color: colors.primary),
            const _BridgeStep(icon: Icons.grass_rounded, label: '体験の種'),
            _BridgeArrow(color: colors.primary),
            const _BridgeStep(icon: Icons.auto_stories_rounded, label: '1冊の絵本'),
          ],
        ),
      ),
    );
  }
}

class _BridgeStep extends StatelessWidget {
  const _BridgeStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, size: 34, color: colors.onPrimaryContainer),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BridgeArrow extends StatelessWidget {
  const _BridgeArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Icon(Icons.arrow_forward_rounded, color: color, size: 30),
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
