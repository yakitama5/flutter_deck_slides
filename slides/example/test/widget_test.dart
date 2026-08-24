import 'package:example_slide/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_deck_storybook/src/storybook_page_curl.dart';
import 'package:flutter_deck_storybook/src/storybook_reveal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExampleApp mounts its focus tree after the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    final placeholder = find.byKey(
      const ValueKey('flutter-deck-initial-layout-placeholder'),
    );

    expect(placeholder, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump();

    expect(placeholder, findsNothing);
    expect(find.text('FlutterDeck Storybook'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('previous navigation covers the current page from above', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.textContaining('ある日、青い小鳥は'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final coverSheet = tester.widget<StorybookCurlSheet>(
      find.byKey(const ValueKey('storybook-page-cover-incoming-sheet')),
    );
    expect(coverSheet.direction, StorybookPageCurlDirection.backward);
    expect(coverSheet.motion, StorybookPageCurlMotion.coverPrevious);
    expect(coverSheet.progress, inExclusiveRange(0, 1));
    expect(
      find.byKey(const ValueKey('storybook-page-cover-current-page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('storybook-page-turn-outgoing-sheet')),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(find.text('FlutterDeck Storybook'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.pump(const Duration(milliseconds: 650));

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
