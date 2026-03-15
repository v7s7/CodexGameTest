import 'package:flutter_test/flutter_test.dart';
import 'package:gravity_tug_color_clash/main.dart';

void main() {
  testWidgets('renders game instructions', (WidgetTester tester) async {
    await tester.pumpWidget(const GravityTugApp());

    expect(find.textContaining('White = pull toward you'), findsOneWidget);
  });
}
