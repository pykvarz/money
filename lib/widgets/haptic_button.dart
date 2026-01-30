import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Виджет для добавления haptic feedback к действиям
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HapticFeedbackType feedbackType;

  const HapticButton({
    super.key,
    required this.child,
    this.onTap,
    this.feedbackType = HapticFeedbackType.medium,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          _triggerHaptic(feedbackType);
          onTap!();
        }
      },
      child: child,
    );
  }

  void _triggerHaptic(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}
