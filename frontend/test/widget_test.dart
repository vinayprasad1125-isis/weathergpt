import 'package:flutter_test/flutter_test.dart';
import 'package:weathergpt_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherGPTApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('🌦 WeatherGPT'), findsWidgets);
  });
}
