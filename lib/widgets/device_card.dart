import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.name,
    required this.id,
    required this.rssi,
    required this.onConnect,
    this.isConnecting = false,
    this.paired = false,
    this.showRssi = true,
  });

  final String name;
  final String id;
  final int rssi;
  final VoidCallback onConnect;
  final bool isConnecting;
  final bool paired;
  final bool showRssi;

  int get _signalBars {
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = showRssi ? '$id  ·  $rssi dBm' : id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardColor,
            AppTheme.cardColor.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnecting ? null : onConnect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    paired ? Icons.link_rounded : Icons.bluetooth,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary.withAlpha(180),
                              fontSize: 12,
                            ),
                      ),
                      if (paired) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Paired',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showRssi) _SignalBars(bars: _signalBars),
                const SizedBox(width: 12),
                if (isConnecting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Connect',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.bars});

  final int bars;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        final active = index < bars;
        return Container(
          width: 4,
          height: 6.0 + (index * 5),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.successColor
                : AppTheme.textSecondary.withAlpha(60),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
