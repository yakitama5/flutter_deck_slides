import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_deck_storybook/flutter_deck_storybook.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:oso_festival_20260912/cover_emblem.dart';
import 'package:oso_festival_20260912/main.dart';
import 'package:oso_festival_20260912/pages.dart';
import 'package:oso_festival_20260912/theme.dart';
import 'package:oso_festival_20260912/widgets.dart';

void main() {
  testWidgets('icon cover opens to image-only pages and the OSO invitation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ForestFestivalApp());
    await tester.pumpAndSettle();
    expect(find.byType(StorybookCoverEmblem), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StorybookBookCover),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(StorybookBookCover),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    for (final page in festivalPages) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(page.slug)), findsOneWidget);
      expect(find.image(AssetImage(page.asset)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StoryArtwork),
          matching: find.byType(Text),
        ),
        findsNothing,
        reason: 'The story must be read from speaker notes, not captions',
      );
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
    expect(find.image(const AssetImage(EventPage.bannerAsset)), findsOneWidget);
    expect(find.byType(OsoBackdrop), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text(eventUrl), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.byType(OsoBackdrop), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.byType(EventPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
