import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oso_20260912/main.dart';
import 'package:oso_20260912/speaker_notes.dart';
import 'package:oso_20260912/theme.dart';
import 'package:oso_20260912/widgets.dart';

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
    expect(SpeakerNotes.backCover, contains('おしまい'));
  });

  test('the speaker supplies the portrait and the sponsor photo', () {
    // Both paths are declared in pubspec.yaml, so a renamed replacement breaks
    // the web build rather than the slide. Fail here instead, where the message
    // names the file.
    for (final path in <String>[
      OsoProfileBody.avatarAssetPath,
      OsoCompanySlide.imageAssetPath,
    ]) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '$path is declared in pubspec.yaml and must exist',
      );
    }
  });

  test('the presentation type scale is sized for a projected room', () {
    expect(osoCanvasSize, const Size(1920, 1080));
    // Body copy has to stay readable from the back of the hall. Against the
    // canvas above this is roughly 3% of the screen height.
    expect(osoTheme.textTheme.bodyLarge?.fontSize, greaterThanOrEqualTo(32));
    expect(osoTheme.textTheme.displaySmall?.fontSize, greaterThanOrEqualTo(72));
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
    // The cover is artwork only; the title is spoken, not printed.
    expect(find.text('リスくんと\nひとつのどんぐり'), findsNothing);

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

    // The arrow key advances a step at a time, so a slide with steps has to be
    // walked through before the next slide is reached.
    for (final (onSlide, steps) in <(String, int)>[
      ('絵本から、現実の話へ', 1),
      ('自己紹介', 1),
      ('絵本で伝えたかったこと', 2),
      ('絵本のモデルとなった話', 4),
      ('持ち帰り', 1),
      ('ピープルソフトウェア株式会社', 1),
      (OsoFinalThanksSlide.message, 1),
    ]) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text(onSlide), findsOneWidget, reason: 'expected $onSlide');

      for (var step = 1; step < steps; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
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
