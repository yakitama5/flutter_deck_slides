import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_storybook/src/storybook_book_cover_transition.dart';
import 'package:flutter_deck_storybook/src/storybook_page_curl.dart';
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

  testWidgets('book covers render without page content or page numbers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            StorybookBookCover(key: ValueKey('front'), title: '本の表紙'),
            StorybookBookCover(key: ValueKey('back'), backCover: true),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('front')), findsOneWidget);
    expect(find.byKey(const ValueKey('back')), findsOneWidget);
    expect(find.text('本の表紙'), findsOneWidget);
    expect(find.textContaining(' / '), findsNothing);
  });

  test('rigid covers use mirrored hinges, rotation, and camera moves', () {
    StorybookBookCoverMotionValues values(
      StorybookBookCoverMotion motion,
      double progress,
      bool backCover,
    ) => StorybookBookCoverMotionValues.forCover(
      motion: motion,
      progress: progress,
      backCover: backCover,
    );

    final frontOpeningStart = values(
      StorybookBookCoverMotion.opening,
      0,
      false,
    );
    final frontOpeningEnd = values(StorybookBookCoverMotion.opening, 1, false);
    final backOpeningStart = values(StorybookBookCoverMotion.opening, 0, true);
    final backOpeningEnd = values(StorybookBookCoverMotion.opening, 1, true);
    final backClosingStart = values(StorybookBookCoverMotion.closing, 0, true);
    final backClosingEnd = values(StorybookBookCoverMotion.closing, 1, true);

    expect(frontOpeningStart.hingeAlignment, Alignment.centerLeft);
    expect(backOpeningStart.hingeAlignment, Alignment.centerRight);
    expect(frontOpeningEnd.rotationY, closeTo(math.pi, 0.0001));
    expect(backOpeningEnd.rotationY, closeTo(-math.pi, 0.0001));
    expect(frontOpeningEnd.rotationY, greaterThan(0));
    expect(backOpeningEnd.rotationY, lessThan(0));
    expect(
      frontOpeningStart.cameraScale,
      lessThan(frontOpeningEnd.cameraScale),
    );
    expect(
      frontOpeningStart.cameraOffset.dy,
      greaterThan(frontOpeningEnd.cameraOffset.dy),
    );
    expect(
      backClosingStart.cameraScale,
      greaterThan(backClosingEnd.cameraScale),
    );
    expect(
      backClosingStart.cameraOffset.dy,
      lessThan(backClosingEnd.cameraOffset.dy),
    );
    expect(backClosingStart.rotationY, closeTo(-math.pi, 0.0001));
    expect(backClosingEnd.rotationY, closeTo(0, 0.0001));
    expect(frontOpeningStart.sceneWidthFactor, closeTo(0.93, 0.0001));
    expect(frontOpeningEnd.sceneWidthFactor, closeTo(1, 0.0001));
    expect(frontOpeningStart.sceneHeightFactor, closeTo(0.88, 0.0001));
    expect(frontOpeningEnd.sceneHeightFactor, closeTo(1, 0.0001));

    final middle = values(StorybookBookCoverMotion.opening, 0.5, false);
    expect(middle.rotationY, greaterThan(frontOpeningStart.rotationY));
    expect(middle.rotationY, lessThan(frontOpeningEnd.rotationY));
    expect(middle.cameraScale, greaterThan(frontOpeningStart.cameraScale));
    expect(middle.cameraScale, lessThan(frontOpeningEnd.cameraScale));
  });

  testWidgets('a cover is a rigid panel without an opacity transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StorybookBookCover(title: '表紙')),
    );

    expect(
      find.byKey(const ValueKey('storybook-book-rigid-cover-panel')),
      findsOneWidget,
    );
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('a turned cover exposes its inner board at the hinge turn', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StorybookBookCoverTransitionScope(
          motion: StorybookBookCoverMotion.opening,
          progress: 0.75,
          child: StorybookBookCover(title: '表紙'),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('storybook-book-rigid-cover-inner-panel')),
      findsOneWidget,
    );
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('a closing rigid cover keeps the tabletop behind the board', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StorybookBookCoverTransitionScope(
          motion: StorybookBookCoverMotion.closing,
          progress: 0.35,
          child: StorybookBookCover(backCover: true),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('storybook-book-closing-cover-tabletop')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('storybook-book-rigid-cover-panel')),
      findsOneWidget,
    );
    expect(find.byType(Opacity), findsNothing);
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
    expect(reveal.circularSketchReveal, isNull);

    final renderReveal = tester.renderObject<RenderStorybookInkReveal>(
      find.byKey(const ValueKey('storybook-ink-reveal')),
    );
    expect(renderReveal.effectivePaintProgress, 0.2);
  });

  test('circular sketch reveal expands from the fitted artwork origin', () {
    const configuration = StorybookCircularSketchReveal(
      origin: Alignment(-0.5, 0.5),
      artworkAspectRatio: 1408 / 752,
    );
    const bounds = Rect.fromLTWH(0, 0, 1600, 900);

    StorybookCircularSketchGeometry geometryAt(double progress) {
      return resolveStorybookCircularSketchGeometry(
        bounds: bounds,
        contentPadding: EdgeInsets.zero,
        designSize: const Size(1600, 900),
        configuration: configuration,
        progress: progress,
      );
    }

    final initial = geometryAt(0);
    final middle = geometryAt(0.5);
    final complete = geometryAt(1);

    expect(initial.artworkRect.left, 0);
    expect(initial.artworkRect.right, 1600);
    expect(initial.artworkRect.top, greaterThan(0));
    expect(initial.artworkRect.bottom, lessThan(900));
    expect(initial.origin.dx, closeTo(400, 0.001));
    expect(
      initial.origin.dy,
      closeTo(
        initial.artworkRect.top + initial.artworkRect.height * 0.75,
        0.001,
      ),
    );
    expect(initial.opacityAt(initial.origin), 1);
    expect(initial.opacityAt(bounds.bottomRight), 0);
    expect(middle.radius, greaterThan(initial.radius));
    expect(middle.opacityAt(const Offset(800, 650)), greaterThan(0));
    expect(complete.radius, greaterThan(middle.radius));
    expect(complete.opacityAt(bounds.topLeft), 1);
    expect(complete.opacityAt(bounds.bottomRight), 1);
  });

  test('different normalized origins stay inside 16:9 fitted artwork', () {
    const bounds = Rect.fromLTWH(0, 0, 1600, 900);

    StorybookCircularSketchGeometry geometryFor(Alignment origin) {
      return resolveStorybookCircularSketchGeometry(
        bounds: bounds,
        contentPadding: EdgeInsets.zero,
        designSize: const Size(1600, 900),
        configuration: StorybookCircularSketchReveal(
          origin: origin,
          artworkAspectRatio: 4 / 3,
        ),
        progress: 0,
      );
    }

    final topLeft = geometryFor(Alignment.topLeft);
    final bottomRight = geometryFor(Alignment.bottomRight);

    expect(topLeft.artworkRect, const Rect.fromLTWH(200, 0, 1200, 900));
    expect(topLeft.origin, topLeft.artworkRect.topLeft);
    expect(bottomRight.origin, bottomRight.artworkRect.bottomRight);
  });

  testWidgets('circular reveal keeps color hidden until sketch completes', (
    tester,
  ) async {
    const circularReveal = StorybookCircularSketchReveal(
      origin: Alignment.center,
      artworkAspectRatio: 16 / 9,
    );

    Future<RenderStorybookInkReveal> pumpReveal({
      required double sketchProgress,
      required double paintProgress,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StorybookRevealScope(
            sketchProgress: sketchProgress,
            paintProgress: paintProgress,
            revealOrigin: Alignment.center,
            child: const StorybookPage(
              circularSketchReveal: circularReveal,
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      );

      return tester.renderObject<RenderStorybookInkReveal>(
        find.byKey(const ValueKey('storybook-ink-reveal')),
      );
    }

    final developing = await pumpReveal(
      sketchProgress: 0.8,
      paintProgress: 0.9,
    );
    expect(developing.circularSketchReveal, circularReveal);
    expect(developing.effectivePaintProgress, 0);

    final sketched = await pumpReveal(sketchProgress: 1, paintProgress: 0.3);
    expect(sketched.effectivePaintProgress, 0.3);
  });

  testWidgets('page-turn transition deforms one full slide as a paper mesh', (
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

    final sheet = tester.widget<StorybookCurlSheet>(
      find.byKey(const ValueKey('storybook-page-turn-outgoing-sheet')),
    );

    expect(transitionBuilder.usePerspective, isTrue);
    expect(find.byKey(const Key('page')), findsOneWidget);
    expect(find.byType(SnapshotWidget), findsOneWidget);
    expect(find.byType(Transform), findsNothing);
    expect(sheet.direction, StorybookPageCurlDirection.forward);
    expect(sheet.motion, StorybookPageCurlMotion.turnAway);
    expect(sheet.progress, closeTo(0.145, 0.01));
    expect(sheet.maxRotation, greaterThan(math.pi / 2));
    expect(sheet.columns, 40);
    expect(sheet.rows, 16);
    expect(sheet.flex, greaterThan(0));
    expect(sheet.twist, greaterThan(0));
    expect(tester.takeException(), isNull);

    secondaryAnimation.stop();
  });

  testWidgets('incoming blank page is uncovered without a crossfade', (
    tester,
  ) async {
    final animation = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
      value: 0.7,
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

    final clip = tester.renderObject<RenderClipPath>(
      find.byKey(const ValueKey('storybook-page-turn-incoming-reveal')),
    );
    final revealed = clip.clipper!.getClip(clip.size);

    expect(
      revealed.contains(Offset(clip.size.width * 0.9, clip.size.height / 2)),
      isTrue,
    );
    expect(
      revealed.contains(Offset(clip.size.width * 0.1, clip.size.height / 2)),
      isFalse,
    );
    expect(revealed.contains(Offset(clip.size.width * 0.5, 2)), isTrue);

    animation.stop();
  });

  testWidgets('horizontal hand ridge starts at the free-edge midpoint', (
    tester,
  ) async {
    const clipKey = ValueKey('twist-clip');
    final transition = StorybookPageTurnTransitionBuilder();

    Future<(double, double, double)> revealThresholds(double progress) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StorybookCurlReveal(
            clipKey: clipKey,
            progress: progress,
            direction: StorybookPageCurlDirection.forward,
            motion: StorybookPageCurlMotion.turnAway,
            perspective: transition.perspective,
            maxRotation: transition.maxRotation,
            flex: transition.pageFlex,
            twist: transition.pageTwist,
            columns: transition.meshColumns,
            rows: transition.meshRows,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      );

      final clip = tester.renderObject<RenderClipPath>(find.byKey(clipKey));
      final path = clip.clipper!.getClip(clip.size);

      double firstRevealedX(double y) {
        for (var x = 0.0; x <= clip.size.width; x += 1) {
          if (path.contains(Offset(x, y))) return x;
        }
        return clip.size.width;
      }

      return (
        firstRevealedX(clip.size.height * 0.10),
        firstRevealedX(clip.size.height * 0.50),
        firstRevealedX(clip.size.height * 0.90),
      );
    }

    final early = await revealThresholds(0.23);
    final late = await revealThresholds(0.62);

    expect(early.$2, lessThan(early.$1 - 4));
    expect(early.$2, lessThan(early.$3 - 4));
    expect(late.$1, lessThan(early.$1));
    expect(late.$3, lessThan(early.$3));
  });

  test('the turned sheet exposes its unprinted paper back', () {
    final transition = StorybookPageTurnTransitionBuilder();
    StorybookCurlSheet sheetAt(double progress) => StorybookCurlSheet(
      progress: progress,
      direction: StorybookPageCurlDirection.forward,
      motion: StorybookPageCurlMotion.turnAway,
      perspective: transition.perspective,
      maxRotation: transition.maxRotation,
      flex: transition.pageFlex,
      twist: transition.pageTwist,
      columns: transition.meshColumns,
      rows: transition.meshRows,
      child: const SizedBox(),
    );

    expect(sheetAt(0.24).debugHasBackFacingSurface, isFalse);
    expect(sheetAt(0.50).debugHasBackFacingSurface, isTrue);
  });

  test('custom flutter_deck transition can match the reference turn', () {
    final transition = FlutterDeckTransition.custom(
      duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
      transitionBuilder: StorybookPageTurnTransitionBuilder(),
    );

    expect(
      transition.duration,
      StorybookPageTurnTransitionBuilder.referenceTurnDuration,
    );
    expect(
      transition.reverseDuration ?? transition.duration,
      StorybookPageTurnTransitionBuilder.referenceTurnDuration,
    );
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
      duration: StorybookPageTurnTransitionBuilder.referenceTurnDuration,
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
    expect(sounds.pageTurnCalls, 0);
    expect(sounds.drawingCalls, 0);

    animation.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(sounds.pageTurnCalls, 0);

    await tester.pump(const Duration(milliseconds: 30));

    expect(sounds.pageTurnCalls, 1);

    await tester.pump(const Duration(milliseconds: 970));
    await tester.pump(const Duration(milliseconds: 250));

    expect(sounds.drawingCalls, 0);

    await tester.pump(const Duration(milliseconds: 320));

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
