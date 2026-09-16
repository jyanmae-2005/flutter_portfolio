import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum NetworkStatus { unknown, checking, wifi, cellular, offline }

extension NetworkStatusExtension on NetworkStatus {
  String get label {
    switch (this) {
      case NetworkStatus.wifi:
        return 'Wi-Fi';
      case NetworkStatus.cellular:
        return 'Cellular';
      case NetworkStatus.offline:
        return 'Offline';
      case NetworkStatus.checking:
        return 'Checking...';
      case NetworkStatus.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.cellular:
        return Icons.cell_tower;
      case NetworkStatus.offline:
        return Icons.wifi_off;
      case NetworkStatus.checking:
        return Icons.refresh;
      case NetworkStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.cellular:
        return Colors.blue;
      case NetworkStatus.offline:
        return Colors.red;
      case NetworkStatus.checking:
      case NetworkStatus.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

class QueuedRequest {
  final String id;
  final String endpoint;
  final int attempt;
  final DateTime createdAt;

  QueuedRequest({
    required this.id,
    required this.endpoint,
    this.attempt = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QueuedRequest copyWith({int? attempt}) {
    return QueuedRequest(
      id: id,
      endpoint: endpoint,
      attempt: attempt ?? this.attempt,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'QueuedRequest($endpoint, attempt=$attempt)';
}

class NetworkProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  NetworkStatus _status = NetworkStatus.unknown;
  final List<QueuedRequest> _queue = [];
  bool _isSending = false;
  int _completedSuccess = 0;
  int _failedPermanently = 0;
  final _random = Random();
  Timer? _handoverTimer;

  static const maxRetries = 3;

  NetworkStatus get status => _status;
  bool get isConnected =>
      _status == NetworkStatus.wifi || _status == NetworkStatus.cellular;

  bool _isStatusConnected(NetworkStatus status) =>
      status == NetworkStatus.wifi || status == NetworkStatus.cellular;
  List<QueuedRequest> get queue => List.unmodifiable(_queue);
  int get queueLength => _queue.length;
  bool get isSending => _isSending;
  int get completedSuccess => _completedSuccess;
  int get failedPermanently => _failedPermanently;
  int get totalProcessed => _completedSuccess + _failedPermanently;

  bool _initialized = false;

  NetworkProvider();

  void init() {
    if (_initialized) return;
    _initialized = true;
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _checkConnectivity() async {
    _setStatus(NetworkStatus.checking);
    final results = await _connectivity.checkConnectivity();
    _processConnectivity(results);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    _processConnectivity(result);
  }

  void _processConnectivity(ConnectivityResult result) {
    NetworkStatus newStatus;
    if (result == ConnectivityResult.none) {
      newStatus = NetworkStatus.offline;
    } else if (result == ConnectivityResult.wifi) {
      newStatus = NetworkStatus.wifi;
    } else if (result == ConnectivityResult.ethernet) {
      newStatus = NetworkStatus.wifi;
    } else if (result == ConnectivityResult.mobile) {
      newStatus = NetworkStatus.cellular;
    } else {
      newStatus = NetworkStatus.unknown;
    }

    final becameConnected =
        !_isStatusConnected(_status) && _isStatusConnected(newStatus);
    _setStatus(newStatus);

    if (becameConnected) {
      _flushQueue();
    }
  }

  void _setStatus(NetworkStatus newStatus) {
    if (newStatus != _status) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<void> simulateRequest(String endpoint) async {
    final request = QueuedRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      endpoint: endpoint,
    );

    if (!isConnected) {
      _queueRequest(request);
      return;
    }

    _isSending = true;
    notifyListeners();

    try {
      await _performRequest(request);
      _completedSuccess++;
      notifyListeners();
    } catch (e) {
      if (request.attempt < maxRetries) {
        _queueRequest(request.copyWith(attempt: request.attempt + 1));
      } else {
        _failedPermanently++;
        notifyListeners();
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void _queueRequest(QueuedRequest request) {
    _queue.add(request);
    notifyListeners();
  }

  Future<void> _performRequest(QueuedRequest request) async {
    final shouldFail = _random.nextDouble() < 0.3 && _status == NetworkStatus.cellular;

    if (!isConnected || shouldFail) {
      throw Exception('Network handover / connection lost during request to ${request.endpoint}');
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _flushQueue() async {
    if (_queue.isEmpty || _isSending) return;

    while (_queue.isNotEmpty) {
      final request = _queue.removeAt(0);
      notifyListeners();

      try {
        await _performRequest(request);
        _completedSuccess++;
        notifyListeners();
      } catch (e) {
        if (request.attempt < maxRetries) {
          _queueRequest(request.copyWith(attempt: request.attempt + 1));
        } else {
          _failedPermanently++;
          notifyListeners();
        }
      }
    }
  }

  void simulateHandover() {
    if (!isConnected) return;

    _handoverTimer?.cancel();
    _handoverTimer = Timer(const Duration(milliseconds: 800), () {
      final previousStatus = _status;
      _setStatus(NetworkStatus.offline);

      if (_isSending) {
        _isSending = false;
      }

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (previousStatus == NetworkStatus.wifi) {
          _setStatus(NetworkStatus.cellular);
        } else {
          _setStatus(NetworkStatus.wifi);
        }
        _flushQueue();
      });

      notifyListeners();
    });
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _handoverTimer?.cancel();
    super.dispose();
  }
}
