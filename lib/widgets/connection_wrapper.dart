// lib/widgets/connection_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_manager.dart';
import './connection_banner.dart';

class ConnectionWrapper extends StatelessWidget {
  final Widget child;
  final bool showBanner;
  
  const ConnectionWrapper({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionManager>(
      builder: (context, connectionManager, _) {
        return Column(
          children: [
            if (showBanner && connectionManager.status != ConnectionStatus.online)
              // ignore: prefer_const_constructors
              ConnectionBanner(),
            
            Expanded(child: child),
          ],
        );
      },
    );
  }
}