import 'package:flutter/material.dart';

/// Анимированный прогресс-бар с плавным заполнением
class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration duration;
  final bool useGradient;
  final LinearGradient? gradient;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 1000),
    this.useGradient = false,
    this.gradient,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  @override
  Widget build(BuildContext context) {
    // Determine color based on percentage if not provided
    Color effectiveColor = widget.color ?? _getColorForValue(widget.value);
    
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: TweenAnimationBuilder<double>(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        tween: Tween<double>(
          begin: 0.0,
          end: widget.value.clamp(0.0, 1.0),
        ),
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
            backgroundColor: widget.backgroundColor ?? Colors.grey[200],
            valueColor: widget.useGradient && widget.gradient != null
                ? null
                : AlwaysStoppedAnimation(effectiveColor),
            minHeight: widget.height,
          );
        },
      ),
    );
  }

  Color _getColorForValue(double value) {
    if (value < 0.7) {
      return Colors.green;
    } else if (value < 0.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
