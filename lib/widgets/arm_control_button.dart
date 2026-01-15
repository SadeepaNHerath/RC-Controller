import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArmControlButton extends StatefulWidget {
  final String label;
  final IconData upIcon;
  final IconData downIcon;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onRelease;

  const ArmControlButton({
    super.key,
    required this.label,
    required this.upIcon,
    required this.downIcon,
    required this.onUp,
    required this.onDown,
    required this.onRelease,
  });

  @override
  State<ArmControlButton> createState() => _ArmControlButtonState();
}

class _ArmControlButtonState extends State<ArmControlButton> {
  bool _isUpPressed = false;
  bool _isDownPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        // Up button
        GestureDetector(
          onTapDown: (_) {
            setState(() => _isUpPressed = true);
            widget.onUp();
          },
          onTapUp: (_) {
            setState(() => _isUpPressed = false);
            widget.onRelease();
          },
          onTapCancel: () {
            setState(() => _isUpPressed = false);
            widget.onRelease();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isUpPressed
                    ? [
                        AppTheme.successColor.withAlpha(200),
                        AppTheme.successColor.withAlpha(150)
                      ]
                    : [
                        AppTheme.successColor,
                        AppTheme.successColor.withAlpha(200)
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      AppTheme.successColor.withAlpha(_isUpPressed ? 50 : 100),
                  blurRadius: _isUpPressed ? 8 : 16,
                  offset: Offset(0, _isUpPressed ? 2 : 6),
                ),
              ],
            ),
            child: Icon(
              widget.upIcon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Down button
        GestureDetector(
          onTapDown: (_) {
            setState(() => _isDownPressed = true);
            widget.onDown();
          },
          onTapUp: (_) {
            setState(() => _isDownPressed = false);
            widget.onRelease();
          },
          onTapCancel: () {
            setState(() => _isDownPressed = false);
            widget.onRelease();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDownPressed
                    ? [
                        AppTheme.warningColor.withAlpha(200),
                        AppTheme.warningColor.withAlpha(150)
                      ]
                    : [
                        AppTheme.warningColor,
                        AppTheme.warningColor.withAlpha(200)
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warningColor
                      .withAlpha(_isDownPressed ? 50 : 100),
                  blurRadius: _isDownPressed ? 8 : 16,
                  offset: Offset(0, _isDownPressed ? 2 : 6),
                ),
              ],
            ),
            child: Icon(
              widget.downIcon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}
