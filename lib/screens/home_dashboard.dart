import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/responsive.dart';
import '../widgets/custom_button.dart';
import '../widgets/menu_card.dart';
import 'activity_screen1.dart';
import 'activity_screen2.dart';
import 'network_monitor.dart';
import 'network_diagnostic_screen.dart';
import 'settings_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: Responsive.padding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, appProvider),
                const SizedBox(height: 32),
                if (!Responsive.isCompact(context))
                  Align(
                    alignment: Responsive.isExpanded(context)
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: Text(
                      'Activities',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  )
                else
                  Text(
                    'Activities',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                _buildMenuGrid(context),
                SizedBox(height: Responsive.padding(context)),
                CustomButton(
                  label: 'Open Settings',
                  icon: Icons.settings,
                  onPressed: () {
                    Navigator.of(context).pushNamed(SettingsScreen.routeName);
                  },
                ),
                SizedBox(height: Responsive.padding(context) * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider) {
    final isCompact = Responsive.isCompact(context);
    final isWide = !isCompact;

    return Row(
      mainAxisAlignment:
          isWide ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Welcome, ${appProvider.userName}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: (Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.fontSize ??
                      24) *
                    Responsive.fontSizeMultiplier(context),
                ),
            textAlign: isWide ? TextAlign.left : TextAlign.center,
          ),
        ),
        if (isWide) SizedBox(height: Responsive.padding(context) * 1.5),
        if (isWide) SizedBox(width: Responsive.padding(context)),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              appProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          label: Text(appProvider.isDarkMode ? 'Dark' : 'Light'),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final items = [
      _MenuItemData(
        title: 'Activity One',
        subtitle: 'Explore the first activity',
        icon: Icons.flight,
        route: ActivityScreen1.routeName,
      ),
      _MenuItemData(
        title: 'Activity Two',
        subtitle: 'Explore the second activity',
        icon: Icons.school,
        route: ActivityScreen2.routeName,
      ),
      _MenuItemData(
        title: 'Network Monitor',
        subtitle: 'Monitor network and request queue',
        icon: Icons.network_check,
        route: NetworkMonitor.routeName,
      ),
      _MenuItemData(
        title: 'Network Diagnostic',
        subtitle: 'Measure speed and connection health',
        icon: Icons.speed,
        route: NetworkDiagnosticScreen.routeName,
      ),
    ];

    final crossAxisCount = Responsive.gridCrossAxisCount(context).toInt();
    final aspectRatio = Responsive.cardAspectRatio(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: Responsive.padding(context),
                mainAxisSpacing: Responsive.padding(context),
                childAspectRatio: aspectRatio,
              ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MenuCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              onTap: () {
                Navigator.of(context).pushNamed(item.route);
              },
            );
          },
        );
      },
    );
  }
}

class _MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  _MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
