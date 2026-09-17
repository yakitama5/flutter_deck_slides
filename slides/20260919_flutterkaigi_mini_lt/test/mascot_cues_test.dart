import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterkaigi_mini_20260919/dashmaru_scene.dart';
import 'package:flutterkaigi_mini_lt_20260919/mascot.dart';

/// Tests the actual cue lifecycle without opening a GPU context or loading GLB.
class _FakeWorld extends DashmaruScene {
  _FakeWorld() {
    durations.addAll({for (final motion in DashmaruMotion.values) motion: 2.5});
  }

  DashmaruMotion selectedMotion = DashmaruMotion.idle;
  bool isPlaying = true;
  double advancedSeconds = 0;
  int advancedFrames = 0;
  final List<DashmaruMotion> selections = [];

  @override
  DashmaruMotion get motion => selectedMotion;

  @override
  bool get playing => isPlaying;

  @override
  void selectMotion(DashmaruMotion value, {bool animateTransition = true}) {
    selections.add(value);
    selectedMotion = value;
    isPlaying = true;
  }

  @override
  void selectExpression(DashmaruExpression value) => expression = value;

  @override
  void setPlaying(bool value) => isPlaying = value;

  @override
  void setSpeed(double value) {}

  @override
  void tick(Duration elapsed, double deltaSeconds) {
    if (!playing || deltaSeconds == 0) return;
    advancedFrames++;
    advancedSeconds += deltaSeconds;
  }
}

void _advance(DashmaruCueController cues, double seconds) {
  for (var i = 0; i < (seconds * 100).round(); i++) {
    cues.tick(Duration(milliseconds: i * 10), 0.01);
  }
}

void main() {
  testWidgets('the demo offers waving, running, shaking and jumping', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: DashmaruActor(
            slideIndex: 5,
            large: true,
            enableRendering: false,
          ),
        ),
      ),
    );

    for (final label in ['手を振る', '走る', 'ぶんぶん', 'ジャンプ']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('歩く'), findsNothing);
    expect(find.text('待機'), findsNothing);
  });

  for (final (slide, motion, expression) in [
    (6, DashmaruMotion.celebrate, DashmaruExpression.smile),
    (7, DashmaruMotion.shake, DashmaruExpression.strain),
    (8, DashmaruMotion.sit, DashmaruExpression.spiral),
  ]) {
    test('slide $slide keeps its motion and face across repeated loops', () {
      final world = _FakeWorld();
      final cues = DashmaruCueController()
        ..selectSlide(slide)
        ..attach(world);

      // Let many complete clip durations pass. The cue must not fall back to
      // idle, clear the face, or keep restarting the seated entrance.
      _advance(cues, 40);
      expect(world.motion, motion);
      expect(world.displayedExpression, expression);
      expect(world.playing, isTrue);
      expect(world.advancedSeconds, closeTo(40, 1e-9));
      expect(world.selections, [motion]);
    });
  }

  test('a late model load applies only the latest slide cue', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(7)
      ..selectSlide(12)
      ..selectSlide(16)
      ..attach(world);

    expect(world.selections, [DashmaruMotion.wave]);
    expect(world.expression, DashmaruExpression.smile);
    _advance(cues, 12);
    expect(world.motion, DashmaruMotion.wave);
    expect(world.expression, DashmaruExpression.smile);
  });

  test('navigation replaces persistent reactions and resets each face', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(7)
      ..attach(world);
    expect(world.motion, DashmaruMotion.shake);
    expect(world.expression, DashmaruExpression.strain);
    _advance(cues, 1);
    cues.selectSlide(8);
    expect(world.motion, DashmaruMotion.sit);
    expect(world.expression, DashmaruExpression.spiral);
    _advance(cues, 5);
    cues.selectSlide(9);
    expect(world.motion, DashmaruMotion.sit);
    expect(world.expression, DashmaruExpression.normal);
    cues.selectSlide(16);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.wave);
    expect(world.expression, DashmaruExpression.smile);
    // Backwards navigation restores the persistent question reaction.
    cues.selectSlide(7);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.shake);
    expect(world.expression, DashmaruExpression.strain);
    cues.selectSlide(6);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.celebrate);
    expect(world.expression, DashmaruExpression.smile);
  });

  test('the discussion retains one seated entrance and clears dizzy eyes', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(8)
      ..attach(world);
    expect(world.expression, DashmaruExpression.spiral);
    _advance(cues, 5);
    for (final slide in [9, 10, 11, 12]) {
      cues.selectSlide(slide);
      _advance(cues, 5);
      expect(world.expression, DashmaruExpression.normal);
    }
    cues.selectSlide(11);

    expect(world.motion, DashmaruMotion.sit);
    expect(world.selections, [DashmaruMotion.sit]);
  });

  test('after the architecture discussion the companion stands calmly', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(12)
      ..attach(world);
    _advance(cues, 4);
    cues.selectSlide(13);
    expect(world.motion, DashmaruMotion.idle);
    _advance(cues, 12);
    expect(world.motion, DashmaruMotion.idle);
    expect(world.expression, DashmaruExpression.normal);
    expect(world.selections, [DashmaruMotion.sit, DashmaruMotion.idle]);
  });

  test('leaving a one-shot cue cannot replace the next slide reaction', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(14)
      ..attach(world);
    _advance(cues, 0.5);
    cues.selectSlide(6);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.celebrate);
    expect(world.expression, DashmaruExpression.smile);
    expect(world.selections, [DashmaruMotion.wave, DashmaruMotion.celebrate]);

    cues.selectSlide(15);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.idle);
    expect(world.expression, DashmaruExpression.normal);
  });

  test('sharing waves once while the closing slide keeps waving', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(14)
      ..attach(world);
    _advance(cues, 2.5);
    expect(world.motion, DashmaruMotion.idle);
    cues.selectSlide(16);
    _advance(cues, 12);
    expect(world.motion, DashmaruMotion.wave);
    expect(world.expression, DashmaruExpression.smile);
  });

  test('jumping from a seated slide allows the full wave after standing', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(11)
      ..attach(world);
    _advance(cues, 5);
    cues.selectSlide(14);
    _advance(cues, 2.5);
    expect(world.motion, DashmaruMotion.wave);
    _advance(cues, 1.25);
    expect(world.motion, DashmaruMotion.idle);
  });

  test('reduced motion freezes cues but allows an explicit demo gesture', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(6, reducedMotion: true)
      ..attach(world);

    for (final (slide, expression) in [
      (6, DashmaruExpression.smile),
      (7, DashmaruExpression.strain),
      (8, DashmaruExpression.spiral),
    ]) {
      cues.selectSlide(slide, reducedMotion: true);
      _advance(cues, 10);
      expect(world.playing, isFalse);
      expect(world.motion, DashmaruMotion.idle);
      expect(world.expression, expression);
      expect(world.advancedFrames, 0);
    }

    cues.selectSlide(5, reducedMotion: true);
    expect(world.playing, isFalse);
    cues.selectDemoMotion(DashmaruMotion.jump);
    _advance(cues, 1);
    expect(world.motion, DashmaruMotion.jump);
    expect(world.playing, isTrue);
    expect(world.advancedFrames, 100);

    cues.selectSlide(6, reducedMotion: true);
    expect(world.playing, isFalse);
    expect(world.motion, DashmaruMotion.idle);
    expect(world.expression, DashmaruExpression.smile);
  });

  test('demo pause freezes the same animation clock and can resume', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(5)
      ..attach(world)
      ..selectDemoMotion(DashmaruMotion.run);
    _advance(cues, 1);
    cues.toggleDemoPlayback();
    _advance(cues, 3);
    expect(world.advancedSeconds, closeTo(1, 1e-9));
    cues.toggleDemoPlayback();
    _advance(cues, 1);
    expect(world.advancedSeconds, closeTo(2, 1e-9));
    expect(world.advancedFrames, 200);
  });

  test('hidden slides, disposed cues and late attachments never advance', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()..attach(world);
    _advance(cues, 10);
    expect(world.advancedFrames, 0);
    cues.selectSlide(7);
    cues.dispose();
    _advance(cues, 10);
    cues.selectSlide(16);
    expect(world.advancedFrames, 0);
    expect(world.playing, isFalse);
    final lateWorld = _FakeWorld();
    cues.attach(lateWorld);
    expect(lateWorld.selections, isEmpty);
  });

  test('each frame advances the model once and clamps a stalled frame', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(7)
      ..attach(world);
    cues.tick(const Duration(seconds: 12), 12);
    expect(world.advancedFrames, 1);
    expect(world.advancedSeconds, 0.05);
    expect(world.expression, DashmaruExpression.strain);
  });
}
