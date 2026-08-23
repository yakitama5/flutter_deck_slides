import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

final _pageTurnTransition = FlutterDeckTransition.custom(
  transitionBuilder: StorybookPageTurnTransitionBuilder(usePerspective: true),
);

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

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
            child: Row(
              children: [
                Expanded(child: Icon(Icons.flutter_dash, size: 220)),
                SizedBox(width: 56),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ある日、青い小鳥は\n新しい物語を届ける旅に出ました。',
                    style: TextStyle(
                      fontSize: 48,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
