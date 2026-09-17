import 'dart:convert';
import 'dart:io';

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

List<Offset> _projectModelBounds(
  DashmaruCueController cues,
  Map<String, dynamic> bounds,
  Size viewSize,
) {
  final minimum = List<num>.from(bounds['min'] as List);
  final maximum = List<num>.from(bounds['max'] as List);
  final camera = cues.camera(Duration.zero);
  return [
    for (final x in [minimum[0], maximum[0]])
      for (final y in [minimum[1], maximum[1]])
        for (final z in [minimum[2], maximum[2]])
          camera.worldToScreen(
            camera.target.clone()
              ..setValues(x.toDouble(), y.toDouble(), z.toDouble()),
            viewSize,
          )!,
  ];
}

void main() {
  // Both projection regressions share one model read and pose sampling pass.
  late final Future<Map<String, dynamic>> modelBounds = () async {
    final result = await Process.run('python3', [
      '-B',
      'test/support/model_motion_bounds.py',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  }();

  testWidgets('the demo offers waving, running, shaking and jumping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actorBounds = dashmaruActorBounds(5);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fromRect(
              rect: actorBounds,
              child: const DashmaruActor(
                slideIndex: 5,
                large: true,
                enableRendering: false,
              ),
            ),
          ],
        ),
      ),
    );

    for (final label in ['手を振る', '走る', 'ぶんぶん', 'ジャンプ']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('歩く'), findsNothing);
    expect(find.text('待機'), findsNothing);
    final sceneBottom = actorBounds.bottom - dashmaruDemoControlsSpace;
    for (final element in find.byType(TextButton).evaluate()) {
      final button = tester.getRect(find.byWidget(element.widget));
      expect(button.top, greaterThanOrEqualTo(sceneBottom));
      expect(actorBounds.contains(button.topLeft), isTrue);
      expect(actorBounds.contains(button.bottomRight), isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  for (final (slide, motion, expression) in [
    (6, DashmaruMotion.celebrate, DashmaruExpression.smile),
    (7, DashmaruMotion.shake, DashmaruExpression.strain),
    (8, DashmaruMotion.sit, DashmaruExpression.spiral),
    (10, DashmaruMotion.tilt, DashmaruExpression.spiral),
    (15, DashmaruMotion.nod, DashmaruExpression.smile),
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
    expect(world.motion, DashmaruMotion.idle);
    expect(world.expression, DashmaruExpression.normal);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.idle);
    cues.selectSlide(10);
    _advance(cues, 10);
    expect(world.motion, DashmaruMotion.tilt);
    expect(world.expression, DashmaruExpression.spiral);
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

  test('the two seated examples retain one entrance and clear dizzy eyes', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(10)
      ..attach(world);
    expect(world.expression, DashmaruExpression.spiral);
    _advance(cues, 5);
    for (final slide in [11, 12]) {
      cues.selectSlide(slide);
      _advance(cues, 5);
      expect(world.expression, DashmaruExpression.normal);
    }
    cues.selectSlide(11);

    expect(world.motion, DashmaruMotion.sit);
    expect(world.selections, [DashmaruMotion.tilt, DashmaruMotion.sit]);
  });

  test('after the seated examples the companion stands calmly', () {
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
    expect(world.motion, DashmaruMotion.nod);
    expect(world.expression, DashmaruExpression.smile);
    cues.selectSlide(13);
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
      (10, DashmaruExpression.spiral),
      (15, DashmaruExpression.smile),
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

  test('running in the demo strains, then changing motion resets the face', () {
    final world = _FakeWorld();
    final cues = DashmaruCueController()
      ..selectSlide(5)
      ..attach(world);
    for (final next in [
      DashmaruMotion.wave,
      DashmaruMotion.shake,
      DashmaruMotion.jump,
    ]) {
      cues.selectDemoMotion(DashmaruMotion.run);
      _advance(cues, 5);
      expect(world.displayedExpression, DashmaruExpression.strain);
      cues.selectDemoMotion(next);
      expect(world.expression, DashmaruExpression.normal);
    }
    cues.selectDemoMotion(DashmaruMotion.run);
    cues.selectSlide(9);
    _advance(cues, 5);
    expect(world.motion, DashmaruMotion.idle);
    expect(world.expression, DashmaruExpression.normal);
  });

  test(
    'the complete Celebrate loop fits its frame without shrinking',
    () async {
      final data = await modelBounds;
      final bounds = data['Celebrate'] as Map<String, dynamic>;
      expect(bounds['samples'], greaterThan(300));

      final world = _FakeWorld();
      final cues = DashmaruCueController()..attach(world);
      List<Offset> project(int slide) {
        cues.selectSlide(slide);
        return _projectModelBounds(
          cues,
          bounds,
          dashmaruActorBounds(slide).size,
        );
      }

      // Check the measured, skinned animation envelope rather than only its
      // neutral pose. The old frame really does cut into this same envelope.
      final ordinaryFrame = dashmaruActorBounds(9);
      expect(
        project(
          9,
        ).any((point) => !(Offset.zero & ordinaryFrame.size).contains(point)),
        isTrue,
      );
      final normalScale = ordinaryFrame.height / world.distance;
      final ideasFrame = dashmaruActorBounds(6);
      final safeArea = (Offset.zero & ideasFrame.size).deflate(8);
      for (final point in project(6)) {
        expect(safeArea.contains(point), isTrue, reason: '$point / $safeArea');
      }
      expect(ideasFrame.height / world.distance, closeTo(normalScale, 1e-9));
      expect(ideasFrame.bottom, ordinaryFrame.bottom);
      expect(ideasFrame.center.dx, ordinaryFrame.center.dx);

      // Returning to the deck restores its original camera framing.
      for (final slide in [7, 9, 10, 15, 16]) {
        cues.selectSlide(slide);
        final camera = cues.camera(Duration.zero);
        expect(world.distance, closeTo(10.4, 1e-9));
        expect(camera.target.y, closeTo(1.5, 1e-9));
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'every demo motion stays inside the viewport above its controls',
    () async {
      final data = await modelBounds;
      final world = _FakeWorld();
      final cues = DashmaruCueController()
        ..selectSlide(9)
        ..attach(world);
      const oldViewSize = Size(920, 746);
      final jump = data['Jump'] as Map<String, dynamic>;
      expect(jump['samples'], greaterThan(300));
      // Reproduce the original apex clipping with the original camera/box.
      expect(
        _projectModelBounds(cues, jump, oldViewSize).any((p) => p.dy < 0),
        isTrue,
      );
      final oldScale = oldViewSize.height / world.distance;
      final frame = dashmaruActorBounds(5);
      final viewSize = Size(
        frame.width,
        frame.height - dashmaruDemoControlsSpace,
      );
      final safeArea = (Offset.zero & viewSize).deflate(8);
      cues.selectSlide(5);
      // Retain at least 97% of the former size, rather than solving the bug
      // by making the demo visibly smaller. The left text remains separate.
      expect(viewSize.height / world.distance / oldScale, greaterThan(0.97));
      expect(frame.left, greaterThan(845));
      expect(frame.top, greaterThanOrEqualTo(24));
      expect(frame.bottom, lessThan(1012));
      expect(frame.right, lessThan(1920));
      for (final motion in [
        DashmaruMotion.wave,
        DashmaruMotion.run,
        DashmaruMotion.shake,
        DashmaruMotion.jump,
      ]) {
        cues.selectDemoMotion(motion);
        final bounds = data[motion.clipName] as Map<String, dynamic>;
        for (final point in _projectModelBounds(cues, bounds, viewSize)) {
          expect(
            safeArea.contains(point),
            isTrue,
            reason: '${motion.clipName}: $point / $safeArea',
          );
        }
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

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
