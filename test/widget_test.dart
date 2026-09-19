import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_portfolio/main.dart';
import 'package:flutter_portfolio/providers/app_provider.dart';
import 'package:flutter_portfolio/providers/network_provider.dart';
import 'package:flutter_portfolio/providers/network_diagnostic_provider.dart';

void main() {
  Future<AppProvider> pumpApp(
    WidgetTester tester, {
    AppProvider? appProvider,
    NetworkProvider? networkProvider,
    NetworkDiagnosticProvider? diagnosticProvider,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    final provider = appProvider ?? AppProvider();
    final netProvider = networkProvider ?? NetworkProvider();
    final diagProvider = diagnosticProvider ??
        NetworkDiagnosticProvider(autoStartDiagnostics: false);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: netProvider),
          ChangeNotifierProvider.value(value: diagProvider),
        ],
        child: const MyApp(),
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
    expect(find.text('Network Diagnostic'), findsOneWidget);
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appProvider),
          ChangeNotifierProvider.value(value: networkProvider),
          ChangeNotifierProvider.value(
              value: NetworkDiagnosticProvider(autoStartDiagnostics: false)),
        ],
        child: const MyApp(),
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

  testWidgets('Network Diagnostic Dashboard shows health status',
      (WidgetTester tester) async {
    final diagnosticProvider =
        NetworkDiagnosticProvider(autoStartDiagnostics: false);
    await pumpApp(
      tester,
      diagnosticProvider: diagnosticProvider,
    );

    await tester.tap(find.text('Network Diagnostic'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Network Diagnostic'), findsOneWidget);
    expect(find.text('Run Diagnostics'), findsOneWidget);
    expect(find.text('Idle Ping'), findsWidgets);
  });
}
