import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class MeshMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isOwn;

  MeshMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isOwn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isOwn': isOwn,
      };

  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isOwn: json['isOwn'] as bool,
      );
}

class DiscoveredEndpoint {
  final String endpointId;
  final String name;
  final String serviceId;

  DiscoveredEndpoint({
    required this.endpointId,
    required this.name,
    required this.serviceId,
  });
}

class MeshChatProvider extends ChangeNotifier {
  static const String _serviceId = 'mesh-chat-local';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  final Nearby _nearby = Nearby();
  final String _localName;
  final String _localId;
  bool _isInitialized = false;
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final List<DiscoveredEndpoint> _discoveredEndpoints = [];
  final Map<String, String> _connectedEndpoints = {};
  final List<MeshMessage> _messages = [];

  final StreamController<List<DiscoveredEndpoint>> _discoveredController =
      StreamController.broadcast();
  final StreamController<MeshMessage> _messageController = StreamController.broadcast();
  final StreamController<String> _connectionStatusController = StreamController.broadcast();

  String get localName => _localName;
  String get localId => _localId;
  bool get isInitialized => _isInitialized;
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  List<DiscoveredEndpoint> get discoveredEndpoints => List.unmodifiable(_discoveredEndpoints);
  List<String> get connectedEndpointNames => _connectedEndpoints.values.toList();
  List<MeshMessage> get messages => List.unmodifiable(_messages);
  Stream<List<DiscoveredEndpoint>> get discoveredStream => _discoveredController.stream;
  Stream<MeshMessage> get messageStream => _messageController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

  MeshChatProvider({String? localName})
      : _localName = localName ?? 'User-${DateTime.now().millisecondsSinceEpoch % 10000}',
        _localId = 'id-${DateTime.now().millisecondsSinceEpoch}';

  /// Request required runtime permissions
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    for (final status in statuses.values) {
      if (!status.isGranted) {
        debugPrint('Permission denied: $status');
        _connectionStatusController.add('Permission denied - cannot start chat');
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    final granted = await requestPermissions();
    if (!granted) {
      _isInitialized = false;
      return;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising || !_isInitialized) return;
    try {
      final result = await _nearby.startAdvertising(
        _localName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      if (result) {
        _isAdvertising = true;
        _connectionStatusController.add('Advertising as $_localName');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Advertising error: $e');
      _connectionStatusController.add('Advertising failed: $e');
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await _nearby.stopAdvertising();
      _isAdvertising = false;
      _connectionStatusController.add('Stopped advertising');
      notifyListeners();
    } catch (e) {
      debugPrint('Stop advertising error: $e');
    }
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering || !_isInitialized) return;
    try {
      _discoveredEndpoints.clear();
      _discoveredController.add(List.unmodifiable(_discoveredEndpoints));
      final result = await _nearby.startDiscovery(
        _localName,
        _strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
      if (result) {
        _isDiscovering = true;
        _connectionStatusController.add('Discovering nearby devices...');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Discovery error: $e');
      _connectionStatusController.add('Discovery failed: $e');
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    try {
      await _nearby.stopDiscovery();
      _isDiscovering = false;
      _connectionStatusController.add('Stopped discovery');
      notifyListeners();
    } catch (e) {
      debugPrint('Stop discovery error: $e');
    }
  }

  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    final discovered = DiscoveredEndpoint(
      endpointId: endpointId,
      name: endpointName,
      serviceId: serviceId,
    );
    if (!_discoveredEndpoints.any((e) => e.endpointId == discovered.endpointId)) {
      _discoveredEndpoints.add(discovered);
      _discoveredController.add(List.unmodifiable(_discoveredEndpoints));
      notifyListeners();
    }
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId != null) {
      _discoveredEndpoints.removeWhere((e) => e.endpointId == endpointId);
      _discoveredController.add(List.unmodifiable(_discoveredEndpoints));
      notifyListeners();
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
    );
    _connectionStatusController.add('Connecting to ${info.endpointName}...');
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      final endpointName = _discoveredEndpoints
          .firstWhere(
            (e) => e.endpointId == endpointId,
            orElse: () => DiscoveredEndpoint(
              endpointId: endpointId,
              name: 'Unknown',
              serviceId: '',
            ),
          )
          .name;
      _connectedEndpoints[endpointId] = endpointName;
      _connectionStatusController.add('Connected to $endpointName');
      notifyListeners();
    } else {
      _connectionStatusController.add('Connection failed: $status');
    }
  }

  void _onDisconnected(String endpointId) {
    final name = _connectedEndpoints.remove(endpointId) ?? 'Unknown';
    _connectionStatusController.add('Disconnected from $name');
    notifyListeners();
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    try {
      final bytes = payload.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        final jsonString = utf8.decode(bytes);
        final data = json.decode(jsonString);
        final message = MeshMessage.fromJson(data);
        _messages.add(message);
        _messageController.add(message);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Payload decode error: $e');
    }
  }

  Future<void> connectToEndpoint(DiscoveredEndpoint endpoint) async {
    try {
      _connectionStatusController.add('Connecting to ${endpoint.name}...');
      await _nearby.requestConnection(
        _localName,
        endpoint.endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      debugPrint('Connection request error: $e');
      _connectionStatusController.add('Connection request failed: $e');
    }
  }

  Future<void> disconnectFromEndpoint(String endpointId) async {
    try {
      await _nearby.disconnectFromEndpoint(endpointId);
      _onDisconnected(endpointId);
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final message = MeshMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: _localId,
      senderName: _localName,
      text: text.trim(),
      timestamp: DateTime.now(),
      isOwn: true,
    );

    _messages.add(message);
    _messageController.add(message);
    notifyListeners();

    final jsonString = json.encode(message.toJson());
    final bytes = utf8.encode(jsonString);

    for (final endpointId in _connectedEndpoints.keys) {
      try {
        await _nearby.sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('Send to $endpointId failed: $e');
      }
    }
  }

  Future<void> clearMessages() async {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopAdvertising();
    stopDiscovery();
    for (final endpointId in _connectedEndpoints.keys) {
      _nearby.disconnectFromEndpoint(endpointId);
    }
    _discoveredController.close();
    _messageController.close();
    _connectionStatusController.close();
    _nearby.stopAllEndpoints();
    super.dispose();
  }
}