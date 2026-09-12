import 'package:flutter_test/flutter_test.dart';
import 'package:floatnote/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FloatNoteApp());
    expect(find.byType(FloatNoteApp), findsOneWidget);
  });
}
