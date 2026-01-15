import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/arm_control_button.dart';
import '../widgets/arm_position_indicator.dart';

class ArmsControlTab extends StatefulWidget {
  final Function(String) onCommand;

  const ArmsControlTab({
    super.key,
    required this.onCommand,
  });

  @override
  State<ArmsControlTab> createState() => _ArmsControlTabState();
}

class _ArmsControlTabState extends State<ArmsControlTab> {
  // Simulated arm positions (0.0 to 1.0)
  double _arm1Position = 0.0;
  double _arm2Position = 0.0;
  double _arm3Position = 0.0;
  double _arm4Position = 0.0;

  void _sendCommand(String command) {
    widget.onCommand(command);
    HapticFeedback.lightImpact();

    // Simulate position changes (in real app, this would come from device feedback)
    setState(() {
      if (command.contains('ARM1_UP')) {
        _arm1Position = (_arm1Position + 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM1_DOWN')) {
        _arm1Position = (_arm1Position - 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM2_UP')) {
        _arm2Position = (_arm2Position + 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM2_DOWN')) {
        _arm2Position = (_arm2Position - 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM3_UP')) {
        _arm3Position = (_arm3Position + 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM3_DOWN')) {
        _arm3Position = (_arm3Position - 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM4_UP')) {
        _arm4Position = (_arm4Position + 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ARM4_DOWN')) {
        _arm4Position = (_arm4Position - 0.1).clamp(0.0, 1.0);
      }

      if (command.contains('FRONT_UP')) {
        _arm1Position = (_arm1Position + 0.1).clamp(0.0, 1.0);
        _arm2Position = (_arm2Position + 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('FRONT_DOWN')) {
        _arm1Position = (_arm1Position - 0.1).clamp(0.0, 1.0);
        _arm2Position = (_arm2Position - 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('BACK_UP')) {
        _arm3Position = (_arm3Position + 0.1).clamp(0.0, 1.0);
        _arm4Position = (_arm4Position + 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('BACK_DOWN')) {
        _arm3Position = (_arm3Position - 0.1).clamp(0.0, 1.0);
        _arm4Position = (_arm4Position - 0.1).clamp(0.0, 1.0);
      }
      if (command.contains('ALL_STOP')) {
        // Stop all arms
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Title
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

          // Group Controls Section
          _buildGroupControls(),
          const SizedBox(height: 32),

          // Individual Arms Section
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

          // Position Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ArmPositionIndicator(
                label: 'ARM 1',
                position: _arm1Position,
                color: AppTheme.primaryColor,
              ),
              ArmPositionIndicator(
                label: 'ARM 2',
                position: _arm2Position,
                color: AppTheme.primaryColor,
              ),
              ArmPositionIndicator(
                label: 'ARM 3',
                position: _arm3Position,
                color: AppTheme.accentColor,
              ),
              ArmPositionIndicator(
                label: 'ARM 4',
                position: _arm4Position,
                color: AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Individual Arm Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ArmControlButton(
                label: 'ARM 1',
                upIcon: Icons.arrow_upward_rounded,
                downIcon: Icons.arrow_downward_rounded,
                onUp: () => _sendCommand('ARM1_UP'),
                onDown: () => _sendCommand('ARM1_DOWN'),
                onRelease: () => _sendCommand('ARM1_STOP'),
              ),
              ArmControlButton(
                label: 'ARM 2',
                upIcon: Icons.arrow_upward_rounded,
                downIcon: Icons.arrow_downward_rounded,
                onUp: () => _sendCommand('ARM2_UP'),
                onDown: () => _sendCommand('ARM2_DOWN'),
                onRelease: () => _sendCommand('ARM2_STOP'),
              ),
              ArmControlButton(
                label: 'ARM 3',
                upIcon: Icons.arrow_upward_rounded,
                downIcon: Icons.arrow_downward_rounded,
                onUp: () => _sendCommand('ARM3_UP'),
                onDown: () => _sendCommand('ARM3_DOWN'),
                onRelease: () => _sendCommand('ARM3_STOP'),
              ),
              ArmControlButton(
                label: 'ARM 4',
                upIcon: Icons.arrow_upward_rounded,
                downIcon: Icons.arrow_downward_rounded,
                onUp: () => _sendCommand('ARM4_UP'),
                onDown: () => _sendCommand('ARM4_DOWN'),
                onRelease: () => _sendCommand('ARM4_STOP'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Emergency Stop
          _buildEmergencyStop(),
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
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(50),
          width: 1,
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Front Arms Group
              _buildGroupButton(
                label: 'FRONT ARMS',
                sublabel: 'Arms 1 & 2',
                upCommand: 'FRONT_UP',
                downCommand: 'FRONT_DOWN',
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              // Back Arms Group
              _buildGroupButton(
                label: 'BACK ARMS',
                sublabel: 'Arms 3 & 4',
                upCommand: 'BACK_UP',
                downCommand: 'BACK_DOWN',
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
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(100),
            width: 1,
          ),
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
                // Up button
                GestureDetector(
                  onTapDown: (_) => _sendCommand(upCommand),
                  onTapUp: (_) =>
                      _sendCommand('${upCommand.split('_')[0]}_STOP'),
                  onTapCancel: () =>
                      _sendCommand('${upCommand.split('_')[0]}_STOP'),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(200)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Down button
                GestureDetector(
                  onTapDown: (_) => _sendCommand(downCommand),
                  onTapUp: (_) =>
                      _sendCommand('${downCommand.split('_')[0]}_STOP'),
                  onTapCancel: () =>
                      _sendCommand('${downCommand.split('_')[0]}_STOP'),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withAlpha(200), color.withAlpha(150)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyStop() {
    return GestureDetector(
      onTap: () => _sendCommand('ALL_STOP'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.errorColor, Color(0xFFD63447)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop_circle, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'EMERGENCY STOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
