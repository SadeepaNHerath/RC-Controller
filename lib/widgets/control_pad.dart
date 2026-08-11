import 'package:flutter/material.dart';

import '../commands/rc_commands.dart';
import '../theme/app_theme.dart';
import 'control_button.dart';

class ControlPad extends StatelessWidget {
  const ControlPad({
    super.key,
    required this.onCommand,
    required this.onStop,
  });

  final Future<void> Function(String command) onCommand;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        ControlButton(
          icon: Icons.keyboard_arrow_up_rounded,
          label: 'FWD',
          command: RcCommands.forward,
          onPressed: () => onCommand(RcCommands.forward),
          onReleased: onStop,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ControlButton(
              icon: Icons.keyboard_arrow_left_rounded,
              label: 'LEFT',
              command: RcCommands.left,
              onPressed: () => onCommand(RcCommands.left),
              onReleased: onStop,
            ),
            const SizedBox(width: 12),
            ControlButton(
              icon: Icons.stop_rounded,
              label: 'STOP',
              command: RcCommands.stop,
              color: AppTheme.errorColor,
              onPressed: () => onCommand(RcCommands.stop),
            ),
            const SizedBox(width: 12),
            ControlButton(
              icon: Icons.keyboard_arrow_right_rounded,
              label: 'RIGHT',
              command: RcCommands.right,
              onPressed: () => onCommand(RcCommands.right),
              onReleased: onStop,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ControlButton(
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'BWD',
          command: RcCommands.backward,
          onPressed: () => onCommand(RcCommands.backward),
          onReleased: onStop,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ControlButton(
              icon: Icons.remove_rounded,
              label: 'SLOW',
              command: RcCommands.slower,
              color: AppTheme.secondaryColor,
              size: 65,
              onPressed: () => onCommand(RcCommands.slower),
            ),
            const SizedBox(width: 24),
            ControlButton(
              icon: Icons.add_rounded,
              label: 'FAST',
              command: RcCommands.faster,
              color: AppTheme.successColor,
              size: 65,
              onPressed: () => onCommand(RcCommands.faster),
            ),
          ],
        ),
      ],
    );
  }
}
