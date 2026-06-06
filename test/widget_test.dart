import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentHubApp());
    await tester.pumpAndSettle();
    // Smoke test - app should render without errors
  });
}
