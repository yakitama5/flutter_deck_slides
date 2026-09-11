import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oso_festival_20260912/main.dart';
import 'package:oso_festival_20260912/pages.dart';
import 'package:oso_festival_20260912/widgets.dart';

void main() {
  testWidgets(
    'book opens, every page loads, closes and reaches the invitation',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ForestFestivalApp());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('storybook-book-front-cover')),
        findsOneWidget,
      );
      for (final page in festivalPages) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey(page.slug)), findsOneWidget);
        if (page.embeddedTitle) {
          expect(
            find.text(page.caption),
            findsNothing,
            reason: 'Decorated lettering is already part of the cover art',
          );
          expect(find.image(AssetImage(page.asset)), findsOneWidget);
        } else {
          expect(find.text(page.caption), findsOneWidget);
        }
        if (page.titleLayout) {
          expect(
            tester.getSize(find.text(page.caption)).height,
            lessThan(300),
            reason: 'The title must stay on two lines above the squirrel',
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('storybook-book-back-cover')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byType(EventPage), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text(eventUrl), findsOneWidget);
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (manifest.listAssets().contains('assets/event/qr.png')) {
        expect(
          find.image(const AssetImage('assets/event/qr.png')),
          findsOneWidget,
        );
      } else {
        expect(find.text('参加の\nお申し込み'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byType(EventPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional media displays a bundled image when present', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OptionalEventImage(
          asset: 'assets/story/06_ready.png',
          fallback: Text('fallback'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
