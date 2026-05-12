import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:curasync/config/api_config.dart';

/// Singleton service that manages a single Socket.IO connection.
/// Screens register callbacks; the service forwards events to them.
class SocketService {
  // ─── Singleton ───
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  // ─── Callbacks that screens can set ───
  void Function(Map<String, dynamic> data)? onQueueUpdated;
  void Function(Map<String, dynamic> data)? onPatientCalled;

  /// Connect to the Socket.IO server.
  /// Safe to call multiple times — will reuse existing connection.
  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('🔌 Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    _socket!.onConnectError((err) {
      print('⚠️ Socket connection error: $err');
    });

    // ─── Listen for backend events ───
    _socket!.on('queue_updated', (data) {
      print('📡 queue_updated: $data');
      if (data is Map<String, dynamic>) {
        onQueueUpdated?.call(data);
      } else {
        onQueueUpdated?.call({});
      }
    });

    _socket!.on('patient_called', (data) {
      print('🔔 patient_called: $data');
      if (data is Map<String, dynamic>) {
        onPatientCalled?.call(data);
      } else {
        onPatientCalled?.call({});
      }
    });

    _socket!.connect();
  }

  /// Disconnect cleanly.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    onQueueUpdated = null;
    onPatientCalled = null;
  }
}
