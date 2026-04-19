import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevak_app/app.dart';

void main() {
  testWidgets('SevakAI app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SevakApp(),
      ),
    );
    // Splash screen shows 'SevakAI' text
    expect(find.text('SevakAI'), findsOneWidget);
  });
}
