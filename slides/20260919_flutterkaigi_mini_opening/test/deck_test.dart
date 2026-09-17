import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterkaigi_mini_opening_20260919/main.dart';
import 'package:flutterkaigi_mini_opening_20260919/pages.dart';
import 'package:flutterkaigi_mini_opening_20260919/theme.dart';
import 'package:flutterkaigi_mini_opening_20260919/widgets.dart';

const _slideImages = {
  OpeningKind.about: 'assets/images/kaigi-2025-hall.jpg',
  OpeningKind.event: 'assets/images/hamamatsucho-main-hall.jpg',
  OpeningKind.volunteer: 'assets/images/volunteer-team.jpg',
  OpeningKind.mini: 'assets/images/mini-okayama.png',
};

ImageProvider _provider(String asset) =>
    asset == 'assets/images/volunteer-team.jpg'
    ? ResizeImage(AssetImage(asset), width: 2000)
    : AssetImage(asset);

Future<void> _loadSlideImages(WidgetTester tester, BuildContext context) async {
  // Image codecs run outside the test clock. Waiting only for scheduled frames
  // can finish before decoding, which would produce a blank preview image.
  await tester.runAsync(() async {
    for (final asset in _slideImages.values) {
      Object? loadingError;
      await precacheImage(
        _provider(asset),
        context,
        onError: (error, stackTrace) => loadingError = error,
      );
      expect(loadingError, isNull, reason: 'Could not decode $asset');
    }
  });
  await tester.pumpAndSettle();
}

void _expectSlideImagesLoaded(WidgetTester tester, OpeningPage page) {
  final expectedAsset = _slideImages[page.kind];
  if (expectedAsset != null) {
    expect(find.image(_provider(expectedAsset)), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
  }
  for (final rawImage in tester.widgetList<RawImage>(find.byType(RawImage))) {
    expect(rawImage.image, isNotNull, reason: '${page.route}: image decoded');
    expect(rawImage.image!.width, greaterThan(0), reason: page.route);
    expect(rawImage.image!.height, greaterThan(0), reason: page.route);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'Noto Sans JP',
    )..addFont(rootBundle.load('assets/fonts/NotoSansJP.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test('nine slides include a complete five-minute speaking plan', () {
    expect(openingPages, hasLength(9));
    expect(openingPages.map((page) => page.route).toSet(), hasLength(9));
    expect(
      openingPages.fold<int>(0, (seconds, page) => seconds + page.seconds),
      300,
    );
    for (final page in openingPages) {
      expect(page.seconds, greaterThan(0), reason: page.route);
      expect(page.title.trim(), isNotEmpty, reason: page.route);
      expect(page.notes.trim(), isNotEmpty, reason: page.route);
    }
  });

  for (final size in [
    const Size(1600, 900),
    const Size(1280, 800),
    const Size(390, 844),
  ]) {
    testWidgets('every slide renders without overflow at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (var index = 0; index < openingPages.length; index++) {
        final page = openingPages[index];
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: openingTheme,
            home: Scaffold(
              body: RepaintBoundary(
                key: boundaryKey,
                child: OpeningSlide(page: page),
              ),
            ),
          ),
        );
        await _loadSlideImages(tester, boundaryKey.currentContext!);
        _expectSlideImagesLoaded(tester, page);
        expect(tester.takeException(), isNull, reason: page.route);

        if (const bool.fromEnvironment('RENDER_SLIDES') &&
            size == const Size(1600, 900)) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final directory = Directory('build/previews')
                ..createSync(recursive: true);
              final number = (index + 1).toString().padLeft(2, '0');
              File('${directory.path}/$number.png').writeAsBytesSync(
                bytes!.buffer.asUint8List(
                  bytes.offsetInBytes,
                  bytes.lengthInBytes,
                ),
              );
            } finally {
              image.dispose();
            }
          });
        }
      }
    });
  }

  testWidgets('keyboard visits all nine slides in both directions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const OpeningApp());
    await tester.pumpAndSettle();
    await _loadSlideImages(tester, tester.element(find.byType(OpeningSlide)));
    for (final page in openingPages) {
      if (page != openingPages.first) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(ValueKey(page.route)), findsOneWidget);
      _expectSlideImagesLoaded(tester, page);
      expect(tester.takeException(), isNull, reason: page.route);
    }
    for (final page in openingPages.reversed.skip(1)) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(page.route)), findsOneWidget);
      _expectSlideImagesLoaded(tester, page);
      expect(tester.takeException(), isNull, reason: page.route);
    }
  });
}
