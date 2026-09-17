import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterkaigi_mini_lt_20260919/showcase_video.dart';
import 'package:video_player/video_player.dart';

class _DemoController extends VideoPlayerController {
  _DemoController(super.url, {this.delayed = false}) : super.networkUrl();

  final bool delayed;
  final ready = Completer<void>();
  bool released = false;
  int playCalls = 0;
  double? volume;
  bool? looping;

  @override
  Future<void> initialize() {
    if (!delayed) finishInitialization();
    return ready.future;
  }

  void finishInitialization() {
    if (!released) {
      value = const VideoPlayerValue(
        duration: Duration(seconds: 8),
        size: Size(1280, 720),
        isInitialized: true,
      );
    }
    ready.complete();
  }

  @override
  Future<void> setVolume(double value) async => volume = value;

  @override
  Future<void> setLooping(bool value) async => looping = value;

  @override
  Future<void> play() async {
    playCalls++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> dispose() async {
    released = true;
    await super.dispose();
  }
}

Widget _card({
  required VideoPlayerController Function(Uri) create,
  bool active = true,
  bool tickerEnabled = true,
}) => MaterialApp(
  home: Scaffold(
    body: TickerMode(
      enabled: tickerEnabled,
      child: Center(
        child: SizedBox(
          width: 750,
          height: 472,
          child: ShowcaseVideo(
            title: 'ライティング',
            posterAsset: 'assets/showcase/scene_lighting.jpg',
            videoUrl: 'https://fscene.dev/media/feat-lighting.mp4',
            isActive: active,
            controllerFactory: create,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('loads on click and provides mute, loop, pause and resume', (
    tester,
  ) async {
    final created = <_DemoController>[];
    _DemoController create(Uri uri) {
      final controller = _DemoController(uri);
      created.add(controller);
      return controller;
    }

    await tester.pumpWidget(_card(create: create));
    expect(created, isEmpty);
    expect(find.text('公式サイト'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    final controller = created.single;
    expect(controller.dataSource, endsWith('/feat-lighting.mp4'));
    expect(controller.volume, 0);
    expect(controller.looping, isTrue);
    expect(controller.playCalls, 1);

    await tester.tap(find.text('一時停止'));
    await tester.pump();
    expect(controller.value.isPlaying, isFalse);
    await tester.tap(find.text('再生'));
    await tester.pump();
    expect(controller.playCalls, 2);

    await tester.pumpWidget(const SizedBox());
    expect(controller.released, isTrue);
  });

  testWidgets('leaving the slide releases video and returning keeps poster', (
    tester,
  ) async {
    final created = <_DemoController>[];
    _DemoController create(Uri uri) {
      final controller = _DemoController(uri);
      created.add(controller);
      return controller;
    }

    await tester.pumpWidget(_card(create: create));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pumpWidget(_card(create: create, active: false));
    expect(created.single.released, isTrue);
    expect(find.byType(VideoPlayer), findsNothing);

    await tester.pumpWidget(_card(create: create));
    expect(created, hasLength(1));
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('a cached route with disabled tickers releases its video', (
    tester,
  ) async {
    late _DemoController controller;
    _DemoController create(Uri uri) => controller = _DemoController(uri);
    await tester.pumpWidget(_card(create: create));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pumpWidget(_card(create: create, tickerEnabled: false));
    expect(controller.released, isTrue);
  });

  testWidgets(
    'initialization finishing after navigation never starts playback',
    (tester) async {
      late _DemoController controller;
      _DemoController create(Uri uri) =>
          controller = _DemoController(uri, delayed: true);
      await tester.pumpWidget(_card(create: create));
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(_card(create: create, active: false));
      controller.finishInitialization();
      await tester.pump();
      expect(controller.released, isTrue);
      expect(controller.playCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed video offers retry and keeps the official source link', (
    tester,
  ) async {
    final created = <_DemoController>[];
    _DemoController create(Uri uri) {
      final controller = _DemoController(uri, delayed: true);
      created.add(controller);
      return controller;
    }

    await tester.pumpWidget(_card(create: create));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    created.single.ready.completeError(StateError('offline'));
    await tester.pump();
    expect(created.single.released, isTrue);
    expect(find.textContaining('読み込めませんでした'), findsOneWidget);
    expect(find.text('公式サイト'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    expect(created, hasLength(2));
    created.last.finishInitialization();
    await tester.pump();
    expect(find.text('一時停止'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
