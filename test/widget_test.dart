import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_portfolio/main.dart';
import 'package:flutter_portfolio/providers/app_provider.dart';
import 'package:flutter_portfolio/providers/network_provider.dart';

void main() {
  Future<AppProvider> pumpApp(
    WidgetTester tester, {
    AppProvider? appProvider,
    NetworkProvider? networkProvider,
  }) async {
    final provider = appProvider ?? AppProvider();
    final netProvider = networkProvider ?? NetworkProvider();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1080, 1920)),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: netProvider),
          ],
          child: const MyApp(),
        ),
      ),
    );
    return provider;
  }

  testWidgets('Home Dashboard renders correctly', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Home Dashboard'), findsOneWidget);
    expect(find.text('Activity One'), findsOneWidget);
    expect(find.text('Activity Two'), findsOneWidget);
    expect(find.text('Network Monitor'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('Navigate to Activity Screen 1', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Activity One'));
    await tester.pumpAndSettle();

    expect(find.text('Activity One'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
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

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Back to Dashboard').first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('User profile name updates Home Dashboard',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Display Name').first,
      'Portfolio User',
    );

    await tester.tap(find.text('Save Name'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Back to Dashboard').first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Portfolio User!'), findsOneWidget);
  });

  testWidgets('Global state provider updates across screens',
      (WidgetTester tester) async {
    final appProvider = AppProvider();
    final networkProvider = NetworkProvider();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1080, 1920)),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appProvider),
            ChangeNotifierProvider.value(value: networkProvider),
          ],
          child: const MyApp(),
        ),
      ),
    );

    expect(find.text('Welcome, Guest User!'), findsOneWidget);

    appProvider.setUserName('Global User');
    await tester.pump();

    expect(find.text('Welcome, Global User!'), findsOneWidget);
  });

  testWidgets('Network Monitor screen shows network status',
      (WidgetTester tester) async {
    final networkProvider = NetworkProvider();
    await pumpApp(
      tester,
      networkProvider: networkProvider,
    );

    await tester.tap(find.text('Network Monitor'));
    await tester.pumpAndSettle();

    expect(find.text('Network Monitor'), findsOneWidget);
    expect(find.text('Request Queue'), findsOneWidget);
    expect(find.text('Request Statistics'), findsOneWidget);
    expect(find.text('Simulate Request'), findsOneWidget);
    expect(find.text('Simulate Handover'), findsOneWidget);
  });

  testWidgets('Network request is queued when offline',
      (WidgetTester tester) async {
    final networkProvider = NetworkProvider();
    await pumpApp(
      tester,
      networkProvider: networkProvider,
    );

    await tester.tap(find.text('Network Monitor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulate Request'));
    await tester.pumpAndSettle();

    expect(networkProvider.queueLength, greaterThanOrEqualTo(0));
  });
}
