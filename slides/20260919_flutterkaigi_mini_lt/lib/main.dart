import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_web_client/flutter_deck_web_client.dart';

import 'mascot.dart';
import 'pages.dart';
import 'slides.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterKaigiMiniLtApp());
}

class FlutterKaigiMiniLtApp extends StatelessWidget {
  const FlutterKaigiMiniLtApp({this.enableRendering = true, super.key});

  final bool enableRendering;

  @override
  Widget build(BuildContext context) => FlutterDeckApp(
    client: FlutterDeckWebClient(),
    themeMode: ThemeMode.dark,
    lightTheme: FlutterDeckThemeData(theme: const MaterialTheme().light()),
    darkTheme: FlutterDeckThemeData(theme: const MaterialTheme().dark()),
    plugins: [_DashmaruPlugin(enableRendering: enableRendering)],
    configuration: const FlutterDeckConfiguration(
      showProgress: false,
      slideSize: FlutterDeckSlideSize.custom(width: 1920, height: 1080),
      transition: FlutterDeckTransition.fade(),
      header: FlutterDeckHeaderConfiguration(showHeader: false),
      footer: FlutterDeckFooterConfiguration(showFooter: false),
      controls: FlutterDeckControlsConfiguration(presenterToolbarVisible: true),
    ),
    slides: [
      for (var i = 0; i < ltPages.length; i++)
        FlutterDeckSlide.custom(
          configuration: FlutterDeckSlideConfiguration(
            route: ltPages[i].route,
            title: ltPages[i].title,
            speakerNotes: '${ltPages[i].seconds}秒\n\n${ltPages[i].notes}',
          ),
          builder: (context) => ListenableBuilder(
            listenable: context.flutterDeck.router,
            builder: (context, _) => LtSlide(
              key: ValueKey(ltPages[i].route),
              slideIndex: i,
              isActive: context.flutterDeck.router.currentSlideIndex == i,
            ),
          ),
        ),
    ],
  );
}

/// The actor lives outside route pages, so a slide change never reloads it.
class _DashmaruPlugin extends FlutterDeckPlugin {
  const _DashmaruPlugin({required this.enableRendering});
  final bool enableRendering;

  @override
  Widget wrap(BuildContext context, Widget child) => Builder(
    builder: (context) {
      final deck = context.flutterDeck;
      final shortcuts = deck.globalConfiguration.controls.shortcuts;
      // The retained actor is outside the slide Navigator. Give its controls
      // an Overlay for tooltips and the same keyboard shortcuts as the deck.
      return Overlay.wrap(
        child: CallbackShortcuts(
          bindings: {
            if (shortcuts.enabled) ...{
              for (final key in shortcuts.nextSlide)
                key: deck.controlsNotifier.next,
              for (final key in shortcuts.previousSlide)
                key: deck.controlsNotifier.previous,
              for (final key in shortcuts.toggleMarker)
                key: deck.controlsNotifier.toggleMarker,
              for (final key in shortcuts.toggleNavigationDrawer)
                key: deck.controlsNotifier.toggleDrawer,
            },
          },
          child: _PresentationStage(
            enableRendering: enableRendering,
            child: child,
          ),
        ),
      );
    },
  );
}

class _PresentationStage extends StatelessWidget {
  const _PresentationStage({
    required this.enableRendering,
    required this.child,
  });
  final bool enableRendering;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = context.flutterDeck.router;
    if (router.isPresenterView) return child;
    return ListenableBuilder(
      listenable: router,
      child: child,
      builder: (context, child) {
        final index = router.currentSlideIndex;
        final isDemo = index == 5;
        final isThanks = index == 16;
        final actorBounds = dashmaruActorBounds(index);
        final reducedMotion = MediaQuery.disableAnimationsOf(context);
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !isDemo,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: FittedBox(
                      child: SizedBox(
                        width: 1920,
                        height: 1080,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: reducedMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 650),
                              curve: Curves.easeInOutCubic,
                              left: actorBounds.left,
                              top: actorBounds.top,
                              width: actorBounds.width,
                              height: actorBounds.height,
                              child: Offstage(
                                offstage: index < 5,
                                child: Focus(
                                  key: const ValueKey('mascot-focus'),
                                  child: DashmaruActor(
                                    key: const ValueKey('retained-dashmaru'),
                                    slideIndex: index,
                                    large: isDemo || isThanks,
                                    enableRendering: enableRendering,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
