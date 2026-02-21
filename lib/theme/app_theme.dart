// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// AKURA SafeStride Theme Configuration
/// Version 7.0 - Modern Dark Edition
///
/// Complete Material Design 3 theme configuration
/// Implements the AKURA SafeStride design system with dark-first approach
class AppTheme {
  AppTheme._(); // Private constructor

  // ============================================================================
  // MAIN THEME - Dark Theme (Primary)
  // ============================================================================

  /// Primary dark theme for the app
  /// Dark-first design optimized for running in low-light conditions
  static ThemeData get darkTheme {
    return ThemeData(
      // Core settings
      brightness: Brightness.dark,
      useMaterial3: true,

      // Primary colors
      primaryColor: AppColors.primaryOrange,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryOrange,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryOrange.withValues(alpha: 0.15),
        onPrimaryContainer: AppColors.primaryOrange,
        secondary: AppColors.primaryBlue,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.primaryBlue.withValues(alpha: 0.15),
        onSecondaryContainer: AppColors.primaryBlue,
        tertiary: AppColors.accentPurple,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.accentPurple.withValues(alpha: 0.15),
        onTertiaryContainer: AppColors.accentPurple,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.error.withValues(alpha: 0.15),
        onErrorContainer: AppColors.error,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceLight,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.surfaceLight,
        outlineVariant: AppColors.surfaceHover,
        shadow: Colors.black.withValues(alpha: 0.3),
        scrim: Colors.black.withValues(alpha: 0.6),
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.backgroundDark,
        inversePrimary: AppColors.primaryOrange,
        surfaceTint: AppColors.primaryOrange,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconSize,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconSize,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.defaultRadius,
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(0, AppSpacing.buttonHeightMedium),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(
            color: AppColors.surfaceLight,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
          textStyle: AppTextStyles.labelMedium,
          minimumSize: const Size(0, AppSpacing.buttonHeightMedium),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.defaultRadius,
          ),
          textStyle: AppTextStyles.labelMedium,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSpacing.fabSize,
          height: AppSpacing.fabSize,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,

        // Borders
        border: OutlineInputBorder(
          borderRadius: AppRadius.defaultRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.defaultRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.defaultRadius,
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.defaultRadius,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.defaultRadius,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.defaultRadius,
          borderSide: BorderSide.none,
        ),

        // Content
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),

        // Text styles
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryOrange,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
        ),
        helperStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),

        // Icons
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.surfaceLight.withValues(alpha: 0.5),
        selectedColor: AppColors.primaryOrange.withValues(alpha: 0.15),
        secondarySelectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        shadowColor: Colors.transparent,
        selectedShadowColor: Colors.transparent,
        labelStyle: AppTextStyles.labelSmall,
        secondaryLabelStyle: AppTextStyles.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        modalBackgroundColor: AppColors.surfaceDark,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.topRounded,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.defaultRadius,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSpacing.iconSize,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surfaceDark,
        selectedTileColor: AppColors.primaryOrange.withValues(alpha: 0.1),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.titleMedium,
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.defaultRadius,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return AppColors.surfaceLight;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return AppColors.surfaceLight;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return AppColors.textTertiary;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryOrange,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.primaryOrange,
        overlayColor: AppColors.primaryOrange.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.primaryOrange,
        valueIndicatorTextStyle: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryOrange,
        linearTrackColor: AppColors.surfaceLight,
        circularTrackColor: AppColors.surfaceLight,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 2,
          ),
          insets: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.defaultRadius,
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }

  // ============================================================================
  // LIGHT THEME (Optional - for outdoor use in bright sunlight)
  // ============================================================================

  /// Optional light theme for better readability in bright sunlight
  /// Can be toggled by user or auto-switched based on ambient light
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,

      primaryColor: AppColors.primaryOrange,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      colorScheme: ColorScheme.light(
        primary: AppColors.primaryOrange,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryOrange.withValues(alpha: 0.1),
        onPrimaryContainer: AppColors.primaryOrange,
        secondary: AppColors.primaryBlue,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.primaryBlue.withValues(alpha: 0.1),
        onSecondaryContainer: AppColors.primaryBlue,
        tertiary: AppColors.accentPurple,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.accentPurple.withValues(alpha: 0.1),
        onTertiaryContainer: AppColors.accentPurple,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.error.withValues(alpha: 0.1),
        onErrorContainer: AppColors.error,
        surface: AppColors.surfaceLightMode,
        onSurface: AppColors.textDark,
        surfaceContainerHighest: AppColors.backgroundLight,
        onSurfaceVariant: AppColors.textDark.withValues(alpha: 0.7),
        outline: const Color(0xFFE0E0E0),
        outlineVariant: const Color(0xFFF5F5F5),
        shadow: Colors.black.withValues(alpha: 0.1),
        scrim: Colors.black.withValues(alpha: 0.4),
        inverseSurface: AppColors.textDark,
        onInverseSurface: Colors.white,
        inversePrimary: AppColors.primaryOrange,
        surfaceTint: AppColors.primaryOrange,
      ),

      // Most other theme properties can inherit from dark theme
      // with color adjustments handled by the ColorScheme
      textTheme: TextTheme(
        displayLarge:
            AppTextStyles.displayLarge.copyWith(color: AppColors.textDark),
        displayMedium:
            AppTextStyles.displayMedium.copyWith(color: AppColors.textDark),
        displaySmall:
            AppTextStyles.displaySmall.copyWith(color: AppColors.textDark),
        headlineLarge:
            AppTextStyles.headlineLarge.copyWith(color: AppColors.textDark),
        headlineMedium:
            AppTextStyles.headlineMedium.copyWith(color: AppColors.textDark),
        headlineSmall:
            AppTextStyles.headlineSmall.copyWith(color: AppColors.textDark),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: AppColors.textDark),
        titleMedium:
            AppTextStyles.titleMedium.copyWith(color: AppColors.textDark),
        titleSmall:
            AppTextStyles.titleSmall.copyWith(color: AppColors.textDark),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDark),
        bodyMedium:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textDark),
        labelLarge:
            AppTextStyles.labelLarge.copyWith(color: AppColors.textDark),
        labelMedium:
            AppTextStyles.labelMedium.copyWith(color: AppColors.textDark),
        labelSmall:
            AppTextStyles.labelSmall.copyWith(color: AppColors.textDark),
      ),

      // Use the same component themes as dark theme
      // Material 3 will adapt colors automatically based on ColorScheme
    );
  }
}
