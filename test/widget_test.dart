import 'package:flutter_test/flutter_test.dart';
import 'package:wherethevibesat/main.dart';

void main() {
  testWidgets('shows branded splash', (WidgetTester tester) async {
    await tester.pumpWidget(const WhereTheVibesAtApp());
    await tester.pump();

    expect(find.text('WHERETHEVIBESAT'), findsOneWidget);
    expect(find.text('Find where the vibes at tonight'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();
  });
}
