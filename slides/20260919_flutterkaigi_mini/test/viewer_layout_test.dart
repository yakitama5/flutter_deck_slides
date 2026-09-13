import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterkaigi_mini_20260919/dashmaru_scene.dart';
import 'package:flutterkaigi_mini_20260919/main.dart';

class _LoadingScene extends DashmaruScene {
  @override
  Future<void> load({
    required DashmaruMotion initialMotion,
    DashmaruExpression initialExpression = DashmaruExpression.normal,
    double? initialTime,
    String? initialCamera,
  }) => Completer<void>().future;
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(320, 640),
    const Size(390, 844),
    const Size(640, 360),
  ]) {
    testWidgets('viewer controls fit ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // The loading shell has the same controls and stage constraints as the
      // ready viewer, without requiring a GPU in the widget-test process.
      await tester.pumpWidget(DashmaruApp(world: _LoadingScene()));
      expect(tester.takeException(), isNull);
      for (final label in ['歩く', 'ジャンプ', '手を振る', 'まばたき', '待機', '走る', 'ぶんぶん']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
