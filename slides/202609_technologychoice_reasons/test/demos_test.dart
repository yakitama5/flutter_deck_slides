import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technologychoice_reasons_202609/demos.dart';

Future<void> _showDemo(WidgetTester tester, Widget demo) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 64)),
      ),
      home: Scaffold(
        body: Center(child: SizedBox(width: 760, height: 583, child: demo)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Kiwi Maru')
      ..addFont(rootBundle.load('assets/fonts/KiwiMaru-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/KiwiMaru-Medium.ttf'));
    await fonts.load();
  });
  testWidgets(
    'theme controls change actual colors, brightness, and saved state; reset restores all',
    (tester) async {
      await _showDemo(tester, const ThemeChoiceDemo());
      ColorScheme colors() =>
          Theme.of(tester.element(find.byKey(const ValueKey('theme-preview'))))
              .colorScheme;
      final original = colors().primary;
      expect(colors().brightness, Brightness.light);

      await tester.tap(find.text('紫'));
      await tester.pumpAndSettle();
      expect(colors().primary, isNot(original));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(colors().brightness, Brightness.dark);
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();
      expect(find.text('保存済み'), findsOneWidget);

      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();
      expect(colors().primary, original);
      expect(colors().brightness, Brightness.light);
      expect(find.text('保存する'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'available width switches bottom navigation to compact then extended rail',
    (tester) async {
      await _showDemo(tester, const ResponsiveChoiceDemo());
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('720 dp'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
      expect(find.text('medium'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('1024 dp'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(find.text('expanded'), findsOneWidget);
      await tester.tap(find.text('検索'));
      await tester.pumpAndSettle();
      expect(find.text('Repository Search'), findsOneWidget);

      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('compact'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Slang switches Japanese and English and resolves singular, plural, and zero',
    (tester) async {
      await _showDemo(tester, const LocalizationChoiceDemo());
      expect(find.text('1 件のリポジトリが見つかりました'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Search repositories'), findsOneWidget);
      expect(find.text('1 repository found'), findsOneWidget);

      await tester.tap(find.byTooltip('件数を増やす'));
      await tester.pumpAndSettle();
      expect(find.text('2 repositories found'), findsOneWidget);
      await tester.tap(find.byTooltip('件数を減らす'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('件数を減らす'));
      await tester.pumpAndSettle();
      expect(find.text('0 repositories found'), findsOneWidget);
      expect(find.text('Try another keyword.'), findsOneWidget);

      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();
      expect(find.text('リポジトリを検索'), findsOneWidget);
      expect(find.text('1 件のリポジトリが見つかりました'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
