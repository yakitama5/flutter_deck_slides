import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'pages.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const OpeningApp());

class OpeningApp extends StatelessWidget {
  const OpeningApp({super.key});

  @override
  Widget build(BuildContext context) => FlutterDeckApp(
    client: FlutterDeckWebClient(),
    themeMode: ThemeMode.light,
    lightTheme: FlutterDeckThemeData.fromTheme(openingTheme),
    configuration: const FlutterDeckConfiguration(
      showProgress: false,
      transition: FlutterDeckTransition.fade(),
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      controls: FlutterDeckControlsConfiguration(presenterToolbarVisible: true),
    ),
    slides: [
      for (final page in openingPages)
        FlutterDeckSlide.custom(
          configuration: FlutterDeckSlideConfiguration(
            route: page.route,
            title: page.title,
            speakerNotes:
                '${page.seconds}秒\n\n${page.notes}\n\n出典\n${page.sources.join('\n')}',
          ),
          builder: (_) => OpeningSlide(key: ValueKey(page.route), page: page),
        ),
    ],
  );
}
