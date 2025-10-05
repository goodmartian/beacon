import 'package:flutter/material.dart';

/// Color palette for Beacon app
/// Dark theme for battery saving and high contrast in emergencies
/// Normal mode: Blue accents on dark background
/// Emergency mode: Red gradients on black (OLED optimized)
class AppColors {
  // ========== DARK THEME - BATTERY OPTIMIZED ==========

  // Background Colors (Pure Black for OLED)
  static const Color bgPrimary = Color(0xFF000000);      // Pure black
  static const Color bgSecondary = Color(0xFF000000);    // Pure black
  static const Color bgTertiary = Color(0xFF1A1A1A);     // Subtle elevation

  // Text Colors (White)
  static const Color textPrimary = Color(0xFFFFFFFF);    // Pure white
  static const Color textSecondary = Color(0xFFFFFFFF);  // Pure white
  static const Color textTertiary = Color(0xFFE0E0E0);   // Slightly muted white

  // Normal Mode Accent Colors (Google Search blue - bright but muted)
  static const Color accentBlue = Color(0xFF8AB4F8);     // Google Search active tab blue
  static const Color accentBlueDark = Color(0xFF6A94D8); // Darker variant
  static const Color accentBlueLight = Color(0xFFAAC4FF);// Lighter variant

  // Legacy compatibility
  static const Color safetyGreen = accentBlue;           // Redirect to blue
  static const Color normalBackground = bgPrimary;        // Black background
  static const Color normalText = textPrimary;

  // Emergency Mode Colors (OLED optimized)
  static const Color sosRed = Color(0xFFEF4444);         // Vibrant red
  static const Color sosRedDark = Color(0xFFDC2626);     // Darker red for gradient
  static const Color hazardAmber = Color(0xFFF59E0B);
  static const Color emergencyBackground = Color(0xFF000000);
  static const Color emergencyText = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);        // Emerald green
  static const Color warning = Color(0xFFF59E0B);        // Amber
  static const Color error = Color(0xFFEF4444);          // Red
  static const Color info = Color(0xFF3B82F6);           // Blue

  // UI Elements
  static const Color cardBackground = bgSecondary;
  static const Color divider = Color(0xFF333333);        // Dark gray divider
  static const Color shadow = Color(0x66000000);

  // Radar-specific Colors (Tactical Emergency Theme)
  static const Color radarBackground = Color(0xFF0A0E27);     // Dark blue-gray
  static const Color radarRing = Color(0xFF1A2645);           // Radar circles
  static const Color radarGrid = Color(0xFF2D3E5F);           // Grid dots
  static const Color radarSweep = Color(0xFF00D9FF);          // Cyan sweep
  static const Color radarNorth = Color(0xFF8B95A8);          // North marker
  static const Color radarText = Color(0xFFE8EDF2);           // Light text

  // Device Status Colors (Radar)
  static const Color deviceSafe = Color(0xFF00FF88);          // Bright green
  static const Color deviceNeedHelp = Color(0xFFFFB800);      // Amber
  static const Color deviceSos = Color(0xFFFF3366);           // Red
  static const Color deviceRelay = Color(0xFF00D9FF);         // Cyan

  // Heatmap Gradient Colors
  static const Color heatmapLow = Color(0xFF0A2540);          // Dark blue
  static const Color heatmapMedium = Color(0xFF00D9FF);       // Cyan
  static const Color heatmapMediumHigh = Color(0xFF00FF88);   // Green
  static const Color heatmapHigh = Color(0xFFFFB800);         // Yellow
  static const Color heatmapCritical = Color(0xFFFF6B35);     // Orange-red

  // ========== NEW: MESH NETWORK STATUS ==========
  static const Color meshNodeActive = Color(0xFFFFFFFF);      // White (active)
  static const Color meshNodeInactive = Color(0xFF888888);    // Gray (inactive)
  static const Color meshSignalStrong = Color(0xFFFFFFFF);    // White (strong)
  static const Color meshSignalMedium = Color(0xFFFFFFFF);    // White (medium)
  static const Color meshSignalWeak = Color(0xFFFF6B6B);      // Light red (weak)

  // ========== NEW: GRADIENTS ==========
  static const List<Color> sosGradient = [sosRed, sosRedDark];
  static const List<Color> safeGradient = [success, Color(0xFF059669)];
  static const List<Color> warningGradient = [warning, Color(0xFFD97706)];
}
