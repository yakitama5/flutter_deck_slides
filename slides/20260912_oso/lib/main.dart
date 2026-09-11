import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'speaker_notes.dart';
import 'theme.dart';
import 'widgets.dart';

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
      // The slides are drawn light whatever the machine is set to, so the deck
      // chrome around them has to be pinned as well. Left on system, a laptop
      // in dark mode frames every slide in a dark border.
      themeMode: ThemeMode.light,
      configuration: FlutterDeckConfiguration(
        controls: const FlutterDeckControlsConfiguration(
          presenterToolbarVisible: true,
        ),
        progressIndicator: const FlutterDeckProgressIndicator.solid(
          color: osoSeedColor,
          backgroundColor: osoAccentColor,
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
      speakerNotes: SpeakerNotes.introProfile,
      child: const OsoProfileBody(),
    );
  }

  /// The sponsor slide skips the shared chrome: the photo is meant to fill the
  /// top of the screen, which a title and a lead-in line would not leave room
  /// for.
  FlutterDeckSlide _buildCompanySlide() {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: '/intro/company',
        title: '会社紹介',
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: SpeakerNotes.introCompany,
        transition: _materialTransition,
      ),
      builder: (context) => const OsoCompanySlide(),
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
        showProgress: false,
        speakerNotes: SpeakerNotes.frontCover,
        transition: _storybookTransition,
      ),
      builder: (context) => const StorybookBookCover(
        coverColor: osoSeedColor,
        accentColor: osoAccentColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 72, vertical: 48),
          child: StorybookCoverEmblem(accentColor: osoAccentColor),
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
        showProgress: false,
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
        showProgress: false,
        speakerNotes: SpeakerNotes.backCover,
        transition: _storybookTransition,
      ),
      builder: (context) => const StorybookBookCover(
        backCover: true,
        coverColor: osoSeedColor,
        accentColor: osoAccentColor,
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
      title: '絵本から、現実の話へ',
      eyebrow: 'AFTER THE STORY',
      subtitle: '絵本の「一粒」が、現実ではどんな出来事だったのかを振り返ります。',
      speakerNotes: SpeakerNotes.afterStoryBridge,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: OsoStatementCard(
              icon: Icons.compare_arrows_rounded,
              title: 'ここからは、\n絵本のモデルになった話。',
              body: '物語に込めたメッセージと、そのモデルになった体験を振り返ります。',
            ),
          ),
          SizedBox(width: 40),
          Expanded(
            flex: 2,
            child: OsoIconPanel(
              icon: Icons.auto_stories_rounded,
              label: 'NEXT CHAPTER',
              color: osoSeedColor,
              iconColor: osoAccentColor,
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
      steps: 2,
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).colorScheme;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OsoMessageCard(
                  number: '01',
                  icon: Icons.spa_rounded,
                  headline: 'はじまりは、\nちいさな一粒。',
                  body: '最初の一歩は、いつも小さい。',
                  color: colors.tertiaryContainer,
                  onColor: colors.onTertiaryContainer,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: OsoStepReveal(
                  step: 2,
                  child: Center(child: OsoFlowArrow()),
                ),
              ),
              Expanded(
                child: OsoStepReveal(
                  step: 2,
                  child: OsoMessageCard(
                    number: '02',
                    icon: Icons.auto_awesome_rounded,
                    headline: '「おもしろい」は、\n次の誰かへ広がる。',
                    body: 'その感動が原動力になって、\nまた新しい一歩が生まれる。',
                    color: colors.primaryContainer,
                    onColor: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FlutterDeckSlide _buildModelStorySlide() {
    return _buildMaterialSlide(
      route: '/message/model-story',
      title: '絵本のモデルとなった話',
      eyebrow: 'THE STORY BEHIND THE STORY',
      subtitle: 'ひと粒から、いまの活動まで。',
      speakerNotes: SpeakerNotes.modelStory,
      steps: 4,
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).colorScheme;

          return OsoGrowthRow(
            stages: [
              OsoGrowthStage(
                number: '01',
                step: 1,
                icon: Icons.emoji_events_rounded,
                title: '社内コンテスト',
                body: 'Flutterを始める。',
                color: colors.surfaceContainerHigh,
                onColor: colors.onSurface,
                heightFactor: 0.66,
                leafCount: 1,
              ),
              OsoGrowthStage(
                number: '02',
                step: 2,
                icon: Icons.code_rounded,
                title: '個人開発',
                body: '人とのつながりが広がる。',
                color: colors.tertiaryContainer,
                onColor: colors.onTertiaryContainer,
                heightFactor: 0.78,
                leafCount: 2,
              ),
              OsoGrowthStage(
                number: '03',
                step: 3,
                icon: Icons.local_fire_department_rounded,
                title: 'FlutterKaigi',
                body: 'コミュニティの熱を感じる。',
                color: colors.primaryContainer,
                onColor: colors.onPrimaryContainer,
                heightFactor: 0.89,
                leafCount: 3,
              ),
              OsoGrowthStage(
                number: '04',
                step: 4,
                icon: Icons.groups_rounded,
                title: '広げる側へ',
                body: '岡山.Flutter / FlutterKaigi',
                color: colors.primary,
                onColor: colors.onPrimary,
                heightFactor: 1,
                leafCount: 5,
              ),
            ],
          );
        },
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
      child: const OsoTakeawayBody(),
    );
  }

  /// The closing slide deliberately carries nothing but the line itself, at the
  /// same weight as the book's ending, so the talk lands where it started.
  FlutterDeckSlide _buildFinalThanksSlide() {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: '/closing/thanks',
        title: 'ご清聴ありがとうございました',
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: SpeakerNotes.finalThanks,
        transition: _materialTransition,
      ),
      builder: (context) => const OsoFinalThanksSlide(),
    );
  }

  FlutterDeckSlide _buildMaterialSlide({
    required String route,
    required String title,
    required String eyebrow,
    required Widget child,
    String? subtitle,
    String? speakerNotes,
    int steps = 1,
  }) {
    return FlutterDeckSlide.blank(
      configuration: FlutterDeckSlideConfiguration(
        route: route,
        title: title,
        steps: steps,
        header: _noHeader,
        footer: _noFooter,
        speakerNotes: speakerNotes ?? '',
        transition: _materialTransition,
      ),
      builder: (context) => OsoMaterialSlide(
        eyebrow: eyebrow,
        title: title,
        subtitle: subtitle,
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

/// The fake ending: the talk pretends to be over so that the real second half
/// lands as a surprise. Mirrors [OsoFinalThanksSlide] on purpose.
class _AfterStoryThanksSlide extends StatelessWidget {
  const _AfterStoryThanksSlide();

  @override
  Widget build(BuildContext context) {
    return OsoCanvas(
      backgroundColor: osoSeedColor,
      theme: osoEndingTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return ColoredBox(
            color: osoSeedColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ご清聴ありがとうございました',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: osoAccentColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  FlutterDeckSlideStepsBuilder(
                    builder: (context, stepNumber) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        child: stepNumber < 2
                            ? const SizedBox(
                                key: ValueKey('after-story-thanks-placeholder'),
                                height: 82,
                              )
                            : Text(
                                'とはいかず……',
                                key: const ValueKey(
                                  'after-story-thanks-not-yet',
                                ),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
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
        },
      ),
    );
  }
}
