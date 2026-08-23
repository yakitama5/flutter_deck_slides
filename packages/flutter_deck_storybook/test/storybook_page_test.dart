import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_storybook/src/storybook_reveal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StorybookPage renders its content and page label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StorybookPage(
          pageNumber: 1,
          totalPages: 3,
          child: Center(child: Text('ものがたり')),
        ),
      ),
    );

    expect(find.text('ものがたり'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('StorybookPage applies reveal animation values to its artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StorybookRevealScope(
          sketchProgress: 0.4,
          paintProgress: 0.2,
          revealOrigin: Alignment(0, 0.25),
          child: StorybookPage(child: SizedBox()),
        ),
      ),
    );

    final reveal = tester.widget<StorybookInkReveal>(
      find.byKey(const ValueKey('storybook-ink-reveal')),
    );

    expect(reveal.sketchProgress, 0.4);
    expect(reveal.paintProgress, 0.2);
    expect(reveal.revealOrigin, const Alignment(0, 0.25));
  });

  testWidgets('page-turn transition rotates one full slide from its edge', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester, value: 1);
    final secondaryAnimation = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
      value: 0.5,
    )..forward();
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const ColoredBox(key: Key('page'), color: Colors.white),
          ),
        ),
      ),
    );

    final transform = tester.widget<Transform>(find.byType(Transform));

    expect(transitionBuilder.usePerspective, isTrue);
    expect(find.byKey(const Key('page')), findsOneWidget);
    expect(transform.alignment, Alignment.centerLeft);
    expect(
      transform.transform.storage.every((value) => value.isFinite),
      isTrue,
    );

    secondaryAnimation.stop();
  });

  testWidgets('incoming blank page is uncovered without a crossfade', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
      value: 0.5,
    )..forward();
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const StorybookPage(child: SizedBox()),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('storybook-page-turn-incoming-reveal')),
      findsOneWidget,
    );
    expect(find.byType(Opacity), findsNothing);

    final clip = tester.renderObject<RenderClipRect>(
      find.byKey(const ValueKey('storybook-page-turn-incoming-reveal')),
    );
    final revealedBounds = clip.clipper!.getClip(clip.size);

    expect(revealedBounds.left, greaterThan(0));
    expect(revealedBounds.left, lessThan(clip.size.width * 0.6));
    expect(revealedBounds.right, clip.size.width);

    animation.stop();
  });

  testWidgets('incoming page stays blank before sketch and ink develop', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const StorybookPage(child: SizedBox()),
          ),
        ),
      ),
    );

    StorybookRevealScope reveal() =>
        tester.widget<StorybookRevealScope>(find.byType(StorybookRevealScope));

    expect(reveal().sketchProgress, 0);
    expect(reveal().paintProgress, 0);

    animation.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    expect(reveal().sketchProgress, 0);
    expect(reveal().paintProgress, 0);

    await tester.pump(const Duration(milliseconds: 400));

    expect(reveal().sketchProgress, greaterThan(0));
    expect(reveal().paintProgress, 0);

    await tester.pump(const Duration(milliseconds: 650));

    expect(reveal().sketchProgress, greaterThan(0.9));
    expect(reveal().paintProgress, greaterThan(0));

    await tester.pump(const Duration(seconds: 2));

    expect(reveal().sketchProgress, 1);
    expect(reveal().paintProgress, 1);
  });

  testWidgets('sound cues stay synchronized with the turn and first lines', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    final secondaryAnimation = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    final sounds = _RecordingSoundEffects();
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
      soundEffects: sounds,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const StorybookPage(child: SizedBox()),
          ),
        ),
      ),
    );

    expect(sounds.preloadCalls, 1);
    expect(sounds.pageTurnCalls, 1);
    expect(sounds.drawingCalls, 0);

    animation.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    expect(sounds.drawingCalls, 0);

    await tester.pump(const Duration(milliseconds: 450));

    final reveal = tester.widget<StorybookRevealScope>(
      find.byType(StorybookRevealScope),
    );
    expect(reveal.sketchProgress, greaterThan(0));
    expect(sounds.drawingCalls, 1);

    secondaryAnimation.forward();
    await tester.pump();

    expect(sounds.stopDrawingCalls, 1);
    secondaryAnimation.stop();
  });

  testWidgets(
    'bundled storybook sound files are available to the asset cache',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      final pageTurn = await rootBundle.load('assets/audio/page-turn.mp3');
      final drawing = await rootBundle.load(
        'assets/audio/drawing-on-paper.mp3',
      );

      expect(pageTurn.lengthInBytes, greaterThan(8000));
      expect(drawing.lengthInBytes, greaterThan(30000));
    },
  );

  testWidgets('page-turn transition provides an optional planar fallback', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester, value: 0.5);
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final sounds = _RecordingSoundEffects();
    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
      usePerspective: false,
      soundEffects: sounds,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => transitionBuilder.build(
            context,
            animation,
            secondaryAnimation,
            const ColoredBox(key: Key('page'), color: Colors.white),
          ),
        ),
      ),
    );

    final planarTransition = find.byKey(
      const ValueKey('storybook-page-turn-planar'),
    );

    expect(planarTransition, findsOneWidget);
    expect(
      find.descendant(
        of: planarTransition,
        matching: find.byType(SlideTransition),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: planarTransition, matching: find.byType(Transform)),
      findsNothing,
    );
    expect(sounds.pageTurnCalls, 1);
  });

  testWidgets('page-turn transition falls back to a fade for reduced motion', (
    tester,
  ) async {
    final animation = AnimationController(vsync: tester, value: 1);
    final secondaryAnimation = AnimationController(vsync: tester);
    addTearDown(animation.dispose);
    addTearDown(secondaryAnimation.dispose);

    final sounds = _RecordingSoundEffects();
    final transitionBuilder = StorybookPageTurnTransitionBuilder(
      reverseOnPrevious: false,
      soundEffects: sounds,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => transitionBuilder.build(
              context,
              animation,
              secondaryAnimation,
              const SizedBox(),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('storybook-page-turn-fade')),
      findsOneWidget,
    );
    expect(find.byType(Transform), findsNothing);
    expect(sounds.preloadCalls, 0);
    expect(sounds.pageTurnCalls, 0);
    expect(sounds.drawingCalls, 0);
  });
}

class _RecordingSoundEffects implements StorybookSoundEffectPlayer {
  var preloadCalls = 0;
  var pageTurnCalls = 0;
  var drawingCalls = 0;
  var stopDrawingCalls = 0;

  @override
  Future<void> preload() async {
    preloadCalls++;
  }

  @override
  Future<void> playPageTurn() async {
    pageTurnCalls++;
  }

  @override
  Future<void> playDrawing() async {
    drawingCalls++;
  }

  @override
  Future<void> stopDrawing() async {
    stopDrawingCalls++;
  }
}
