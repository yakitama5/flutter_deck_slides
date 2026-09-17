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

  test('navigation cancels the previous question and gesture sequence', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(7)
      ..attach(world);
    expect(world.expression, DashmaruExpression.spiral);
    _advance(cues, 1);
    cues.selectSlide(16);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.wave);
    expect(world.expression, DashmaruExpression.smile);
    expect(world.selections, isNot(contains(DashmaruMotion.blink)));

    // Backwards navigation starts the question's sequence from the beginning.
    cues.selectSlide(7);
    expect(world.expression, DashmaruExpression.spiral);
    _advance(cues, 1.8);
    expect(world.motion, DashmaruMotion.blink);
    expect(world.expression, DashmaruExpression.normal);
    _advance(cues, 2.5);
    expect(world.motion, DashmaruMotion.idle);
  });

  test('the three design slides retain one seated animation entrance', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(10)
      ..attach(world);
    _advance(cues, 5);
    cues.selectSlide(11);
    _advance(cues, 5);
    cues.selectSlide(12);
    _advance(cues, 5);
    cues.selectSlide(11);

    expect(world.motion, DashmaruMotion.sit);
    expect(world.selections, [DashmaruMotion.sit]);
  });

  test('the learning slide stands, jumps once, then smiles at idle', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(12)
      ..attach(world);
    _advance(cues, 4);
    cues.selectSlide(13);
    expect(world.motion, DashmaruMotion.idle);
    _advance(cues, 1.24);
    expect(world.motion, DashmaruMotion.idle);
    _advance(cues, 0.01);
    expect(world.motion, DashmaruMotion.jump);
    _advance(cues, 2.5);
    expect(world.motion, DashmaruMotion.idle);
    expect(world.expression, DashmaruExpression.smile);
    _advance(cues, 10);
    expect(world.selections.where((motion) => motion == DashmaruMotion.jump), [
      DashmaruMotion.jump,
    ]);
  });

  test('a skipped standing sequence cannot jump on a later slide', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(12)
      ..attach(world)
      ..selectSlide(13);
    _advance(cues, 0.5);
    cues.selectSlide(15);
    _advance(cues, 10);
    expect(world.selections, isNot(contains(DashmaruMotion.jump)));
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
      ..selectSlide(13, reducedMotion: true)
      ..attach(world);
    _advance(cues, 10);
    expect(world.playing, isFalse);
    expect(world.motion, DashmaruMotion.idle);
    expect(world.advancedFrames, 0);

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
      ..selectDemoMotion(DashmaruMotion.walk);
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
    expect(world.expression, DashmaruExpression.spiral);
  });
}
