import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'pages.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const TechnologyReasonsApp());

class TechnologyReasonsApp extends StatelessWidget {
  const TechnologyReasonsApp({super.key});

  @override
  Widget build(BuildContext context) => FlutterDeckApp(
    client: FlutterDeckWebClient(),
    themeMode: ThemeMode.light,
    lightTheme: FlutterDeckThemeData.fromTheme(reasonTheme),
    configuration: const FlutterDeckConfiguration(
      showProgress: false,
      transition: FlutterDeckTransition.fade(),
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      controls: FlutterDeckControlsConfiguration(presenterToolbarVisible: true),
    ),
    slides: [
      for (final page in reasonPages)
        FlutterDeckSlide.blank(
          configuration: FlutterDeckSlideConfiguration(
            route: page.route,
            title: page.title.replaceAll('\n', ' '),
            speakerNotes:
                '${page.seconds}秒\n\n${page.notes}\n\n${page.sourceUrl}',
          ),
          builder: (_) => KeyedSubtree(
            key: ValueKey(page.route),
            child: ReasonSlide(page: page),
          ),
        ),
    ],
  );
}
