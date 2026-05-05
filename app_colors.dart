import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF2196F3); // Medical Blue
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Secondary Colors
  static const Color secondary = Color(0xFF4CAF50); // Success Green
  static const Color secondaryDark = Color(0xFF388E3C);

  // Accent & Status Colors
  static const Color accent = Color(0xFFFF9800); // Warning Orange
  static const Color error = Color(0xFFF44336); // Error Red
  static const Color success = Color(0xFF4CAF50);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA); // Light Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color textSecondary = Color(0xFF757575); // Medium Gray
  static const Color divider = Color(0xFFBDBDBD);

  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
