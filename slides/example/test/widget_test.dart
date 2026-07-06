import 'package:example_slide/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExampleApp builds without error', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
  });
}
