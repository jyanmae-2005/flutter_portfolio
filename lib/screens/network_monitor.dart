import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_provider.dart';

class NetworkMonitor extends StatefulWidget {
  const NetworkMonitor({super.key});

  static const routeName = '/network';

  @override
  State<NetworkMonitor> createState() => _NetworkMonitorState();
}

class _NetworkMonitorState extends State<NetworkMonitor> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NetworkProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 24),
                _buildQueueCard(context),
                const SizedBox(height: 24),
                _buildStatsCard(context),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildActions(context),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final provider = Provider.of<NetworkProvider>(context);
    final status = provider.status;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: status.color(context).withValues(alpha: 0.2),
              child: Icon(
                status.icon,
                size: 48,
                color: status.color(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              status.label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: status.color(context),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isConnected
                  ? 'Connection stable'
                  : 'No active network connection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(BuildContext context) {
    final provider = Provider.of<NetworkProvider>(context);
    final queue = provider.queue;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request Queue',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (queue.isNotEmpty)
                  TextButton(
                    onPressed: provider.clearQueue,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (queue.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No pending requests',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final request = queue[index];
                  return ListTile(
                    leading: const Icon(Icons.queue, size: 32),
                    title: Text(request.endpoint),
                    subtitle: Text(
                      'Attempt ${request.attempt + 1} of ${NetworkProvider.maxRetries} • ${request.createdAt.hour.toString().padLeft(2, '0')}:${request.createdAt.minute.toString().padLeft(2, '0')}:${request.createdAt.second.toString().padLeft(2, '0')}',
                    ),
                    trailing: provider.isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
            if (provider.isSending) ...[
              const SizedBox(height: 12),
              Text(
                'Sending request...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final provider = Provider.of<NetworkProvider>(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildStatItem(
                  context,
                  value: provider.completedSuccess.toString(),
                  label: 'Succeeded',
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                _buildStatItem(
                  context,
                  value: provider.failedPermanently.toString(),
                  label: 'Failed',
                  color: Colors.red,
                  icon: Icons.error,
                ),
                _buildStatItem(
                  context,
                  value: provider.queueLength.toString(),
                  label: 'Queued',
                  color: Colors.orange,
                  icon: Icons.pending_actions,
                ),
                _buildStatItem(
                  context,
                  value: provider.totalProcessed.toString(),
                  label: 'Total',
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.analytics,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final provider = Provider.of<NetworkProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'simulate_request',
          onPressed: provider.isSending
              ? null
              : () {
                  provider.simulateRequest('/api/data/page${provider.totalProcessed + 1}');
                },
          icon: const Icon(Icons.send),
          label: const Text('Simulate Request'),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'handover',
          onPressed: provider.isConnected ? provider.simulateHandover : null,
          icon: const Icon(Icons.wifi_protected_setup),
          label: const Text('Simulate Handover'),
        ),
      ],
    );
  }
}
