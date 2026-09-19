import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'backdrop.dart';
import 'theme.dart';

// Decoded from the survey QR image supplied by the event organizer.
const surveyUrl =
    'https://docs.google.com/forms/d/e/'
    '1FAIpQLSeWm5oxZdUvKWsszeu-KE_zff9TVDovJK7wd876L0MZ3hHvvA/'
    'viewform?pli=1';

void main() => runApp(const FlutterKaigiMiniEdApp());

class FlutterKaigiMiniEdApp extends StatelessWidget {
  const FlutterKaigiMiniEdApp({super.key});

  @override
  Widget build(BuildContext context) => FlutterDeckApp(
    client: FlutterDeckWebClient(),
    themeMode: ThemeMode.dark,
    lightTheme: FlutterDeckThemeData(theme: const MaterialTheme().light()),
    darkTheme: FlutterDeckThemeData(theme: const MaterialTheme().dark()),
    configuration: const FlutterDeckConfiguration(
      showProgress: false,
      slideSize: FlutterDeckSlideSize.custom(width: 1920, height: 1080),
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      controls: FlutterDeckControlsConfiguration(
        presenterToolbarVisible: false,
      ),
    ),
    slides: [
      FlutterDeckSlide.custom(
        configuration: const FlutterDeckSlideConfiguration(
          route: '/survey',
          title: 'アンケート / FlutterKaigi mini #6 @Okayama',
          speakerNotes: 'アンケートへのご協力をお願いします。\n$surveyUrl',
        ),
        builder: (context) => const SurveySlide(),
      ),
    ],
  );
}

class SurveySlide extends StatelessWidget {
  const SurveySlide({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const EventBackdrop(emphasized: true),
      Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(120),
            child: Semantics(
              label: 'アンケート回答用QRコード',
              image: true,
              child: QrImageView(
                data: surveyUrl,
                size: 840,
                // Keep at least four white modules around every side.
                padding: const EdgeInsets.all(80),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
