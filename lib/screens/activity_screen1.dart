import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/responsive.dart';
import '../widgets/custom_button.dart';

class ActivityScreen1 extends StatefulWidget {
  const ActivityScreen1({super.key});

  static const routeName = '/activity1';

  @override
  State<ActivityScreen1> createState() => _ActivityScreen1State();
}

class _ActivityScreen1State extends State<ActivityScreen1> {
  int _selectedIndex = 0;
  final List<int> _items = [1, 2, 3, 4, 5];

  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity One'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
            vertical: Responsive.padding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'User: ${appProvider.userName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Pick a number',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? _buildWideLayout()
                    : _buildCompactList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Dashboard'),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildItemList(),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Card(
            elevation: 4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Selected: ${_items[_selectedIndex]}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Selected: ${_items[_selectedIndex]}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildItemList(),
      ],
    );
  }

  Widget _buildItemList() {
    return ListView.separated(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedIndex == index;
        return CustomButton(
          label: _items[index].toString(),
          icon: isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          onPressed: () => _selectItem(index),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
    );
  }
}
