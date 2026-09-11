import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oso_20260912/main.dart';
import 'package:oso_20260912/speaker_notes.dart';

void main() {
  test('selected story pages stay in numeric order', () {
    expect(
      osoPages.map((page) => page.number),
      orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
    );
    expect(
      osoPages.map((page) => page.assetPath),
      orderedEquals(<String>[
        'assets/risukun_hitotsu_no_donguri/00_cover.png',
        'assets/risukun_hitotsu_no_donguri/01_page01.png',
        'assets/risukun_hitotsu_no_donguri/02_page02.png',
        'assets/risukun_hitotsu_no_donguri/03_page03.png',
        'assets/risukun_hitotsu_no_donguri/04_page04.png',
        'assets/risukun_hitotsu_no_donguri/05_page05.png',
        'assets/risukun_hitotsu_no_donguri/06_page06.png',
        'assets/risukun_hitotsu_no_donguri/07_page07.png',
        'assets/risukun_hitotsu_no_donguri/08_page08.png',
        'assets/risukun_hitotsu_no_donguri/09_page09.png',
        'assets/risukun_hitotsu_no_donguri/10_page10.png',
        'assets/risukun_hitotsu_no_donguri/11_page11_ending.png',
      ]),
    );
  });

  test('every story page uses the separately managed speaker notes', () {
    expect(
      osoPages.map((page) => page.speakerNotes),
      orderedEquals(SpeakerNotes.bookPages),
    );
    expect(
      osoPages.map((page) => page.speakerNotes.trim()),
      everyElement(isNotEmpty),
    );
    expect(SpeakerNotes.bookPages, hasLength(osoPages.length));
    expect(SpeakerNotes.frontCover.trim(), isNotEmpty);
    expect(osoPages.last.speakerNotes, contains('おしまい'));
  });

  testWidgets('the storybook opens, turns through pages, and closes', (
    tester,
  ) async {
    await tester.pumpWidget(const OsoStorybookApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('storybook-book-front-cover')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    expect(find.text('リスくんと\nひとつのどんぐり'), findsOneWidget);

    for (var pageNumber = 1; pageNumber <= osoPages.length; pageNumber++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('oso-page-image-$pageNumber')),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('oso-page-$pageNumber')), findsOneWidget);
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('storybook-book-back-cover')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('ご清聴ありがとうございました'), findsOneWidget);
    expect(find.text('とはいかず……'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('ご清聴ありがとうございました'), findsOneWidget);
    expect(find.text('とはいかず……'), findsOneWidget);

    for (final presentationTitle in <String>[
      'ここからは、絵本のモデルとなった話と絵本を通して伝えたかった内容の話になります',
      '自己紹介',
      '絵本で伝えたかったこと',
      '絵本のモデルとなった話',
      '持ち帰り',
      '会社紹介',
      'ご清聴ありがとうございました',
    ]) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text(presentationTitle), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('page reveal configuration stays valid', (tester) async {
    await tester.pumpWidget(const OsoStorybookApp());
    await tester.pumpAndSettle();

    for (final page in osoPages) {
      final reveal = page.circularSketchReveal;
      expect(reveal.origin.x, inInclusiveRange(-1, 1));
      expect(reveal.origin.y, inInclusiveRange(-1, 1));
      expect(reveal.artworkAspectRatio, greaterThan(0));
      expect(reveal.focusLineFraction, inExclusiveRange(0, 1.000001));
      expect(reveal.surroundingFadeFraction, inExclusiveRange(0, 1.000001));
      expect(
        reveal.focusLineFraction + reveal.surroundingFadeFraction,
        lessThan(1),
      );
    }
  });
}
