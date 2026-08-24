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
    final coverTitle = find.text('FlutterDeck Storybook');
    expect(coverTitle, findsOneWidget);
    expect(ModalRoute.of(tester.element(coverTitle))?.opaque, isFalse);
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

  testWidgets(
    'previous navigation covers from the left binding without flash',
    (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.textContaining('ある日、青い小鳥は'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.pump();

      final initialCoverSheet = tester.widget<StorybookCurlSheet>(
        find.byKey(const ValueKey('storybook-page-cover-incoming-sheet')),
      );
      expect(initialCoverSheet.direction, StorybookPageCurlDirection.forward);
      expect(initialCoverSheet.motion, StorybookPageCurlMotion.coverPrevious);
      expect(initialCoverSheet.progress, closeTo(1, 0.001));

      final initialSheetClip = tester.widget<ClipPath>(
        find.byKey(const ValueKey('storybook-page-cover-sheet-clip')),
      );
      final initialClipSize = tester.getSize(
        find.byKey(const ValueKey('storybook-page-cover-sheet-clip')),
      );
      final initialBounds = initialSheetClip.clipper!
          .getClip(initialClipSize)
          .getBounds();
      expect(initialBounds.width, lessThan(initialClipSize.width * 0.01));
      expect(
        initialSheetClip.clipper!
            .getClip(initialClipSize)
            .contains(initialClipSize.center(Offset.zero)),
        isFalse,
      );

      await tester.pump(const Duration(milliseconds: 850));

      final previousPageRoute = ModalRoute.of(
        tester.element(find.text('FlutterDeck Storybook')),
      );
      final currentPageRoute = ModalRoute.of(
        tester.element(find.textContaining('ある日、青い小鳥は')),
      );
      expect(previousPageRoute?.opaque, isFalse);
      expect(currentPageRoute?.opaque, isFalse);

      final coverSheet = tester.widget<StorybookCurlSheet>(
        find.byKey(const ValueKey('storybook-page-cover-incoming-sheet')),
      );
      expect(coverSheet.direction, StorybookPageCurlDirection.forward);
      expect(coverSheet.motion, StorybookPageCurlMotion.coverPrevious);
      expect(coverSheet.progress, inExclusiveRange(0.45, 0.55));
      final sheetClip = tester.widget<ClipPath>(
        find.byKey(const ValueKey('storybook-page-cover-sheet-clip')),
      );
      final clipSize = tester.getSize(
        find.byKey(const ValueKey('storybook-page-cover-sheet-clip')),
      );
      final coverBounds = sheetClip.clipper!.getClip(clipSize).getBounds();
      expect(coverBounds.left, closeTo(0, 0.01));
      expect(coverBounds.right, inExclusiveRange(0, clipSize.width));
      final currentPageClip = tester
          .widgetList<StorybookCurlReveal>(find.byType(StorybookCurlReveal))
          .singleWhere(
            (reveal) =>
                reveal.clipKey ==
                const ValueKey('storybook-page-cover-current-page'),
          );
      expect(currentPageClip.motion, StorybookPageCurlMotion.coverPrevious);
      expect(currentPageClip.direction, StorybookPageCurlDirection.forward);
      expect(currentPageClip.progress, closeTo(coverSheet.progress, 0.01));
      expect(
        find.byKey(const ValueKey('storybook-page-turn-outgoing-sheet')),
        findsNothing,
      );

      await tester.pumpAndSettle();
      expect(find.text('FlutterDeck Storybook'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

    await tester.pump(const Duration(milliseconds: 900));

    expect(developingPage().sketchProgress, 0);
    expect(developingPage().paintProgress, 0);

    await tester.pump(const Duration(milliseconds: 250));

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
