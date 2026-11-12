import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gold_calculator/main.dart';
import 'package:gold_calculator/services/preferences_service.dart';

void main() {
  testWidgets('Pak Gold Pro app launches and renders dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.init();

    await tester.pumpWidget(GoldCalculatorApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Verify branded AppBar and Dashboard elements render
    expect(find.text('Pak Gold Pro'), findsOneWidget);
    // Verified clean single title
    expect(find.text('Pak Gold Pro'), findsWidgets);
    expect(find.text('Shopkeeper & Buyer Tools'), findsOneWidget);
    expect(find.text('Jewelry Purchase & Bill Calculator'), findsOneWidget);
    expect(find.text('Tola Masha Ratti Converter'), findsOneWidget);
  });
}
