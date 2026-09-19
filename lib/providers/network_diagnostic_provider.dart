import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum ConnectionHealth { unknown, excellent, fair, poor, degraded }

extension ConnectionHealthExtension on ConnectionHealth {
  String get label {
    switch (this) {
      case ConnectionHealth.excellent:
        return 'Excellent';
      case ConnectionHealth.fair:
        return 'Fair';
      case ConnectionHealth.poor:
        return 'Poor';
      case ConnectionHealth.degraded:
        return 'Degraded';
      case ConnectionHealth.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionHealth.excellent:
        return Icons.signal_cellular_alt;
      case ConnectionHealth.fair:
        return Icons.wifi;
      case ConnectionHealth.poor:
        return Icons.signal_cellular_null;
      case ConnectionHealth.degraded:
        return Icons.error;
      case ConnectionHealth.unknown:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case ConnectionHealth.excellent:
        return Colors.green;
      case ConnectionHealth.fair:
        return Colors.orange;
      case ConnectionHealth.poor:
        return Colors.red;
      case ConnectionHealth.degraded:
        return Colors.deepOrange;
      case ConnectionHealth.unknown:
        return Colors.grey;
    }
  }
}

class DiagnosticResult {
  final int idlePingMs;
  final int downloadPingMs;
  final double downloadMbps;
  final int uploadPingMs;
  final double uploadMbps;
  final double packetLoss;
  final DateTime timestamp;

  DiagnosticResult({
    required this.idlePingMs,
    required this.downloadPingMs,
    required this.downloadMbps,
    required this.uploadPingMs,
    required this.uploadMbps,
    required this.packetLoss,
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now();

  DiagnosticResult copyWith({
    int? idlePingMs,
    int? downloadPingMs,
    double? downloadMbps,
    int? uploadPingMs,
    double? uploadMbps,
    double? packetLoss,
  }) {
    return DiagnosticResult(
      idlePingMs: idlePingMs ?? this.idlePingMs,
      downloadPingMs: downloadPingMs ?? this.downloadPingMs,
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadPingMs: uploadPingMs ?? this.uploadPingMs,
      uploadMbps: uploadMbps ?? this.uploadMbps,
      packetLoss: packetLoss ?? this.packetLoss,
      timestamp: timestamp,
    );
  }
}

class NetworkDiagnosticProvider with ChangeNotifier {
  static const _testUrl = 'https://httpbin.org/get';
  static const _downloadUrl = 'https://httpbin.org/bytes/50000';
  static const _uploadUrl = 'https://httpbin.org/post';
  static const _requestTimeout = Duration(seconds: 10);
  static const _diagnosticInterval = Duration(seconds: 30);
  static const _pingCount = 5;
  bool _initialized = false;
  final bool autoStartDiagnostics;
  Timer? _timer;

  NetworkDiagnosticProvider({this.autoStartDiagnostics = true});

  void init() {
    _initialized = true;
  }

  void startPeriodicDiagnostics() {
    if (!_initialized) {
      _initialized = true;
    }
    _startPeriodicDiagnostics();
  }

  void _startPeriodicDiagnostics() {
    _timer?.cancel();
    _timer = Timer.periodic(_diagnosticInterval, (_) {
      if (_isIdle) {
        runFullDiagnostics();
      }
    });
  }

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  bool _isIdle = true;
  bool get isIdle => _isIdle;

  ConnectionHealth _health = ConnectionHealth.unknown;
  ConnectionHealth get health => _health;

  DiagnosticResult? _lastResult;
  DiagnosticResult? get lastResult => _lastResult;

  double _downloadMbps = 0;
  double get downloadMbps => _downloadMbps;

  double _uploadMbps = 0;
  double get uploadMbps => _uploadMbps;

  int _idlePingMs = 0;
  int get idlePingMs => _idlePingMs;

  int _downloadPingMs = 0;
  int get downloadPingMs => _downloadPingMs;

  int _uploadPingMs = 0;
  int get uploadPingMs => _uploadPingMs;

  double _packetLoss = 0;
  double get packetLoss => _packetLoss;

  int _step = 0;
  int get step => _step;

  static const int stepCount = 3;

  Future<void> runFullDiagnostics() async {
    if (_isRunning) return;
    _isRunning = true;
    _isIdle = false;
    notifyListeners();

    try {
      final idlePing = await _measureIdlePing();
      _step = 1;
      notifyListeners();

      final downloadResult = await _measureDownloadBandwidth();
      _step = 2;
      notifyListeners();

      final uploadResult = await _measureUploadBandwidth();
      _step = 3;
      notifyListeners();

      final effectivePacketLoss = (idlePing.packetLoss +
              downloadResult.packetLoss +
              uploadResult.packetLoss) /
          3;

      final result = DiagnosticResult(
        idlePingMs: idlePing.pingMs,
        downloadPingMs: downloadResult.pingMs,
        downloadMbps: downloadResult.mbps,
        uploadPingMs: uploadResult.pingMs,
        uploadMbps: uploadResult.mbps,
        packetLoss: effectivePacketLoss,
      );

      _lastResult = result;
      _idlePingMs = result.idlePingMs;
      _downloadPingMs = result.downloadPingMs;
      _downloadMbps = result.downloadMbps;
      _uploadPingMs = result.uploadPingMs;
      _uploadMbps = result.uploadMbps;
      _packetLoss = result.packetLoss;

      _health = _categorizeHealth(result);
      notifyListeners();
    } catch (e) {
      _health = ConnectionHealth.unknown;
      notifyListeners();
    } finally {
      _isRunning = false;
      _isIdle = true;
      _step = 0;
      notifyListeners();
    }
  }

  Future<_PingResult> _measureIdlePing() async {
    int successCount = 0;
    int failCount = 0;
    int totalPing = 0;

    for (int i = 0; i < _pingCount; i++) {
      try {
        final sw = Stopwatch()..start();
        final response = await http
            .get(Uri.parse(_testUrl))
            .timeout(_requestTimeout);
        sw.stop();

        if (response.statusCode == 200) {
          successCount++;
          totalPing += sw.elapsedMilliseconds;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    final totalRequests = successCount + failCount;
    final packetLoss = totalRequests > 0
        ? (failCount / totalRequests) * 100
        : 100.0;
    final avgPing =
        successCount > 0 ? (totalPing / successCount).round() : 9999;

    return _PingResult(
      pingMs: avgPing,
      packetLoss: packetLoss,
      successRate: successCount / _pingCount,
    );
  }

  Future<_BandwidthResult> _measureDownloadBandwidth() async {
    int dataReceived = 0;
    int successCount = 0;
    int failCount = 0;
    int totalPing = 0;

    for (int i = 0; i < _pingCount; i++) {
      try {
        final sw = Stopwatch()..start();
        final response = await http
            .get(Uri.parse(_downloadUrl))
            .timeout(_requestTimeout);
        sw.stop();

        if (response.statusCode == 200) {
          successCount++;
          dataReceived += response.bodyBytes.length;
          totalPing += sw.elapsedMilliseconds;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }

      final pingSw = Stopwatch()..start();
      try {
        await http.get(Uri.parse(_testUrl)).timeout(_requestTimeout);
        pingSw.stop();
        totalPing += pingSw.elapsedMilliseconds;
      } catch (_) {
        pingSw.stop();
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }

    final totalRequests = successCount + failCount;
    final packetLoss = totalRequests > 0
        ? (failCount / totalRequests) * 100
        : 100.0;

    final totalTimeSeconds = _pingCount * 2;
    final totalBytes = dataReceived.toDouble();
    final bitsPerSecond = (totalBytes * 8) / totalTimeSeconds;
    final mbps = bitsPerSecond / (1024 * 1024);

    final avgPing = successCount > 0
        ? (totalPing / (successCount * 2)).round()
        : 9999;

    return _BandwidthResult(
      mbps: mbps,
      pingMs: avgPing,
      packetLoss: packetLoss,
    );
  }

  Future<_BandwidthResult> _measureUploadBandwidth() async {
    const int uploadSizeBytes = 10000;
    final uploadData = List<int>.filled(uploadSizeBytes, 0);
    int totalUploaded = 0;
    int successCount = 0;
    int failCount = 0;
    int totalPing = 0;

    for (int i = 0; i < _pingCount; i++) {
      try {
        final sw = Stopwatch()..start();
        final response = await http
            .post(
              Uri.parse(_uploadUrl),
              body: uploadData,
            )
            .timeout(_requestTimeout);
        sw.stop();

        if (response.statusCode == 200 || response.statusCode == 201) {
          successCount++;
          totalUploaded += uploadSizeBytes;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }

      final pingSw = Stopwatch()..start();
      try {
        await http.get(Uri.parse(_testUrl)).timeout(_requestTimeout);
        pingSw.stop();
        totalPing += pingSw.elapsedMilliseconds;
      } catch (_) {
        pingSw.stop();
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }

    final totalRequests = successCount + failCount;
    final packetLoss = totalRequests > 0
        ? (failCount / totalRequests) * 100
        : 100.0;

    final totalTimeSeconds = _pingCount * 2;
    final totalBits = totalUploaded * 8;
    final bitsPerSecond = totalBits / totalTimeSeconds;
    final mbps = bitsPerSecond / (1024 * 1024);

    final avgPing = successCount > 0
        ? (totalPing / (successCount * 2)).round()
        : 9999;

    return _BandwidthResult(
      mbps: mbps,
      pingMs: avgPing,
      packetLoss: packetLoss,
    );
  }

  ConnectionHealth _categorizeHealth(DiagnosticResult result) {
    final maxBandwidth =
        result.downloadMbps > result.uploadMbps
            ? result.downloadMbps
            : result.uploadMbps;
    final avgPing = (result.idlePingMs +
            result.downloadPingMs +
            result.uploadPingMs) /
        3;

    if (result.packetLoss > 15 || avgPing > 300) {
      return ConnectionHealth.degraded;
    }

    if (maxBandwidth > 10 && avgPing < 50 && result.packetLoss < 1) {
      return ConnectionHealth.excellent;
    }

    if (maxBandwidth >= 2 && avgPing <= 100 && result.packetLoss <= 5) {
      return ConnectionHealth.fair;
    }

    if (maxBandwidth < 2 && avgPing > 100 && result.packetLoss > 5) {
      return ConnectionHealth.poor;
    }

    if (result.packetLoss > 10 || avgPing > 200) {
      return ConnectionHealth.degraded;
    }

    return ConnectionHealth.poor;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

class _PingResult {
  final int pingMs;
  final double packetLoss;
  final double successRate;

  _PingResult({
    required this.pingMs,
    required this.packetLoss,
    required this.successRate,
  });
}

class _BandwidthResult {
  final double mbps;
  final int pingMs;
  final double packetLoss;

  _BandwidthResult({
    required this.mbps,
    required this.pingMs,
    required this.packetLoss,
  });
}
