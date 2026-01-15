import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'control_button.dart';

class ControlPad extends StatelessWidget {
  final Function(String) onCommand;
  final VoidCallback onStop;

  const ControlPad({
    super.key,
    required this.onCommand,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        const Text(
          'CONTROLS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Forward button
        ControlButton(
          icon: Icons.keyboard_arrow_up_rounded,
          label: 'FWD',
          command: 'F',
          onPressed: () => onCommand('F'),
          onReleased: onStop,
        ),
        const SizedBox(height: 12),

        // Left, Stop, Right row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ControlButton(
              icon: Icons.keyboard_arrow_left_rounded,
              label: 'LEFT',
              command: 'L',
              onPressed: () => onCommand('L'),
              onReleased: onStop,
            ),
            const SizedBox(width: 12),
            ControlButton(
              icon: Icons.stop_rounded,
              label: 'STOP',
              command: 'S',
              color: AppTheme.errorColor,
              onPressed: () => onCommand('S'),
            ),
            const SizedBox(width: 12),
            ControlButton(
              icon: Icons.keyboard_arrow_right_rounded,
              label: 'RIGHT',
              command: 'R',
              onPressed: () => onCommand('R'),
              onReleased: onStop,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Backward button
        ControlButton(
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'BWD',
          command: 'B',
          onPressed: () => onCommand('B'),
          onReleased: onStop,
        ),
        const SizedBox(height: 32),

        // Speed controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ControlButton(
              icon: Icons.remove_rounded,
              label: 'SLOW',
              command: '-',
              color: AppTheme.secondaryColor,
              size: 65,
              onPressed: () => onCommand('-'),
            ),
            const SizedBox(width: 24),
            ControlButton(
              icon: Icons.add_rounded,
              label: 'FAST',
              command: '+',
              color: AppTheme.successColor,
              size: 65,
              onPressed: () => onCommand('+'),
            ),
          ],
        ),
      ],
    );
  }
}
