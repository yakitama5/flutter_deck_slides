import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_deck_storybook/src/storybook_reveal.dart';
import 'package:risukun_super_tenkomori_car_202608/main.dart';
import 'package:risukun_super_tenkomori_car_202608/speaker_notes.dart';

void main() {
  test('page data stays in numeric order and notes are complete', () {
    expect(
      risukunPages.map((page) => page.number),
      orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
    );
    expect(
      risukunPages.map((page) => page.assetPath),
      orderedEquals(<String>[
        'assets/risukun_super_tenkomori_car/01_title.png',
        'assets/risukun_super_tenkomori_car/02_race_dream.png',
        'assets/risukun_super_tenkomori_car/03_building.png',
        'assets/risukun_super_tenkomori_car/04_super_tenkomori_car.png',
        'assets/risukun_super_tenkomori_car/05_race_breakdown.png',
        'assets/risukun_super_tenkomori_car/06_owl_doctor.png',
        'assets/risukun_super_tenkomori_car/07_new_car.png',
        'assets/risukun_super_tenkomori_car/08_goal.png',
        'assets/risukun_super_tenkomori_car/09_yagni_comparison.png',
        'assets/risukun_super_tenkomori_car/10_ending.png',
      ]),
    );

    final notes = SpeakerNotes.all.join('\n');
    expect(notes, contains('それでは、発表を始めます。'));
    expect(notes, contains('『リスくんの スーパー・てんこもり・カー』'));
    expect(notes, contains('～～～'));
    expect(notes, contains('「You Aren’t Gonna Need It」の略で、'));
    expect(notes, contains('ご清聴ありがとうございました。'));

    for (final page in risukunPages) {
      final reveal = page.circularSketchReveal;
      expect(reveal.origin.x, inInclusiveRange(-1, 1));
      expect(reveal.origin.y, inInclusiveRange(-1, 1));
      expect(reveal.artworkAspectRatio, greaterThan(0));
      expect(reveal.initialRadiusFraction, inInclusiveRange(0, 1));
      expect(reveal.softEdgeFraction, inExclusiveRange(0, 1.000001));
    }
  });

  testWidgets('the ten image pages use the storybook cover and page flow', (
    tester,
  ) async {
    await tester.pumpWidget(const RisukunSuperTenkomoriCarApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('storybook-book-front-cover')),
      findsOneWidget,
    );

    for (var pageNumber = 1; pageNumber <= risukunPages.length; pageNumber++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('risukun-page-image-$pageNumber')),
        findsOneWidget,
      );
      final page = tester.widget<StorybookPage>(
        find.byKey(ValueKey('risukun-page-$pageNumber')),
      );
      expect(
        page.circularSketchReveal,
        risukunPages[pageNumber - 1].circularSketchReveal,
      );
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('storybook-book-back-cover')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'circular reveal remains stable on revisit and rapid navigation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const RisukunSuperTenkomoriCarApp());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('risukun-page-image-2')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('risukun-page-image-1')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.byType(StorybookPage), findsOneWidget);
      final visiblePage = tester.widget<StorybookPage>(
        find.byType(StorybookPage),
      );
      expect(visiblePage.circularSketchReveal, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('live route transition starts the reveal sequence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const RisukunSuperTenkomoriCarApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const ValueKey('risukun-page-image-1')), findsOneWidget);

    final scopes = tester.widgetList<StorybookRevealScope>(
      find.byType(StorybookRevealScope),
    );
    expect(scopes, isNotEmpty);
    final progress = scopes
        .map(
          (scope) =>
              'sketch=${scope.sketchProgress}, paint=${scope.paintProgress}',
        )
        .join('; ');
    expect(
      scopes.any((scope) => scope.sketchProgress > 0),
      isTrue,
      reason: progress,
    );
    expect(scopes.any((scope) => scope.paintProgress < 1), isTrue);
  });

  testWidgets('book boundary transitions keep the existing tabletop owner', (
    tester,
  ) async {
    await tester.pumpWidget(const RisukunSuperTenkomoriCarApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(Duration.zero);
    expect(find.byType(StorybookBookTabletop), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    expect(
      find.byKey(const ValueKey('storybook-book-opening-cover-tabletop')),
      findsNothing,
    );
    await tester.pumpAndSettle();

    for (var pageNumber = 2; pageNumber <= risukunPages.length; pageNumber++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('storybook-book-closing-underlay-tabletop')),
      findsOneWidget,
    );
    expect(find.byType(Opacity), findsNothing);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('storybook-book-closing-cover-tabletop')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
