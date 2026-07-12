import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motoshop_app/main.dart';

void main() {
  testWidgets('MotoshopApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MotoshopApp(),
      ),
    );
    // Verifica que la app inicia sin errores
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
