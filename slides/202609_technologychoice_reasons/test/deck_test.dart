import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technologychoice_reasons_202609/main.dart';
import 'package:technologychoice_reasons_202609/pages.dart';
import 'package:technologychoice_reasons_202609/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Kiwi Maru')
      ..addFont(rootBundle.load('assets/fonts/KiwiMaru-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/KiwiMaru-Medium.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('every slide fits presentation, laptop and portrait viewports', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [
      const Size(1920, 1080),
      const Size(1280, 800),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      for (final page in reasonPages) {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: boundaryKey,
                child: ReasonSlide(page: page),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.route} at $size',
        );
        expect(find.text(page.title), findsOneWidget);
        if (const bool.fromEnvironment('RENDER_SLIDES') && size.width == 1920) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('build/previews')
              ..createSync(recursive: true);
            final number = (reasonPages.indexOf(page) + 1).toString().padLeft(
              2,
              '0',
            );
            File('${directory.path}/$number.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });

  testWidgets(
    'keyboard can traverse chapters and live demo slides in both directions',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const TechnologyReasonsApp());
      await tester.pumpAndSettle();
      for (final page in reasonPages) {
        if (page != reasonPages.first) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
        expect(find.byKey(ValueKey(page.route)), findsOneWidget);
        expect(tester.takeException(), isNull, reason: page.route);
      }
      for (final page in reasonPages.reversed.skip(1)) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey(page.route)), findsOneWidget);
        expect(tester.takeException(), isNull, reason: page.route);
      }
    },
  );
}
