import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final StorybookSoundEffects _soundEffects;
  late final FlutterDeckTransition _pageTurnTransition;

  @override
  void initState() {
    super.initState();
    _soundEffects = StorybookSoundEffects();
    _pageTurnTransition = FlutterDeckTransition.custom(
      duration: const Duration(milliseconds: 1000),
      transitionBuilder: StorybookPageTurnTransitionBuilder(
        usePerspective: true,
        enableInkReveal: true,
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
        FlutterDeckSlide.blank(
          configuration: const FlutterDeckSlideConfiguration(
            route: '/cover',
            header: FlutterDeckHeaderConfiguration(showHeader: false),
            footer: FlutterDeckFooterConfiguration(showFooter: false),
          ),
          builder: (context) => const StorybookPage(
            pageNumber: 1,
            totalPages: 3,
            accentColor: Color(0xFF287A78),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 104),
                  SizedBox(height: 32),
                  Text(
                    'FlutterDeck Storybook',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 68,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '矢印キーで、物語のページをめくってみよう。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        FlutterDeckSlide.blank(
          configuration: const FlutterDeckSlideConfiguration(
            route: '/story',
            header: FlutterDeckHeaderConfiguration(showHeader: false),
            footer: FlutterDeckFooterConfiguration(showFooter: false),
          ),
          builder: (context) => const StorybookPage(
            pageNumber: 2,
            totalPages: 3,
            accentColor: Color(0xFFD07A4A),
            contentPadding: EdgeInsets.fromLTRB(48, 42, 48, 54),
            child: _StoryScene(),
          ),
        ),
        FlutterDeckSlide.blank(
          configuration: const FlutterDeckSlideConfiguration(
            route: '/ending',
            header: FlutterDeckHeaderConfiguration(showHeader: false),
            footer: FlutterDeckFooterConfiguration(showFooter: false),
          ),
          builder: (context) => const StorybookPage(
            pageNumber: 3,
            totalPages: 3,
            accentColor: Color(0xFF6D5BA6),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nightlight_round, size: 112),
                  SizedBox(height: 32),
                  Text(
                    'おしまい',
                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'この3ページを、あなたの物語に置き換えてください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryScene extends StatelessWidget {
  const _StoryScene();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFBFE9E2), Color(0xFF4383A8)],
              ),
            ),
          ),
          const Positioned(
            top: 58,
            right: 104,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFD46A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55FFE7A1),
                    blurRadius: 38,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: SizedBox.square(dimension: 132),
            ),
          ),
          Positioned(
            left: -120,
            right: 360,
            bottom: -210,
            height: 470,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF315C51),
                borderRadius: BorderRadius.circular(280),
              ),
            ),
          ),
          Positioned(
            left: 560,
            right: -180,
            bottom: -190,
            height: 430,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF5D8F65),
                borderRadius: BorderRadius.circular(260),
              ),
            ),
          ),
          const Positioned(
            left: 58,
            bottom: 148,
            child: Icon(
              Icons.park_rounded,
              color: Color(0xFF214E3D),
              size: 190,
            ),
          ),
          const Positioned(
            right: 50,
            bottom: 126,
            child: Icon(
              Icons.park_rounded,
              color: Color(0xFF2E6549),
              size: 210,
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.34),
            child: Icon(
              Icons.flutter_dash,
              color: Color(0xFFF7F0DD),
              size: 224,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Text(
              'ある日、青い小鳥は物語を届ける旅に出ました。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFDF8EA),
                fontSize: 36,
                height: 1.4,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Color(0x660E2B2D),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
