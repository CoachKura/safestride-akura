// lib/theme/app_spacing.dart
import 'package:flutter/material.dart';

/// AKURA SafeStride Spacing & Layout System
/// Version 7.0 - Modern Dark Edition
/// 
/// Spacing scale, border radius, elevations, and shadows
class AppSpacing {
  AppSpacing._(); // Private constructor

  // ============================================================================
  // SPACING SCALE - 8pt grid system
  // ============================================================================

  /// Extra small spacing - 4dp
  /// Usage: Tight spacing between related elements
  static const double xs = 4.0;

  /// Small spacing - 8dp
  /// Usage: Compact layouts, icon padding
  static const double sm = 8.0;

  /// Medium spacing - 16dp (Base unit)
  /// Usage: Default spacing, standard padding
  static const double md = 16.0;

  /// Large spacing - 24dp
  /// Usage: Section gaps, card spacing
  static const double lg = 24.0;

  /// Extra large spacing - 32dp
  /// Usage: Major sections, screen padding
  static const double xl = 32.0;

  /// Extra extra large spacing - 48dp
  /// Usage: Hero sections, major separations
  static const double xxl = 48.0;

  // ============================================================================
  // COMPONENT-SPECIFIC SPACING
  // ============================================================================

  /// Standard card padding
  static const double cardPadding = 16.0;

  /// Screen edge padding
  static const double screenPadding = 20.0;

  /// Section gap spacing
  static const double sectionGap = 24.0;

  /// List item padding
  static const double listItemPadding = 16.0;

  /// Bottom navigation height
  static const double bottomNavHeight = 80.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Small icon size
  static const double iconSizeSmall = 16.0;

  /// Default icon size
  static const double iconSize = 24.0;

  /// Large icon size
  static const double iconSizeLarge = 32.0;

  /// Extra large icon size (app bar, hero)
  static const double iconSizeXL = 40.0;

  // ============================================================================
  // BUTTON SIZING
  // ============================================================================

  /// Button height - Small
  static const double buttonHeightSmall = 36.0;

  /// Button height - Medium (default)
  static const double buttonHeightMedium = 48.0;

  /// Button height - Large
  static const double buttonHeightLarge = 56.0;

  /// FAB size
  static const double fabSize = 56.0;

  /// Mini FAB size
  static const double fabSizeMini = 40.0;
}

/// Border Radius Definitions
class AppRadius {
  AppRadius._(); // Private constructor

  // ============================================================================
  // RADIUS VALUES
  // ============================================================================

  /// Small radius - 8dp
  /// Usage: Small components, chips
  static const double sm = 8.0;

  /// Medium radius - 12dp (Default)
  /// Usage: Cards, buttons
  static const double md = 12.0;

  /// Large radius - 16dp
  /// Usage: Large cards, modals
  static const double lg = 16.0;

  /// Extra large radius - 24dp
  /// Usage: Hero cards, featured content
  static const double xl = 24.0;

  /// Pill radius - 100dp
  /// Usage: Buttons, badges, fully rounded
  static const double pill = 100.0;

  // ============================================================================
  // BORDER RADIUS OBJECTS
  // ============================================================================

  /// Small border radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));

  /// Default border radius
  static const BorderRadius defaultRadius = BorderRadius.all(Radius.circular(12));

  /// Large border radius
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));

  /// Extra large border radius
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(24));

  /// Pill border radius
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(100));

  /// Top-only rounded corners (for bottom sheets)
  static const BorderRadius topRounded = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );

  /// Bottom-only rounded corners
  static const BorderRadius bottomRounded = BorderRadius.only(
    bottomLeft: Radius.circular(24),
    bottomRight: Radius.circular(24),
  );
}

/// Elevation & Shadow Definitions
class AppShadows {
  AppShadows._(); // Private constructor

  // ============================================================================
  // SHADOW DEFINITIONS
  // ============================================================================

  /// Subtle elevation for cards
  /// Usage: Standard cards, list items
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  /// Medium elevation
  /// Usage: Floating action buttons, raised components
  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x26000000),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  );

  /// Strong elevation for modals
  /// Usage: Dialogs, bottom sheets, overlays
  static const BoxShadow modalShadow = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
  );

  /// Hero shadow for featured content
  /// Usage: Hero cards, featured items
  static const BoxShadow heroShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 12),
    blurRadius: 32,
    spreadRadius: 0,
  );

  /// Glow effect for active states
  /// Usage: Active buttons, focused fields
  static BoxShadow glowShadow(Color color) => BoxShadow(
        color: color.withOpacity(0.4),
        offset: const Offset(0, 0),
        blurRadius: 16,
        spreadRadius: 0,
      );

  /// Bottom navigation shadow
  static const BoxShadow bottomNavShadow = BoxShadow(
    color: Color(0x26000000),
    offset: Offset(0, -2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  // ============================================================================
  // SHADOW LISTS (for convenience)
  // ============================================================================

  /// Card shadow list
  static const List<BoxShadow> cardShadows = [cardShadow];

  /// Medium shadow list
  static const List<BoxShadow> mediumShadows = [mediumShadow];

  /// Modal shadow list
  static const List<BoxShadow> modalShadows = [modalShadow];

  /// Hero shadow list
  static const List<BoxShadow> heroShadows = [heroShadow];

  /// Bottom nav shadow list
  static const List<BoxShadow> bottomNavShadows = [bottomNavShadow];

  /// Glow shadow list
  static List<BoxShadow> glowShadows(Color color) => [glowShadow(color)];
}

/// Edge Insets Presets
class AppPadding {
  AppPadding._(); // Private constructor

  // ============================================================================
  // SYMMETRIC PADDING
  // ============================================================================

  /// Extra small padding - 4dp all sides
  static const EdgeInsets xs = EdgeInsets.all(AppSpacing.xs);

  /// Small padding - 8dp all sides
  static const EdgeInsets sm = EdgeInsets.all(AppSpacing.sm);

  /// Medium padding - 16dp all sides
  static const EdgeInsets md = EdgeInsets.all(AppSpacing.md);

  /// Large padding - 24dp all sides
  static const EdgeInsets lg = EdgeInsets.all(AppSpacing.lg);

  /// Extra large padding - 32dp all sides
  static const EdgeInsets xl = EdgeInsets.all(AppSpacing.xl);

  // ============================================================================
  // HORIZONTAL PADDING
  // ============================================================================

  /// Screen horizontal padding
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.screenPadding,
  );

  /// Card horizontal padding
  static const EdgeInsets cardHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.cardPadding,
  );

  // ============================================================================
  // VERTICAL PADDING
  // ============================================================================

  /// Screen vertical padding
  static const EdgeInsets screenVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.screenPadding,
  );

  /// Section vertical padding
  static const EdgeInsets sectionVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.sectionGap,
  );

  // ============================================================================
  // COMBINED PADDING
  // ============================================================================

  /// Screen padding - All sides
  static const EdgeInsets screen = EdgeInsets.all(AppSpacing.screenPadding);

  /// Card padding - All sides
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.cardPadding);

  /// List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );

  /// Button padding - Horizontal
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );

  /// Button padding - Large
  static const EdgeInsets buttonLarge = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );
}
