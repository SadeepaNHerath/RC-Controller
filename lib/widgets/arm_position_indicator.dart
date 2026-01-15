import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArmPositionIndicator extends StatelessWidget {
  final String label;
  final double position; // 0.0 to 1.0 (0 = down, 1 = up)
  final Color color;

  const ArmPositionIndicator({
    super.key,
    required this.label,
    required this.position,
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.textSecondary.withAlpha(50),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background track
              Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Fill indicator
              Container(
                margin: const EdgeInsets.all(4),
                height: (120 - 8) * position,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color,
                      color.withAlpha(200),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(100),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Position marker
              Positioned(
                bottom: (120 - 20) * position,
                child: Container(
                  width: 30,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // Percentage text
              Center(
                child: Text(
                  '${(position * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        position > 0.5 ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
