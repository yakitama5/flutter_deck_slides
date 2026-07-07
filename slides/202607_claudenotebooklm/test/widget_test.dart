import 'package:claudenotebooklm_202607/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ClaudenotebooklmApp builds without error', (tester) async {
    await tester.pumpWidget(const ClaudenotebooklmApp());
    await tester.pump(const Duration(seconds: 2));
  });
}
