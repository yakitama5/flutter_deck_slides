import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'speaker_notes.dart';

const _noHeader = FlutterDeckHeaderConfiguration(showHeader: false);
const _noFooter = FlutterDeckFooterConfiguration(showFooter: false);

/// The ten image pages stay in this explicit numeric order.
const risukunPages = <RisukunPageData>[
  RisukunPageData(
    number: 1,
    slug: 'title',
    title: 'タイトル',
    assetPath: 'assets/risukun_super_tenkomori_car/01_title.png',
    speakerNotes: SpeakerNotes.page01,
  ),
  RisukunPageData(
    number: 2,
    slug: 'race-dream',
    title: 'レースの夢',
    assetPath: 'assets/risukun_super_tenkomori_car/02_race_dream.png',
    speakerNotes: SpeakerNotes.page02,
  ),
  RisukunPageData(
    number: 3,
    slug: 'building',
    title: '車をつくる',
    assetPath: 'assets/risukun_super_tenkomori_car/03_building.png',
    speakerNotes: SpeakerNotes.page03,
  ),
  RisukunPageData(
    number: 4,
    slug: 'super-tenkomori-car',
    title: 'てんこもりカー完成',
    assetPath: 'assets/risukun_super_tenkomori_car/04_super_tenkomori_car.png',
    speakerNotes: SpeakerNotes.page04,
  ),
  RisukunPageData(
    number: 5,
    slug: 'race-breakdown',
    title: 'レースで故障',
    assetPath: 'assets/risukun_super_tenkomori_car/05_race_breakdown.png',
    speakerNotes: SpeakerNotes.page05,
  ),
  RisukunPageData(
    number: 6,
    slug: 'owl-doctor',
    title: 'フクロウ博士',
    assetPath: 'assets/risukun_super_tenkomori_car/06_owl_doctor.png',
    speakerNotes: SpeakerNotes.page06,
  ),
  RisukunPageData(
    number: 7,
    slug: 'new-car',
    title: '新しい車',
    assetPath: 'assets/risukun_super_tenkomori_car/07_new_car.png',
    speakerNotes: SpeakerNotes.page07,
  ),
  RisukunPageData(
    number: 8,
    slug: 'goal',
    title: 'ゴール',
    assetPath: 'assets/risukun_super_tenkomori_car/08_goal.png',
    speakerNotes: SpeakerNotes.page08,
  ),
  RisukunPageData(
    number: 9,
    slug: 'yagni-comparison',
    title: 'YAGNIのくらべっこ',
    assetPath: 'assets/risukun_super_tenkomori_car/09_yagni_comparison.png',
    speakerNotes: SpeakerNotes.page09,
  ),
  RisukunPageData(
    number: 10,
    slug: 'ending',
    title: 'おしまいと解説',
    assetPath: 'assets/risukun_super_tenkomori_car/10_ending.png',
    speakerNotes: SpeakerNotes.page10,
  ),
];

void main() => runApp(const RisukunSuperTenkomoriCarApp());

class RisukunSuperTenkomoriCarApp extends StatefulWidget {
  const RisukunSuperTenkomoriCarApp({super.key});

  @override
  State<RisukunSuperTenkomoriCarApp> createState() =>
      _RisukunSuperTenkomoriCarAppState();
}

class _RisukunSuperTenkomoriCarAppState
    extends State<RisukunSuperTenkomoriCarApp> {
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
        // The shared boundary animation allows at most eight staggered sheets.
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
        for (final page in risukunPages) _buildImageSlide(page),
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
      speakerNotes: SpeakerNotes.frontCover,
    ),
    builder: (context) => const StorybookBookCover(
      title: 'リスくんの\nスーパーてんこもりカー',
      subtitle: '矢印キーで、本を開いてみよう。',
      coverColor: Color(0xFF31533E),
      accentColor: Color(0xFFE7C978),
    ),
  );
}

FlutterDeckSlide _buildImageSlide(RisukunPageData page) {
  return FlutterDeckSlide.blank(
    configuration: FlutterDeckSlideConfiguration(
      route: '/${page.number.toString().padLeft(2, '0')}-${page.slug}',
      title: page.title,
      header: _noHeader,
      footer: _noFooter,
      preloadImages: {page.assetPath},
      speakerNotes: page.speakerNotes,
    ),
    builder: (context) => StorybookPage(
      key: ValueKey('risukun-page-${page.number}'),
      pageNumber: page.number,
      totalPages: risukunPages.length,
      paperColor: const Color(0xFFFFFDF5),
      coverColor: const Color(0xFF75523E),
      accentColor: const Color(0xFFB97840),
      outerPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      borderRadius: 0,
      showPageNumber: false,
      child: Image.asset(
        page.assetPath,
        key: ValueKey('risukun-page-image-${page.number}'),
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

class RisukunPageData {
  const RisukunPageData({
    required this.number,
    required this.slug,
    required this.title,
    required this.assetPath,
    required this.speakerNotes,
  });

  final int number;
  final String slug;
  final String title;
  final String assetPath;
  final String speakerNotes;
}
