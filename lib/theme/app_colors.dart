// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

/// AKURA SafeStride Color System
/// Version 7.0 - Modern Dark Edition
///
/// Complete color palette for the dark-first running training app
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PRIMARY COLORS - Athletic & Professional
  // ============================================================================

  /// Main brand color - Running energy and action
  static const Color primaryOrange = Color(0xFFFF6B35);

  /// Secondary brand color - Trust and performance
  static const Color primaryBlue = Color(0xFF0099FF);

  /// Success color - Goals achieved, positive actions
  static const Color accentGreen = Color(0xFF00E676);

  /// Premium features indicator
  static const Color accentPurple = Color(0xFF9C27FF);

  // ============================================================================
  // BACKGROUND COLORS - Deep & Modern
  // ============================================================================

  /// Main background color - Deepest dark
  static const Color backgroundDark = Color(0xFF0D0F14);

  /// Cards and elevated surfaces
  static const Color surfaceDark = Color(0xFF1A1D26);

  /// Secondary surfaces, list items
  static const Color surfaceLight = Color(0xFF252932);

  /// Hover and pressed states
  static const Color surfaceHover = Color(0xFF2D313D);

  // ============================================================================
  // TEXT COLORS - Hierarchy
  // ============================================================================

  /// Primary text - Maximum emphasis (100% opacity)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - Medium emphasis (70% opacity)
  static const Color textSecondary = Color(0xB3FFFFFF);

  /// Tertiary text - Low emphasis (50% opacity)
  static const Color textTertiary = Color(0x80FFFFFF);

  /// Disabled text - Minimal emphasis (30% opacity)
  static const Color textDisabled = Color(0x4DFFFFFF);

  // ============================================================================
  // AISRI ZONE COLORS - Heart Rate Training Zones
  // ============================================================================

  /// Zone AR - Active Recovery (50-60% max HR)
  static const Color zoneAR = Color(0xFF4CAF50);

  /// Zone F - Foundation (60-70% max HR)
  static const Color zoneF = Color(0xFF2196F3);

  /// Zone EN - Endurance (70-80% max HR)
  static const Color zoneEN = Color(0xFF03A9F4);

  /// Zone TH - Threshold (80-87% max HR)
  static const Color zoneTH = Color(0xFFFF9800);

  /// Zone P - Peak (87-95% max HR)
  static const Color zoneP = Color(0xFFFF5722);

  /// Zone SP - Sprint (95-100% max HR)
  static const Color zoneSP = Color(0xFFF44336);

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  /// Success states - Completed, achieved
  static const Color success = Color(0xFF00E676);

  /// Warning states - Attention needed
  static const Color warning = Color(0xFFFFC107);

  /// Error states - Errors, injury risk
  static const Color error = Color(0xFFFF5252);

  /// Info states - Tips, information
  static const Color info = Color(0xFF448AFF);

  // ============================================================================
  // GRADIENT OVERLAYS
  // ============================================================================

  /// Hero gradient - Orange theme for primary CTAs
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
  );

  /// Stats gradient - Blue theme for analytics
  static const LinearGradient statsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0099FF), Color(0xFF00C6FF)],
  );

  /// Premium gradient - Purple theme for premium features
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9C27FF), Color(0xFFBA68C8)],
  );

  // ============================================================================
  // LIGHT THEME COLORS (Optional - for bright sunlight readability)
  // ============================================================================

  /// Light background - For outdoor use in bright sunlight
  static const Color backgroundLight = Color(0xFFF5F7FA);

  /// Light surface - Cards and containers in light mode
  static const Color surfaceLightMode = Color(0xFFFFFFFF);

  /// Dark text - For light mode
  static const Color textDark = Color(0xFF1A1D26);

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get AISRI zone color by zone name
  static Color getZoneColor(String zone) {
    switch (zone.toUpperCase()) {
      case 'AR':
        return zoneAR;
      case 'F':
        return zoneF;
      case 'EN':
        return zoneEN;
      case 'TH':
        return zoneTH;
      case 'P':
        return zoneP;
      case 'SP':
        return zoneSP;
      default:
        return zoneF; // Default to Foundation zone
    }
  }

  /// Create zone gradient for progress bars and charts
  static LinearGradient getZoneGradient(String zone) {
    final color = getZoneColor(zone);
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withValues(alpha: 0.7),
        color,
      ],
    );
  }

  /// Get color with opacity for glassmorphism effects
  static Color withGlassOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
