import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({
    super.key,
    required this.deviceName,
    required this.subtitle,
    required this.onDisconnect,
    this.onSettings,
  });

  final String deviceName;
  final String subtitle;
  final VoidCallback onDisconnect;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardColor, AppTheme.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withAlpha(150),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onSettings != null)
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
              color: AppTheme.textSecondary,
              tooltip: 'TX characteristic',
            ),
          IconButton(
            onPressed: onDisconnect,
            icon: const Icon(Icons.bluetooth_disabled),
            color: AppTheme.errorColor,
            tooltip: 'Disconnect',
          ),
        ],
      ),
    );
  }
}
