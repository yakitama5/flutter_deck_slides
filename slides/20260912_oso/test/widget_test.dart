import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oso_20260912/main.dart';

void main() {
  test('selected story pages stay in numeric order', () {
    expect(
      osoPages.map((page) => page.number),
      orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
    );
    expect(
      osoPages.map((page) => page.assetPath),
      orderedEquals(<String>[
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
        'assets/risukun_hitotsu_no_donguri/11_page11.png',
      ]),
    );
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
