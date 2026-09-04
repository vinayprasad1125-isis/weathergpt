import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weathergpt_flutter/screens/news_screen.dart';
import 'package:weathergpt_flutter/services/demo_alert_manager.dart';

void main() {
  testWidgets('NewsScreen initial render shows state selector and empty prompt', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NewsScreen(),
      ),
    );

    // Header check
    expect(find.text('📰 Weather News'), findsOneWidget);

    // Dropdown prompt check
    expect(find.text('Select Indian State'), findsOneWidget);

    // Empty prompt check
    expect(find.text('Select a state to view weather news'), findsOneWidget);
  });

  testWidgets('NewsScreen in Demo Mode displays demo articles when state is selected', (WidgetTester tester) async {
    // Enable demo mode
    DemoAlertManager.instance.isDemoMode.value = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: NewsScreen(),
      ),
    );

    // Verify dropdown is present
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DropdownMenuItem<String>), findsWidgets);
    await tester.tap(find.byType(DropdownMenuItem<String>).first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Demo Badge
    expect(find.text('DEMO MODE'), findsOneWidget);

    // Verify Demo Articles for the selected state (first state is Andhra Pradesh)
    expect(find.textContaining('Andhra Pradesh'), findsWidgets);
    expect(find.text('Read More'), findsWidgets);

    // Reset demo mode
    DemoAlertManager.instance.isDemoMode.value = false;
  });
}
