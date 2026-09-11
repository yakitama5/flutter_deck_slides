import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'cover_emblem.dart';
import 'pages.dart';
import 'speaker_notes.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const ForestFestivalApp());

class ForestFestivalApp extends StatefulWidget {
  const ForestFestivalApp({super.key});

  @override
  State<ForestFestivalApp> createState() => _ForestFestivalAppState();
}

class _ForestFestivalAppState extends State<ForestFestivalApp> {
  late final StorybookSoundEffects _sounds;
  late final FlutterDeckTransition _bookTransition;
  late final FlutterDeckTransition _talkTransition;

  @override
  void initState() {
    super.initState();
    _sounds = StorybookSoundEffects();
    final builder = StorybookPageTurnTransitionBuilder(
      usePerspective: true,
      enableInkReveal: true,
      enableBookOpening: true,
      enableBookClosing: true,
      openingTargetSlideNumber: 2,
      closingTargetSlideNumber: festivalPages.length + 2,
      bookPageStartSlideNumber: 2,
      bookPageEndSlideNumber: festivalPages.length + 1,
      useMaterialTransitionForOrdinarySlides: true,
      bookPageCount: festivalPages.length,
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

  FlutterDeckSlide _slide({
    required String route,
    required String title,
    required String notes,
    required Widget child,
    bool book = true,
    Set<String> images = const {},
  }) => FlutterDeckSlide.blank(
    configuration: FlutterDeckSlideConfiguration(
      route: route,
      title: title,
      speakerNotes: notes,
      preloadImages: images,
      transition: book ? _bookTransition : _talkTransition,
    ),
    builder: (_) => child,
  );

  @override
  Widget build(BuildContext context) => FlutterDeckApp(
    client: FlutterDeckWebClient(),
    themeMode: ThemeMode.light,
    lightTheme: FlutterDeckThemeData.fromTheme(osoTheme),
    configuration: const FlutterDeckConfiguration(
      slideSize: FlutterDeckSlideSize.custom(width: 1920, height: 1080),
      showProgress: false,
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      controls: FlutterDeckControlsConfiguration(presenterToolbarVisible: true),
    ),
    slides: [
      _slide(
        route: '/front-cover',
        title: festivalTitle,
        notes: FestivalNotes.frontCover,
        child: const StorybookBookCover(
          coverColor: osoSeedColor,
          accentColor: osoAccentColor,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 72, vertical: 48),
            child: StorybookCoverEmblem(accentColor: osoAccentColor),
          ),
        ),
      ),
      for (final page in festivalPages)
        _slide(
          route: '/story/${page.slug}',
          title: page.title.replaceAll('\n', ' '),
          notes: page.notes,
          images: {page.asset},
          child: StorybookPage(
            key: ValueKey(page.slug),
            paperColor: const Color(0xFFFFFDF5),
            designSize: const Size(1920, 1080),
            outerPadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            borderRadius: 0,
            showPageNumber: false,
            circularSketchReveal: StorybookCircularSketchReveal(
              origin: page.revealOrigin,
              artworkAspectRatio: 1672 / 941,
            ),
            child: StoryArtwork(page: page),
          ),
        ),
      _slide(
        route: '/back-cover',
        title: 'つづきは、わたしたちの もりで。',
        notes: FestivalNotes.backCover,
        child: const StorybookBookCover(
          backCover: true,
          coverColor: osoSeedColor,
          accentColor: osoAccentColor,
        ),
      ),
      _slide(
        route: '/event',
        title: 'FlutterKaigi mini 岡山',
        notes: FestivalNotes.event,
        book: false,
        images: {EventPage.bannerAsset},
        child: const EventPage(),
      ),
      _slide(
        route: '/invitation',
        title: 'このお話を、ハッピーエンドに。',
        notes: FestivalNotes.invitation,
        book: false,
        child: const InvitationPage(),
      ),
    ],
  );
}
