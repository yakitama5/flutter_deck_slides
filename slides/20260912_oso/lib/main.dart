import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

const _noHeader = FlutterDeckHeaderConfiguration(showHeader: false);
const _noFooter = FlutterDeckFooterConfiguration(showFooter: false);
const _artworkAspectRatio = 1672 / 941;

const osoPages = <OsoPageData>[
  OsoPageData(
    number: 1,
    slug: 'first-acorn',
    title: '一粒のどんぐり',
    assetPath: 'assets/risukun_hitotsu_no_donguri/01_page01.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.18, 0.28),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 2,
    slug: 'planting',
    title: 'どんぐりを植える',
    assetPath: 'assets/risukun_hitotsu_no_donguri/02_page02.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.36, 0.08),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 3,
    slug: 'daily-care',
    title: '毎日のお世話',
    assetPath: 'assets/risukun_hitotsu_no_donguri/03_page03.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.05, 0.18),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 4,
    slug: 'young-tree',
    title: '小さな木と友達',
    assetPath: 'assets/risukun_hitotsu_no_donguri/04_page04.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.12, 0.18),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 5,
    slug: 'big-forest',
    title: '大きな森との出会い',
    assetPath: 'assets/risukun_hitotsu_no_donguri/05_page05.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.52, 0.50),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 6,
    slug: 'new-idea',
    title: 'ひらめき',
    assetPath: 'assets/risukun_hitotsu_no_donguri/06_page06.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.46, 0.35),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 7,
    slug: 'invite-friends',
    title: '友達を誘う',
    assetPath: 'assets/risukun_hitotsu_no_donguri/07_page07.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(-0.20, 0.06),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 8,
    slug: 'shared-place',
    title: 'みんなの場所',
    assetPath: 'assets/risukun_hitotsu_no_donguri/08_page08.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.02, 0.02),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 9,
    slug: 'pass-the-acorn',
    title: 'どんぐりを渡す',
    assetPath: 'assets/risukun_hitotsu_no_donguri/09_page09.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.15, 0.04),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 10,
    slug: 'next-place',
    title: '次の場所へ',
    assetPath: 'assets/risukun_hitotsu_no_donguri/10_page10.png',
    circularSketchReveal: StorybookCircularSketchReveal(
      origin: Alignment(0.15, 0.18),
      artworkAspectRatio: _artworkAspectRatio,
    ),
  ),
  OsoPageData(
    number: 11,
    slug: 'future-forest',
    title: '育った森',
    assetPath: 'assets/risukun_hitotsu_no_donguri/11_page11.png',
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
  late final FlutterDeckTransition _pageTurnTransition;

  @override
  void initState() {
    super.initState();
    _soundEffects = StorybookSoundEffects();
    _pageTurnTransition = FlutterDeckTransition.custom(
      duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
      transitionBuilder: StorybookPageTurnTransitionBuilder(
        usePerspective: true,
        enableInkReveal: true,
        enableBookOpening: true,
        enableBookClosing: true,
        bookPageCount: 8,
        soundEffects: _soundEffects,
      ),
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
        transition: _pageTurnTransition,
      ),
      slides: [
        _buildFrontCoverSlide(),
        for (final page in osoPages) _buildImageSlide(page),
        _buildBackCoverSlide(),
      ],
    );
  }
}

FlutterDeckSlide _buildFrontCoverSlide() {
  return FlutterDeckSlide.blank(
    configuration: const FlutterDeckSlideConfiguration(
      route: '/front-cover',
      initial: true,
      title: '前カバー',
      header: _noHeader,
      footer: _noFooter,
    ),
    builder: (context) => const StorybookBookCover(
      coverColor: Color(0xFF31533E),
      accentColor: Color(0xFFE7C978),
      child: SizedBox(
        width: 1000,
        height: 563,
        child: Image(
          image: AssetImage('assets/risukun_hitotsu_no_donguri/00_cover.png'),
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

FlutterDeckSlide _buildImageSlide(OsoPageData page) {
  return FlutterDeckSlide.blank(
    configuration: FlutterDeckSlideConfiguration(
      route: '/${page.number.toString().padLeft(2, '0')}-${page.slug}',
      title: page.title,
      header: _noHeader,
      footer: _noFooter,
      preloadImages: {page.assetPath},
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
    configuration: const FlutterDeckSlideConfiguration(
      route: '/back-cover',
      title: '後ろカバー',
      header: _noHeader,
      footer: _noFooter,
    ),
    builder: (context) => const StorybookBookCover(
      backCover: true,
      coverColor: Color(0xFF31533E),
      accentColor: Color(0xFFE7C978),
    ),
  );
}

class OsoPageData {
  const OsoPageData({
    required this.number,
    required this.slug,
    required this.title,
    required this.assetPath,
    required this.circularSketchReveal,
  });

  final int number;
  final String slug;
  final String title;
  final String assetPath;
  final StorybookCircularSketchReveal circularSketchReveal;
}
