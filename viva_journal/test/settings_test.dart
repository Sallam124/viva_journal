import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'remindersEnabled': false,
      'authEnabled': false,
    });
  });

  Widget createSettingsScreen() {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen renders and toggles reminder switch', (WidgetTester tester) async {
    await tester.pumpWidget(createSettingsScreen());
    await tester.pump(const Duration(seconds: 1)); // wait for async load

    expect(find.text('Enable Reminders'), findsOneWidget);
    final remindersSwitch = find.byType(Switch).first;
    expect(remindersSwitch, findsOneWidget);

    await tester.tap(remindersSwitch);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Reminder Time:'), findsOneWidget);
    expect(find.textContaining('Pick a time'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows authentication section when toggled', (WidgetTester tester) async {
    await tester.pumpWidget(createSettingsScreen());
    await tester.pump(const Duration(seconds: 1));

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    await tester.tap(switches.at(1)); // Auth switch
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining("Passcode"), findsOneWidget);
  });

  testWidgets('Logout button is present and clickable', (WidgetTester tester) async {
    await tester.pumpWidget(createSettingsScreen());
    await tester.pump(const Duration(seconds: 1));

    final logoutButton = find.text('Logout');
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton); // interaction only
    await tester.pump();
  });
}
