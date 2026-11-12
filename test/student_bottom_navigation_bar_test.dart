import 'package:campus_transit/widgets/student_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('student navigation shows destinations and handles selection',
      (tester) async {
    int? selectedDestination;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: StudentBottomNavigationBar(
            currentIndex: 0,
            onDestinationSelected: (index) => selectedDestination = index,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Bus schedule'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Explore'));
    expect(selectedDestination, 1);

    await tester.tap(find.text('Profile'));
    expect(selectedDestination, 4);
  });
}
