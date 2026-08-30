import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
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
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('storybook-book-back-cover')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
