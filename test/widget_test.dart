import 'package:flutter_test/flutter_test.dart';
import 'package:campus_transit/main.dart';

void main() {
  testWidgets('Campus Transit welcome screen displays correctly',
      (WidgetTester tester) async {
    // Open the Campus Transit app.
    await tester.pumpWidget(const CampusTransitApp());

    // Check that the app name is displayed.
    expect(find.text('Campus Transit'), findsOneWidget);

    // Check that the login choices are displayed.
    expect(find.text('Continue as:'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

  });
}
