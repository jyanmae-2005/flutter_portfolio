import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_portfolio/main.dart';
import 'package:flutter_portfolio/providers/app_provider.dart';

void main() {
  /// Helper: wraps the app in a ChangeNotifierProvider so tests can verify
  /// global state behavior.
  Future<AppProvider> pumpApp(
    WidgetTester tester, {
    AppProvider? provider,
  }) async {
    final appProvider = provider ?? AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appProvider,
        child: const MyApp(),
      ),
    );
    return appProvider;
  }

  testWidgets('Home Dashboard renders correctly', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Home Dashboard'), findsOneWidget);
    expect(find.text('Activity One'), findsOneWidget);
    expect(find.text('Activity Two'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('Navigate to Activity Screen 1', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Activity One'));
    await tester.pumpAndSettle();

    expect(find.text('Activity One'), findsOneWidget);
    expect(find.text('Item A'), findsOneWidget);
  });

  testWidgets('Navigate to Activity Screen 2', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Activity Two'));
    await tester.pumpAndSettle();

    expect(find.text('Activity Two'), findsOneWidget);
    expect(find.text('Edit Text'), findsOneWidget);
  });

  testWidgets('Navigate to Settings and toggle theme',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Navigate back to Home Dashboard
    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Back to Dashboard').first,
    );
    await tester.pumpAndSettle();

    // The theme chip on Home Dashboard should reflect dark mode
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('User profile name updates Home Dashboard',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Navigate to Settings
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Enter a new name
    await tester.enterText(
      find.widgetWithText(TextField, 'Display Name').first,
      'Portfolio User',
    );

    // Save the name
    await tester.tap(find.text('Save Name'));
    await tester.pumpAndSettle();

    // Navigate back to Home Dashboard
    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Back to Dashboard').first,
    );
    await tester.pumpAndSettle();

    // The welcome message should show the new name
    expect(find.text('Welcome, Portfolio User!'), findsOneWidget);
  });

  testWidgets('Global state provider updates across screens',
      (WidgetTester tester) async {
    final appProvider = AppProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appProvider,
        child: const MyApp(),
      ),
    );

    expect(find.text('Welcome, Guest User!'), findsOneWidget);

    appProvider.setUserName('Global User');
    await tester.pump();

    expect(find.text('Welcome, Global User!'), findsOneWidget);
  });
}
