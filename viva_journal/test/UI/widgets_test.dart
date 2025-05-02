import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viva_journal/widgets/widgets.dart';

void main() {
  testWidgets('BackgroundContainer applies gradient', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BackgroundContainer(
          child: Container(),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    expect((container.decoration as BoxDecoration).gradient, isNotNull);
  });

  testWidgets('AppButton displays correct text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            onPressed: () {},
            text: 'Test Button',
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
  });
}