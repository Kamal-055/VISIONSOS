import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vision/main.dart'; 

void main() {
  testWidgets('App compiles and loads successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame inside ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: VisionApp(),
      ),
    );

    // Verify application starts up
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
