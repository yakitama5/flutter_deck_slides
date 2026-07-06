import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterDeckApp(
      client: FlutterDeckWebClient(),
      configuration: const FlutterDeckConfiguration(
        controls: FlutterDeckControlsConfiguration(
          presenterToolbarVisible: true,
        ),
      ),
      slides: [
        FlutterDeckSlide.title(
          title: 'example',
          configuration: const FlutterDeckSlideConfiguration(
            route: '/intro',
            header: FlutterDeckHeaderConfiguration(showHeader: false),
            footer: FlutterDeckFooterConfiguration(showFooter: false),
          ),
        ),
        FlutterDeckSlide.blank(
          configuration: const FlutterDeckSlideConfiguration(
            route: '/section-1',
          ),
          builder: (context) => const Center(child: Text('セクション 1')),
        ),
        FlutterDeckSlide.blank(
          configuration: const FlutterDeckSlideConfiguration(
            route: '/thank-you',
            header: FlutterDeckHeaderConfiguration(showHeader: false),
            footer: FlutterDeckFooterConfiguration(showFooter: false),
          ),
          builder: (context) => const Center(child: Text('Thank you!')),
        ),
      ],
    );
  }
}
