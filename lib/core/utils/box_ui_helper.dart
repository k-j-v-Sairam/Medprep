import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

extension BoxUIHelper on int {
  Color toBoxColor({Color? defaultColor}) {
    switch (this) {
      case 0: return const Color(0xFF9E9E9E); // Grey for unviewed
      case 1: return const Color(0xFFE57373);
      case 2: return const Color(0xFFFFB74D);
      case 3: return const Color(0xFFFFD54F);
      case 4: return const Color(0xFF81C784);
      case 5: return const Color(0xFF4AE176);
      default: return defaultColor ?? AppTheme.primary;
    }
  }

  String toBoxEmoji() {
    switch (this) {
      case 0: return '🆕';
      case 1: return '🔴';
      case 2: return '🟠';
      case 3: return '🟡';
      case 4: return '🟢';
      case 5: return '💚';
      default: return '📦';
    }
  }
}
