import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technologychoice_202609/main.dart';
import 'package:technologychoice_202609/pages.dart';
import 'package:technologychoice_202609/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Kiwi Maru')
      ..addFont(rootBundle.load('assets/fonts/KiwiMaru-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/KiwiMaru-Medium.ttf'));
    await fonts.load();
  });

  test('the ten story beats and the talk fit the ten-minute slot', () {
    expect(choicePages.where((p) => p.kind == PageKind.story), hasLength(10));
    expect(choicePages.fold<int>(0, (sum, p) => sum + p.seconds), 600);
    expect(
      choicePages.map((p) => p.route).toSet(),
      hasLength(choicePages.length),
    );
    expect(timedNotes(choicePages.last), startsWith('09:05–10:00'));
  });

  testWidgets('talk pages fit wide, laptop and portrait windows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [
      const Size(1920, 1080),
      const Size(1280, 800),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      for (final page in choicePages.where((p) => !p.isBook)) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ChoiceTalkPage(page: page)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(page.title), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.route} at $size',
        );
      }
    }
  });

  testWidgets(
    'keyboard navigation crosses both book boundaries in both directions',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const TechnologyChoiceApp());
      await tester.pumpAndSettle();
      for (var index = 0; index < choicePages.length; index++) {
        final page = choicePages[index];
        if (index > 0) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
        expect(find.byKey(ValueKey(page.route)), findsOneWidget);
        if (page.kind == PageKind.story) {
          expect(find.image(AssetImage(page.asset!)), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(StorybookPage),
              matching: find.byType(Text),
            ),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull, reason: page.route);
      }
      for (final page in choicePages.reversed.skip(1)) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey(page.route)), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'reverse ${page.route}');
      }
    },
  );
}
