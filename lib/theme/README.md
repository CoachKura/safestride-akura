# AKURA SafeStride Design System

**Version**: 7.0 - Modern Dark Edition  
**Theme**: Dark, Professional, Athletic  
**Date**: February 2026

## 📁 File Structure

```
lib/theme/
├── theme.dart              # Main export (import this)
├── app_colors.dart         # Complete color palette
├── app_text_styles.dart    # Typography system
├── app_spacing.dart        # Spacing, radius, shadows
├── app_theme.dart          # Theme configuration
└── dashboard_colors.dart   # Legacy (kept for compatibility)
```

## 🚀 Quick Start

### Import the Design System

```dart
import 'package:akura_mobile/theme/theme.dart';
```

This single import gives you access to all design system components:
- `AppColors` - All colors
- `AppTextStyles` - All text styles
- `AppSpacing` - Spacing values
- `AppRadius` - Border radius values
- `AppShadows` - Shadow definitions
- `AppPadding` - EdgeInsets presets
- `AppTheme` - Complete theme

## 🎨 Usage Examples

### Colors

```dart
Container(
  color: AppColors.surfaceDark,
  decoration: BoxDecoration(
    gradient: AppColors.heroGradient,
    borderRadius: AppRadius.defaultRadius,
  ),
)
```

### Text Styles

```dart
Text(
  'Hello Runner!',
  style: AppTextStyles.headlineLarge,
)

Text(
  '12.5 km',
  style: AppTextStyles.statValue,
)
```

### Spacing & Layout

```dart
Padding(
  padding: AppPadding.md,
  child: Column(
    children: [
      // Content
    ],
  ),
)

SizedBox(height: AppSpacing.lg)
```

### Shadows & Elevation

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: AppRadius.defaultRadius,
    boxShadow: AppShadows.cardShadows,
  ),
)
```

### AISRI Zone Colors

```dart
Container(
  color: AppColors.zoneEN,
  // or dynamically:
  color: AppColors.getZoneColor('TH'),
)
```

## 📐 Spacing Scale

- `AppSpacing.xs` - 4dp (tight spacing)
- `AppSpacing.sm` - 8dp (small spacing)
- `AppSpacing.md` - 16dp (default)
- `AppSpacing.lg` - 24dp (large spacing)
- `AppSpacing.xl` - 32dp (extra large)
- `AppSpacing.xxl` - 48dp (hero sections)

## 🎨 Primary Colors

- `AppColors.primaryOrange` - Main brand (#FF6B35)
- `AppColors.primaryBlue` - Secondary (#0099FF)
- `AppColors.accentGreen` - Success (#00E676)
- `AppColors.accentPurple` - Premium (#9C27FF)

## 📝 Text Hierarchy

- **Display** (57/45/36sp) - Hero headlines
- **Headline** (32/28/24sp) - Section titles
- **Title** (22/16/14sp) - Card headers
- **Body** (16/14/12sp) - Main content
- **Label** (14/12/11sp) - Buttons, badges

## 🏃 AISRI Zones

- `AppColors.zoneAR` - Active Recovery (50-60%)
- `AppColors.zoneF` - Foundation (60-70%)
- `AppColors.zoneEN` - Endurance (70-80%)
- `AppColors.zoneTH` - Threshold (80-87%)
- `AppColors.zoneP` - Peak (87-95%)
- `AppColors.zoneSP` - Sprint (95-100%)

## 🧩 Example Components

### Primary Button

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Start Workout'),
)
```

### Card with Stats

```dart
Container(
  padding: AppPadding.md,
  decoration: BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: AppRadius.defaultRadius,
    boxShadow: AppShadows.cardShadows,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Distance', style: AppTextStyles.labelMedium),
      SizedBox(height: AppSpacing.sm),
      Text('12.5', style: AppTextStyles.statValue),
      Text('km', style: AppTextStyles.statLabel),
    ],
  ),
)
```

### Zone Badge

```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  ),
  decoration: BoxDecoration(
    color: AppColors.zoneTH.withOpacity(0.15),
    borderRadius: AppRadius.pillRadius,
    border: Border.all(color: AppColors.zoneTH),
  ),
  child: Text(
    'THRESHOLD',
    style: AppTextStyles.labelSmall.copyWith(
      color: AppColors.zoneTH,
    ),
  ),
)
```

## 🌙 Dark Theme

The app uses dark theme as primary. Access via:

```dart
MaterialApp(
  theme: AppTheme.darkTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.dark,
)
```

## ☀️ Light Theme (Optional)

For outdoor use in bright sunlight:

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Auto-switch
)
```

## 📱 Responsive Design

All spacing and sizing values are in device-independent pixels (dp) and will scale automatically across different screen sizes.

## 🎯 Design Principles

1. **Dark First** - Optimized for running in low-light
2. **Data Dense** - Show maximum relevant data
3. **Action Oriented** - Quick access to key functions
4. **Performance** - Smooth 60 FPS animations
5. **Consistency** - Unified design language

## 🔄 Migrating from Old Theme

Replace old color references:

```dart
// Old
Color(0xFF667EEA)

// New
AppColors.primaryBlue
```

Replace old text styles:

```dart
// Old
TextStyle(fontSize: 24, fontWeight: FontWeight.bold)

// New
AppTextStyles.headlineSmall
```

## 📚 Resources

- Design Doc: See root `DESIGN_SYSTEM.md`
- Figma: [Link to Figma file]
- Material 3: https://m3.material.io/

## 🤝 Contributing

When adding new design tokens:

1. Add to appropriate file (`app_colors.dart`, etc.)
2. Document usage in this README
3. Update design documentation
4. Test on real devices

---

**Let's build the most modern running app! 🚀**
