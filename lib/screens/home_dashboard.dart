import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/menu_card.dart';
import 'activity_screen1.dart';
import 'activity_screen2.dart';
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, appProvider),
                const SizedBox(height: 32),
                Text(
                  'Activities',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildMenuGrid(context),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Open Settings',
                  icon: Icons.settings,
                  onPressed: () {
                    Navigator.of(context).pushNamed(SettingsScreen.routeName);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Row(
      mainAxisAlignment:
          isWide ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Welcome, ${appProvider.userName}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: isWide ? TextAlign.left : TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        if (isWide) const SizedBox(width: 16),
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
    ];

    final isWide = MediaQuery.of(context).size.width > 800;
    final crossAxisCount = isWide ? 3 : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: constraints.maxWidth < 600 ? 1.0 : 1.2,
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
