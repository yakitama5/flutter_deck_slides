import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterkaigi_mini_lt_20260919/main.dart';
import 'package:flutterkaigi_mini_lt_20260919/mascot.dart';
import 'package:flutterkaigi_mini_lt_20260919/pages.dart';
import 'package:flutterkaigi_mini_lt_20260919/slides.dart';
import 'package:flutterkaigi_mini_lt_20260919/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Noto Sans JP',
    )..addFont(rootBundle.load('assets/fonts/NotoSansJP-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('all slides fit the projector, laptop and portrait viewports', (
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
      for (var index = 0; index < ltPages.length; index++) {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: const MaterialTheme().dark(),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: FittedBox(child: LtSlide(slideIndex: index)),
                ),
              ),
            ),
          ),
        );
        if (index == 0 && size.width == 1920) {
          await tester.runAsync(() async {
            final context = boundaryKey.currentContext!;
            for (final asset in [
              'assets/profile/avatar.png',
              'assets/showcase/flutter_scene_202603.png',
              'assets/showcase/scene_materials.jpg',
              'assets/showcase/scene_lighting.jpg',
            ]) {
              await precacheImage(AssetImage(asset), context);
            }
          });
        }
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${ltPages[index].route} at $size',
        );
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
            final number = (index + 1).toString().padLeft(2, '0');
            File('${directory.path}/$number.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });

  testWidgets('keyboard navigation retains one mascot through all 14 slides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const FlutterKaigiMiniLtApp(enableRendering: false),
    );
    await tester.pumpAndSettle();
    final actor = find.byType(DashmaruActor, skipOffstage: false);
    expect(ltPages, hasLength(14));
    expect(ltPages[9].route, '/delegate');
    final retainedState = tester.state(actor);
    final theme = Theme.of(tester.element(actor));
    expect(theme.textTheme.bodyLarge!.fontFamily, 'Noto Sans JP');
    expect(theme.colorScheme, MaterialTheme.colorScheme(Brightness.dark));
    for (var index = 0; index < ltPages.length; index++) {
      if (index > 0) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(ValueKey(ltPages[index].route)), findsOneWidget);
      expect(tester.state(actor), same(retainedState));
      expect(tester.widget<DashmaruActor>(actor).slideIndex, index);
      expect(
        tester.widget<DashmaruActor>(actor).large,
        index == 5 || ltPages[index].route == '/thanks',
      );
      final actorSize = tester.getSize(actor);
      if (ltPages[index].route == '/thanks') {
        expect(actorSize, const Size(790, 790));
      } else if (index >= 7) {
        expect(actorSize, const Size(390, 370));
      }
      expect(tester.takeException(), isNull, reason: ltPages[index].route);
      if (index == 5) {
        // A demo button focuses the actor's subtree, outside the Navigator.
        Focus.of(tester.element(actor)).requestFocus();
        await tester.pump();
        expect(Focus.of(tester.element(actor)).hasFocus, isTrue);
      }
    }
    for (var index = ltPages.length - 2; index >= 0; index--) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(ltPages[index].route)), findsOneWidget);
      expect(tester.state(actor), same(retainedState));
      expect(tester.widget<DashmaruActor>(actor).slideIndex, index);
      expect(tester.takeException(), isNull, reason: ltPages[index].route);
    }
  });
}
