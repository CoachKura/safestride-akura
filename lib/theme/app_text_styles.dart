// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AKURA SafeStride Typography System
/// Version 7.0 - Modern Dark Edition
///
/// Complete text style definitions using Inter font family
/// Follows Material Design 3 type scale with customizations
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // ============================================================================
  // DISPLAY STYLES - Hero sections, large headlines
  // ============================================================================

  /// Display Large - 57sp, ExtraBold
  /// Usage: Hero headlines, splash screens
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -0.25,
  );

  /// Display Medium - 45sp, Bold
  /// Usage: Section heroes, major headlines
  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  /// Display Small - 36sp, SemiBold
  /// Usage: Sub-heroes, feature highlights
  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  // ============================================================================
  // HEADLINE STYLES - Section titles
  // ============================================================================

  /// Headline Large - 32sp, Bold
  /// Usage: Screen titles, major sections
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Headline Medium - 28sp, SemiBold
  /// Usage: Section headers
  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
  );

  /// Headline Small - 24sp, SemiBold
  /// Usage: Card titles, subsection headers
  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // ============================================================================
  // TITLE STYLES - Card headers, list items
  // ============================================================================

  /// Title Large - 22sp, SemiBold
  /// Usage: Large card headers, list section titles
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  /// Title Medium - 16sp, SemiBold
  /// Usage: Card titles, dialog headers
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Title Small - 14sp, SemiBold
  /// Usage: Compact card titles, list item headers
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ============================================================================
  // BODY STYLES - Main content, paragraphs
  // ============================================================================

  /// Body Large - 16sp, Regular
  /// Usage: Main body text, descriptions
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Body Medium - 14sp, Regular
  /// Usage: Default body text, list items
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// Body Small - 12sp, Regular
  /// Usage: Secondary descriptions, captions
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ============================================================================
  // LABEL STYLES - Buttons, badges, chips
  // ============================================================================

  /// Label Large - 14sp, SemiBold
  /// Usage: Primary buttons, important labels
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Label Medium - 12sp, SemiBold
  /// Usage: Secondary buttons, badges
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
  );

  /// Label Small - 11sp, SemiBold
  /// Usage: Chips, small badges, tags
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ============================================================================
  // SPECIAL STYLES - Stats, metrics, specialized content
  // ============================================================================

  /// Stat Value - 36sp, ExtraBold
  /// Usage: Large metric values (distance, pace, heart rate)
  static TextStyle statValue = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.5,
  );

  /// Stat Value Large - 48sp, ExtraBold
  /// Usage: Hero stats, featured metrics
  static TextStyle statValueLarge = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.5,
  );

  /// Stat Label - 12sp, Medium
  /// Usage: Metric labels (km, bpm, min)
  static TextStyle statLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
    color: const Color(0x80FFFFFF), // 50% opacity white
  );

  /// Time Display - 32sp, Bold
  /// Usage: Timer displays during workouts
  static TextStyle timeDisplay = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
    fontFeatures: [const FontFeature.tabularFigures()], // Monospaced numbers
  );

  /// Pace Display - 28sp, Bold
  /// Usage: Pace metrics (min/km)
  static TextStyle paceDisplay = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply opacity to any text style
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(
      color:
          (style.color ?? const Color(0xFFFFFFFF)).withValues(alpha: opacity),
    );
  }

  /// Create custom text style with Inter font
  static TextStyle custom({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
