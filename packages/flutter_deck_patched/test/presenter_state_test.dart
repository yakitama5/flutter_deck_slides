import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:flutter_deck_client/flutter_deck_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default presentation publishes and receives slide changes', (
    tester,
  ) async {
    final client = _MemoryClient();
    await tester.pumpWidget(_deck(client));
    await tester.pumpAndSettle();

    expect(client.initialStates.single?.slideIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(client.updates.last.slideIndex, 1);

    client.receive(client.updates.last.copyWith(slideIndex: 0));
    await tester.pumpAndSettle();
    expect(find.text('First slide'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('presenter shows the notes of the synchronized slide', (
    tester,
  ) async {
    final client = _MemoryClient();
    await tester.pumpWidget(_deck(client, isPresenterView: true));
    await tester.pumpAndSettle();
    expect(client.initialStates, [null]);
    expect(find.text('First notes'), findsOneWidget);

    client.receive(
      const FlutterDeckState(
        locale: 'en-US',
        themeMode: 'system',
        slideIndex: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Second notes'), findsOneWidget);
    expect(find.text('Notes: Slide 2'), findsOneWidget);
    // Preview capture waits 300 ms before taking its offscreen image.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });
}

Widget _deck(_MemoryClient client, {bool? isPresenterView}) => FlutterDeckApp(
  client: client,
  isPresenterView: isPresenterView,
  slides: [
    FlutterDeckSlide.blank(
      configuration: const FlutterDeckSlideConfiguration(
        route: '/first',
        speakerNotes: 'First notes',
      ),
      builder: (_) => const Text('First slide'),
    ),
    FlutterDeckSlide.blank(
      configuration: const FlutterDeckSlideConfiguration(
        route: '/second',
        speakerNotes: 'Second notes',
      ),
      builder: (_) => const Text('Second slide'),
    ),
  ],
);

class _MemoryClient implements FlutterDeckClient {
  final _controller = StreamController<FlutterDeckState>();
  final initialStates = <FlutterDeckState?>[];
  final updates = <FlutterDeckState>[];

  @override
  Stream<FlutterDeckState> get flutterDeckStateStream => _controller.stream;

  @override
  void init([FlutterDeckState? state]) => initialStates.add(state);

  @override
  void updateState(FlutterDeckState state) => updates.add(state);

  void receive(FlutterDeckState state) => _controller.add(state);

  @override
  void openPresenterView() {}

  @override
  void dispose() => unawaited(_controller.close());
}
