import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invisible_grills/app/app.dart';

void main() {
  testWidgets('App renders CustomerListScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: InvisibleGrillsApp(),
      ),
    );

    // Verify title is shown
    expect(find.text('Invisible Grills'), findsOneWidget);
    expect(find.text('New Estimate'), findsOneWidget);
  });
}
