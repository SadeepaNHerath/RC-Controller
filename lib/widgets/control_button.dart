import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String command;
  final VoidCallback onPressed;
  final VoidCallback? onReleased;
  final Color? color;
  final double size;
  final bool isToggle;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.command,
    required this.onPressed,
    this.onReleased,
    this.color,
    this.size = 80,
    this.isToggle = false,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onReleased?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onReleased?.call();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPressed
                  ? [buttonColor.withAlpha(200), buttonColor.withAlpha(150)]
                  : [buttonColor, buttonColor.withAlpha(200)],
            ),
            borderRadius: BorderRadius.circular(widget.size * 0.2),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withAlpha(_isPressed ? 50 : 100),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 2 : 6),
                spreadRadius: _isPressed ? 0 : 2,
              ),
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withAlpha(_isPressed ? 20 : 40),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.size * 0.4,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
