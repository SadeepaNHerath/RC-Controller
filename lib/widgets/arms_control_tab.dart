import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../commands/rc_commands.dart';
import '../theme/app_theme.dart';
import 'arm_control_button.dart';
import 'arm_position_indicator.dart';

class ArmsControlTab extends StatefulWidget {
  const ArmsControlTab({
    super.key,
    required this.onCommand,
  });

  final Future<void> Function(String command) onCommand;

  @override
  State<ArmsControlTab> createState() => _ArmsControlTabState();
}

class _ArmsControlTabState extends State<ArmsControlTab> {
  final List<double> _positions = [0, 0, 0, 0];
  Timer? _motionTimer;
  List<int> _activeArms = [];
  int _direction = 0;

  @override
  void dispose() {
    _motionTimer?.cancel();
    super.dispose();
  }

  Future<void> _send(String command) async {
    HapticFeedback.lightImpact();
    await widget.onCommand(command);
  }

  void _beginMotion(List<int> arms, int direction) {
    _motionTimer?.cancel();
    _activeArms = arms;
    _direction = direction;
    _tickMotion();
    _motionTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => _tickMotion(),
    );
  }

  void _tickMotion() {
    if (!mounted) return;
    setState(() {
      for (final index in _activeArms) {
        _positions[index] =
            (_positions[index] + (_direction * 0.04)).clamp(0.0, 1.0);
      }
    });
  }

  Future<void> _endMotion(List<String> stopCommands) async {
    _motionTimer?.cancel();
    _motionTimer = null;
    for (final command in stopCommands) {
      await _send(command);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'ARM CONTROLS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _buildGroupControls(),
          const SizedBox(height: 32),
          const Text(
            'INDIVIDUAL CONTROLS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 4; i++)
                ArmPositionIndicator(
                  label: 'ARM ${i + 1}',
                  position: _positions[i],
                  color: i < 2 ? AppTheme.primaryColor : AppTheme.accentColor,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 4; i++)
                ArmControlButton(
                  label: 'ARM ${i + 1}',
                  upIcon: Icons.arrow_upward_rounded,
                  downIcon: Icons.arrow_downward_rounded,
                  onUp: () {
                    _beginMotion([i], 1);
                    _send([
                      RcCommands.arm1Up,
                      RcCommands.arm2Up,
                      RcCommands.arm3Up,
                      RcCommands.arm4Up,
                    ][i]);
                  },
                  onDown: () {
                    _beginMotion([i], -1);
                    _send([
                      RcCommands.arm1Down,
                      RcCommands.arm2Down,
                      RcCommands.arm3Down,
                      RcCommands.arm4Down,
                    ][i]);
                  },
                  onRelease: () => _endMotion([
                    [
                      RcCommands.arm1Stop,
                      RcCommands.arm2Stop,
                      RcCommands.arm3Stop,
                      RcCommands.arm4Stop,
                    ][i]
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Hold to move. Release to stop. Indicators are estimated.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardColor, AppTheme.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GROUP CONTROLS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildGroupButton(
                label: 'FRONT ARMS',
                sublabel: 'Arms 1 & 2',
                upCommand: RcCommands.frontUp,
                downCommand: RcCommands.frontDown,
                armIndexes: const [0, 1],
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              _buildGroupButton(
                label: 'BACK ARMS',
                sublabel: 'Arms 3 & 4',
                upCommand: RcCommands.backUp,
                downCommand: RcCommands.backDown,
                armIndexes: const [2, 3],
                color: AppTheme.accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupButton({
    required String label,
    required String sublabel,
    required String upCommand,
    required String downCommand,
    required List<int> armIndexes,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _holdButton(
                  icon: Icons.arrow_upward_rounded,
                  color: color,
                  onDown: () {
                    _beginMotion(armIndexes, 1);
                    _send(upCommand);
                  },
                  onUp: () =>
                      _endMotion(RcCommands.groupReleaseStops(upCommand)),
                ),
                _holdButton(
                  icon: Icons.arrow_downward_rounded,
                  color: color.withAlpha(200),
                  onDown: () {
                    _beginMotion(armIndexes, -1);
                    _send(downCommand);
                  },
                  onUp: () =>
                      _endMotion(RcCommands.groupReleaseStops(downCommand)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _holdButton({
    required IconData icon,
    required Color color,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withAlpha(200)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
