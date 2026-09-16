import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/network_provider.dart';
import 'screens/activity_screen1.dart';
import 'screens/activity_screen2.dart';
import 'screens/home_dashboard.dart';
import 'screens/network_monitor.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Portfolio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: appProvider.themeMode,
       initialRoute: HomeDashboard.routeName,
      routes: {
        HomeDashboard.routeName: (context) => const HomeDashboard(),
        ActivityScreen1.routeName: (context) => const ActivityScreen1(),
        ActivityScreen2.routeName: (context) => const ActivityScreen2(),
        NetworkMonitor.routeName: (context) => const NetworkMonitor(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }
}
