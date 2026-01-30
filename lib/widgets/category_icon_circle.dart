import 'package:flutter/material.dart';

/// Виджет для отображения иконки категории в цветном круглом контейнере
class CategoryIconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool withGradient;

  const CategoryIconCircle({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.withGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: withGradient
            ? LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: withGradient ? null : color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
