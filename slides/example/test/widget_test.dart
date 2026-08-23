import 'package:example_slide/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck_storybook/src/storybook_reveal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExampleApp bundles storybook sounds from the shared package', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    final pageTurn = await rootBundle.load(
      'packages/flutter_deck_storybook/assets/audio/page-turn.mp3',
    );
    final drawing = await rootBundle.load(
      'packages/flutter_deck_storybook/assets/audio/drawing-on-paper.mp3',
    );

    expect(pageTurn.lengthInBytes, greaterThan(8000));
    expect(drawing.lengthInBytes, greaterThan(30000));
  });

  testWidgets('ExampleApp moves through every storybook page', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('FlutterDeck Storybook'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    StorybookInkReveal developingPage() => tester
        .widgetList<StorybookInkReveal>(find.byType(StorybookInkReveal))
        .singleWhere((reveal) => reveal.paintProgress < 1);

    expect(developingPage().sketchProgress, 0);
    expect(developingPage().paintProgress, 0);

    await tester.pump(const Duration(milliseconds: 400));

    expect(developingPage().sketchProgress, 0);
    expect(developingPage().paintProgress, 0);

    await tester.pump(const Duration(milliseconds: 400));

    expect(developingPage().sketchProgress, greaterThan(0));
    expect(developingPage().paintProgress, 0);

    await tester.pumpAndSettle();

    expect(find.textContaining('ある日、青い小鳥は'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.text('おしまい'), findsOneWidget);
    expect(find.textContaining('ある日、青い小鳥は'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(find.textContaining('ある日、青い小鳥は'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(find.text('FlutterDeck Storybook'), findsOneWidget);
    expect(find.text('おしまい'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
