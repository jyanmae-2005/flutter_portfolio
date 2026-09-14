import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_button.dart';

class ActivityScreen2 extends StatefulWidget {
  const ActivityScreen2({super.key});

  static const routeName = '/activity2';

  @override
  State<ActivityScreen2> createState() => _ActivityScreen2State();
}

class _ActivityScreen2State extends State<ActivityScreen2> {
  final TextEditingController _controller = TextEditingController(
    text: 'Hello World! Tap to edit.',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Two'),
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'User: ${appProvider.userName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Edit Text',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _controller,
                              maxLines: 4,
                              expands: false,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: 'Type something...',
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              label: 'Show Snackbar',
                              icon: Icons.info,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_controller.text),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isWide) const SizedBox(height: 80),
              ],
            );
          },
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
}
