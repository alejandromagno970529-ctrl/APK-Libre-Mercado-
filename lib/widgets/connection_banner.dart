// lib/widgets/connection_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_manager.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionManager>(
      builder: (context, connectionManager, child) {
        final status = connectionManager.status;
        
        // Solo mostrar banner si hay problemas de conexión
        if (!ConnectionStatusBanner.shouldShow(status)) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Material(
            color: _getBackgroundColor(status),
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _getIcon(status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getTitle(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_getSubtitle(status, connectionManager) != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getSubtitle(status, connectionManager)!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (status == ConnectionStatus.offline) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          connectionManager.forceCheck();
                        },
                        style: TextButton.styleFrom(
                          // ignore: deprecated_member_use
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return const Color(0xFFD32F2F); // Rojo
      case ConnectionStatus.checking:
        return const Color(0xFFF57C00); // Naranja
      case ConnectionStatus.unstable:
        return const Color(0xFFFFA000); // Amarillo oscuro
      case ConnectionStatus.online:
        return const Color(0xFF388E3C); // Verde
    }
  }

  Widget _getIcon(ConnectionStatus status) {
    IconData iconData;
    
    switch (status) {
      case ConnectionStatus.offline:
        iconData = Icons.wifi_off;
        break;
      case ConnectionStatus.checking:
        iconData = Icons.sync;
        break;
      case ConnectionStatus.unstable:
        iconData = Icons.signal_wifi_statusbar_connected_no_internet_4;
        break;
      case ConnectionStatus.online:
        iconData = Icons.wifi;
        break;
    }

    return status == ConnectionStatus.checking
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Icon(
            iconData,
            color: Colors.white,
            size: 20,
          );
  }

  String _getTitle(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return 'Sin conexión';
      case ConnectionStatus.checking:
        return 'Verificando conexión...';
      case ConnectionStatus.unstable:
        return 'Conexión inestable';
      case ConnectionStatus.online:
        return 'Conectado';
    }
  }

  String? _getSubtitle(ConnectionStatus status, ConnectionManager manager) {
    switch (status) {
      case ConnectionStatus.offline:
        final attempts = manager.reconnectAttempts;
        return attempts > 0 
            ? 'Reintentando... (intento $attempts/5)'
            : 'Verifica tu conexión a internet';
      case ConnectionStatus.checking:
        return 'Espera un momento...';
      case ConnectionStatus.unstable:
        return 'Algunos mensajes pueden tardar';
      case ConnectionStatus.online:
        return null;
    }
  }
}

/// Banner flotante alternativo (más discreto)
class ConnectionFloatingBanner extends StatelessWidget {
  const ConnectionFloatingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionManager>(
      builder: (context, connectionManager, child) {
        final status = connectionManager.status;
        
        if (!ConnectionStatusBanner.shouldShow(status)) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: ConnectionStatusBanner.shouldShow(status) ? 1.0 : 0.0,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _getIcon(status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ConnectionStatusBanner.getMessage(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (status == ConnectionStatus.offline)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        onPressed: () {
                          connectionManager.forceCheck();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return const Color(0xFFD32F2F);
      case ConnectionStatus.checking:
        return const Color(0xFFF57C00);
      case ConnectionStatus.unstable:
        return const Color(0xFFFFA000);
      case ConnectionStatus.online:
        return const Color(0xFF388E3C);
    }
  }

  Widget _getIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return const Icon(Icons.wifi_off, color: Colors.white, size: 20);
      case ConnectionStatus.checking:
        return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
      case ConnectionStatus.unstable:
        return const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4, 
                        color: Colors.white, size: 20);
      case ConnectionStatus.online:
        return const Icon(Icons.wifi, color: Colors.white, size: 20);
    }
  }
}

/// Indicador compacto para AppBar
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionManager>(
      builder: (context, connectionManager, child) {
        final status = connectionManager.status;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: _getBackgroundColor(status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBackgroundColor(status),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(status),
                size: 14,
                color: _getBackgroundColor(status),
              ),
              const SizedBox(width: 4),
              Text(
                connectionManager.getStatusText(),
                style: TextStyle(
                  color: _getBackgroundColor(status),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return const Color(0xFFD32F2F);
      case ConnectionStatus.checking:
        return const Color(0xFFF57C00);
      case ConnectionStatus.unstable:
        return const Color(0xFFFFA000);
      case ConnectionStatus.online:
        return const Color(0xFF388E3C);
    }
  }

  IconData _getIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.offline:
        return Icons.wifi_off;
      case ConnectionStatus.checking:
        return Icons.sync;
      case ConnectionStatus.unstable:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case ConnectionStatus.online:
        return Icons.wifi;
    }
  }
}