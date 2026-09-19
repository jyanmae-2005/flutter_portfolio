import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_diagnostic_provider.dart';
import '../utils/responsive.dart';

class NetworkDiagnosticScreen extends StatefulWidget {
  const NetworkDiagnosticScreen({super.key});

  static const routeName = '/diagnostic';

  @override
  State<NetworkDiagnosticScreen> createState() =>
      _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<NetworkDiagnosticProvider>(context, listen: false);
      provider.init();
      if (provider.autoStartDiagnostics) {
        provider.startPeriodicDiagnostics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NetworkDiagnosticProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostic'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        actions: [
          if (provider.isRunning)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
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
                _buildHealthStatus(context, provider),
                SizedBox(height: Responsive.padding(context)),
                _buildProgressBar(context, provider),
                SizedBox(height: Responsive.padding(context)),
                _buildMetricsGrid(context, provider),
                SizedBox(height: Responsive.padding(context)),
                _buildHistory(context, provider),
                SizedBox(height: Responsive.padding(context) * 2),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isRunning ? null : provider.runFullDiagnostics,
        icon: const Icon(Icons.speed),
        label: const Text('Run Diagnostics'),
      ),
    );
  }

  Widget _buildHealthStatus(BuildContext context, NetworkDiagnosticProvider provider) {
    final health = provider.health;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context)),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: provider.isRunning ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                if (provider.isRunning) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: health.color.withValues(alpha: 0.3 * value),
                    ),
                    child: Icon(
                      health.icon,
                      size: 48 + (12 * value),
                      color: health.color,
                    ),
                  );
                } else {
                  return Icon(
                    health.icon,
                    size: 64,
                    color: health.color,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              health.label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: health.color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.isRunning
                  ? 'Testing network...'
                  : provider.lastResult != null
                      ? 'Last checked ${_formatTimeAgo(provider.lastResult!.timestamp)}'
                      : 'Tap "Run Diagnostics" to begin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Widget _buildProgressBar(BuildContext context, NetworkDiagnosticProvider provider) {
    final currentStep = provider.step;
    final steps = NetworkDiagnosticProvider.stepCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Idle Ping',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: currentStep >= 1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              'Download',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: currentStep >= 2
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              'Upload',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: currentStep >= 3
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: currentStep / steps,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, NetworkDiagnosticProvider provider) {
    final isWide = !Responsive.isCompact(context);
    final gridCount = isWide ? 3 : 2;

    final metrics = [
      _MetricData(
        label: 'Idle Ping',
        value: '${provider.idlePingMs} ms',
        icon: Icons.speed,
        color: provider.health.color,
      ),
      _MetricData(
        label: 'Download',
        value: '${provider.downloadMbps.toStringAsFixed(1)} Mbps',
        icon: Icons.download,
        color: Colors.blue,
      ),
      _MetricData(
        label: 'Upload',
        value: '${provider.uploadMbps.toStringAsFixed(1)} Mbps',
        icon: Icons.upload,
        color: Colors.purple,
      ),
      _MetricData(
        label: 'DL Ping',
        value: '${provider.downloadPingMs} ms',
        icon: Icons.route,
        color: Colors.orange,
      ),
      _MetricData(
        label: 'UL Ping',
        value: '${provider.uploadPingMs} ms',
        icon: Icons.route,
        color: Colors.deepOrange,
      ),
      _MetricData(
        label: 'Packet Loss',
        value: '${provider.packetLoss.toStringAsFixed(1)}%',
        icon: Icons.wifi_protected_setup,
        color: provider.packetLoss > 5 ? Colors.red : Colors.green,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        crossAxisSpacing: Responsive.padding(context),
        mainAxisSpacing: Responsive.padding(context),
        childAspectRatio: 2.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(Responsive.padding(context) / 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(metric.icon, color: metric.color, size: 24),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  metric.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistory(BuildContext context, NetworkDiagnosticProvider provider) {
    final result = provider.lastResult;
    if (result == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(Responsive.padding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Latest Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildResultRow(context, 'Idle Ping', '${result.idlePingMs} ms'),
            _buildResultRow(context, 'Download Ping', '${result.downloadPingMs} ms'),
            _buildResultRow(context, 'Download Speed', '${result.downloadMbps.toStringAsFixed(2)} Mbps'),
            _buildResultRow(context, 'Upload Ping', '${result.uploadPingMs} ms'),
            _buildResultRow(context, 'Upload Speed', '${result.uploadMbps.toStringAsFixed(2)} Mbps'),
            _buildResultRow(context, 'Packet Loss', '${result.packetLoss.toStringAsFixed(1)}%'),
            _buildResultRow(context, 'Timestamp', _formatTimestamp(result.timestamp)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
