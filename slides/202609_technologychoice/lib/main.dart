import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'cover_emblem.dart';
import 'pages.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const TechnologyChoiceApp());

class TechnologyChoiceApp extends StatefulWidget {
  const TechnologyChoiceApp({super.key});
  @override
  State<TechnologyChoiceApp> createState() => _TechnologyChoiceAppState();
}

class _TechnologyChoiceAppState extends State<TechnologyChoiceApp> {
  late final StorybookSoundEffects _sounds;
  late final FlutterDeckTransition _bookTransition;
  late final FlutterDeckTransition _talkTransition;

  @override
  void initState() {
    super.initState();
    _sounds = StorybookSoundEffects();
    final first = choicePages.indexWhere((p) => p.kind == PageKind.story) + 1;
    final back =
        choicePages.indexWhere((p) => p.kind == PageKind.backCover) + 1;
    final builder = StorybookPageTurnTransitionBuilder(
      usePerspective: true,
      enableInkReveal: true,
      enableBookOpening: true,
      enableBookClosing: true,
      openingTargetSlideNumber: first,
      closingTargetSlideNumber: back,
      bookPageStartSlideNumber: first,
      bookPageEndSlideNumber: back - 1,
      useMaterialTransitionForOrdinarySlides: true,
      // Decorative sheets in the opening animation (the shared renderer
      // supports at most eight), independent of the ten story scenes.
      bookPageCount: 8,
      soundEffects: _sounds,
    );
    _bookTransition = FlutterDeckTransition.custom(
      duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
      reverseDuration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
      transitionBuilder: builder,
    );
    _talkTransition = FlutterDeckTransition.custom(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 300),
      transitionBuilder: builder,
    );
  }

  @override
  void dispose() {
    unawaited(_sounds.dispose());
    super.dispose();
  }

  Widget _content(ChoicePage page) => switch (page.kind) {
    PageKind.frontCover => const StorybookBookCover(
      coverColor: osoSeedColor,
      accentColor: osoAccentColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 72, vertical: 48),
        child: StorybookCoverEmblem(accentColor: osoAccentColor),
      ),
    ),
    PageKind.backCover => const StorybookBookCover(
      backCover: true,
      coverColor: osoSeedColor,
      accentColor: osoAccentColor,
    ),
    PageKind.story => StorybookPage(
      paperColor: const Color(0xFFFFFDF5),
      coverColor: const Color(0xFF75523E),
      accentColor: const Color(0xFFB97840),
      designSize: osoCanvasSize,
      outerPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      borderRadius: 0,
      showPageNumber: false,
      circularSketchReveal: StorybookCircularSketchReveal(
        origin: page.revealOrigin,
        artworkAspectRatio: 1672 / 941,
      ),
      child: Image.asset(
        page.asset!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: page.title,
      ),
    ),
    _ => ChoiceTalkPage(page: page),
  };

  @override
  Widget build(BuildContext context) => FlutterDeckApp(
    client: FlutterDeckWebClient(),
    themeMode: ThemeMode.light,
    lightTheme: FlutterDeckThemeData.fromTheme(osoTheme),
    // Each page owns its fixed canvas, preserving the OSO paper-coloured
    // gutters on windows that are not 16:9.
    configuration: const FlutterDeckConfiguration(
      showProgress: false,
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      controls: FlutterDeckControlsConfiguration(presenterToolbarVisible: true),
    ),
    slides: [
      for (final page in choicePages)
        FlutterDeckSlide.blank(
          configuration: FlutterDeckSlideConfiguration(
            route: page.route,
            title: page.title,
            speakerNotes: timedNotes(page),
            preloadImages: {if (page.asset != null) page.asset!},
            transition: page.isBook ? _bookTransition : _talkTransition,
          ),
          builder: (_) =>
              KeyedSubtree(key: ValueKey(page.route), child: _content(page)),
        ),
    ],
  );
}
