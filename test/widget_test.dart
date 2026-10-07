
import 'package:flutter_test/flutter_test.dart';
import 'package:cheri/main.dart';

void main() {
  testWidgets('Cheri app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CheriApp());

    expect(find.text('Cheri'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
