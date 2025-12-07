// lib/services/connection_manager.dart - VERSIÓN CORREGIDA
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

enum ConnectionStatus {
  online,
  offline,
  checking,
  unstable,
}

enum ConnectionQuality {
  excellent,
  good,
  poor,
  none,
}

class ConnectionManager extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  ConnectionStatus _status = ConnectionStatus.checking;
  ConnectionQuality _quality = ConnectionQuality.none;
  DateTime? _lastOnlineTime;
  DateTime? _lastStatusChange;
  int _reconnectAttempts = 0;
  Timer? _qualityCheckTimer;
  Timer? _reconnectTimer;
  
  final List<Function(ConnectionStatus)> _statusListeners = [];
  final List<Function()> _onlineCallbacks = [];
  final List<Function()> _offlineCallbacks = [];

  static const Duration qualityCheckInterval = Duration(seconds: 10);
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;

  ConnectionManager() {
    _initialize();
  }

  // Getters
  ConnectionStatus get status => _status;
  ConnectionQuality get quality => _quality;
  bool get isOnline => _status == ConnectionStatus.online;
  bool get isOffline => _status == ConnectionStatus.offline;
  bool get isChecking => _status == ConnectionStatus.checking;
  bool get isUnstable => _status == ConnectionStatus.unstable;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  int get reconnectAttempts => _reconnectAttempts;

  Future<void> _initialize() async {
    try {
      await checkConnection();
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          AppLogger.e('❌ Error en stream de conectividad: $error');
        },
      );
      
      _startQualityMonitoring();
      AppLogger.d('✅ ConnectionManager inicializado');
    } catch (e) {
      AppLogger.e('❌ Error inicializando ConnectionManager: $e');
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    AppLogger.d('🔄 Cambio de conectividad detectado: $result');
    
    if (result == ConnectivityResult.none) {
      _updateStatus(ConnectionStatus.offline);
    } else {
      checkConnection();
    }
  }

  Future<bool> checkConnection() async {
    try {
      _updateStatus(ConnectionStatus.checking);
      
      final result = await _connectivity.checkConnectivity();
      
      if (result == ConnectivityResult.none) {
        _updateStatus(ConnectionStatus.offline);
        return false;
      }
      
      // Simular verificación de conexión real
      await Future.delayed(const Duration(milliseconds: 500));
      
      _updateStatus(ConnectionStatus.online);
      _lastOnlineTime = DateTime.now();
      _reconnectAttempts = 0;
      
      return true;
    } catch (e) {
      AppLogger.e('❌ Error verificando conexión: $e');
      _updateStatus(ConnectionStatus.offline);
      return false;
    }
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      final oldStatus = _status;
      _status = newStatus;
      _lastStatusChange = DateTime.now();
      
      AppLogger.d('🔄 Estado de conexión: $oldStatus → $newStatus');
      notifyListeners();
      
      for (final listener in _statusListeners) {
        listener(newStatus);
      }
      
      if (newStatus == ConnectionStatus.online) {
        for (final callback in _onlineCallbacks) {
          callback();
        }
      } else if (newStatus == ConnectionStatus.offline) {
        for (final callback in _offlineCallbacks) {
          callback();
        }
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      AppLogger.w('⚠️ Máximo de intentos de reconexión alcanzado');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectInterval, () async {
      _reconnectAttempts++;
      AppLogger.d('🔄 Intento de reconexión #$_reconnectAttempts');
      
      final connected = await checkConnection();
      if (!connected && _reconnectAttempts < maxReconnectAttempts) {
        _scheduleReconnect();
      }
    });
  }

  void _startQualityMonitoring() {
    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = Timer.periodic(qualityCheckInterval, (_) {
      if (isOnline) {
        _checkConnectionQuality();
      }
    });
  }

  Future<void> _checkConnectionQuality() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      ConnectionQuality newQuality;
      
      if (result == ConnectivityResult.wifi) {
        newQuality = ConnectionQuality.excellent;
      } else if (result == ConnectivityResult.mobile) {
        newQuality = ConnectionQuality.good;
      } else if (result == ConnectivityResult.ethernet) {
        newQuality = ConnectionQuality.excellent;
      } else {
        newQuality = ConnectionQuality.none;
      }
      
      if (_quality != newQuality) {
        _quality = newQuality;
        AppLogger.d('📊 Calidad de conexión: $newQuality');
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('❌ Error verificando calidad: $e');
      _quality = ConnectionQuality.poor;
      notifyListeners();
    }
  }

  void addStatusListener(Function(ConnectionStatus) listener) {
    _statusListeners.add(listener);
  }

  void removeStatusListener(Function(ConnectionStatus) listener) {
    _statusListeners.remove(listener);
  }

  void addOnlineCallback(Function() callback) {
    _onlineCallbacks.add(callback);
  }

  void addOfflineCallback(Function() callback) {
    _offlineCallbacks.add(callback);
  }

  Future<Map<String, dynamic>> getConnectionInfo() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      return {
        'status': _status.toString(),
        'quality': _quality.toString(),
        'connectivity_result': result.toString(),
        'is_online': isOnline,
        'last_online': _lastOnlineTime?.toIso8601String(),
        'last_status_change': _lastStatusChange?.toIso8601String(),
        'reconnect_attempts': _reconnectAttempts,
      };
    } catch (e) {
      AppLogger.e('❌ Error obteniendo info de conexión: $e');
      return {
        'error': e.toString(),
        'status': _status.toString(),
      };
    }
  }

  String getStatusText() {
    switch (_status) {
      case ConnectionStatus.online:
        return 'En línea';
      case ConnectionStatus.offline:
        return 'Sin conexión';
      case ConnectionStatus.checking:
        return 'Verificando...';
      case ConnectionStatus.unstable:
        return 'Conexión inestable';
    }
  }

  String getQualityText() {
    switch (_quality) {
      case ConnectionQuality.excellent:
        return 'Excelente';
      case ConnectionQuality.good:
        return 'Buena';
      case ConnectionQuality.poor:
        return 'Pobre';
      case ConnectionQuality.none:
        return 'Sin conexión';
    }
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    AppLogger.d('🔄 Contador de reconexiones reiniciado');
  }

  Future<void> forceCheck() async {
    AppLogger.d('🔍 Forzando verificación de conexión...');
    await checkConnection();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _qualityCheckTimer?.cancel();
    _reconnectTimer?.cancel();
    _statusListeners.clear();
    _onlineCallbacks.clear();
    _offlineCallbacks.clear();
    super.dispose();
  }

  void initialize() {}
}

class ConnectionStatusBanner {
  static String getMessage(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.online:
        return 'Conectado';
      case ConnectionStatus.offline:
        return 'Sin conexión a internet';
      case ConnectionStatus.checking:
        return 'Verificando conexión...';
      case ConnectionStatus.unstable:
        return 'Conexión inestable';
    }
  }

  static bool shouldShow(ConnectionStatus status) {
    return status == ConnectionStatus.offline || 
           status == ConnectionStatus.unstable ||
           status == ConnectionStatus.checking;
  }
}