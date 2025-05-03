import 'package:flutter_test/flutter_test.dart';
import 'package:viva_journal/theme_provider.dart';

void main() {
  test('Initial theme is system default', () {
    final provider = ThemeProvider();
    expect(provider.themeMode, ThemeMode.system);
  });

  test('Toggle theme switches between light/dark', () {
    final provider = ThemeProvider();

    provider.toggleTheme(true);
    expect(provider.themeMode, ThemeMode.dark);

    provider.toggleTheme(false);
    expect(provider.themeMode, ThemeMode.light);
  });
}