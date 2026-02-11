# 🎨 AKURA SAFESTRIDE - Modern Design System
## Ultra-Modern Running Training App

**Date**: 2026-02-10  
**Version**: 7.0 - Modern Dark Edition  
**Status**: Design Documentation  
**Theme**: Dark, Professional, Athletic  

---

## 🎯 DESIGN PHILOSOPHY

### Brand Identity
- **AKURA SafeStride**: Premium running training platform
- **AISRI Standard**: Science-based injury prevention
- **Target Users**: Serious runners, athletes, coaches
- **Positioning**: Professional alternative to Strava/Garmin Connect
- **Unique Value**: AI-powered injury prevention + structured training

### Design Principles
1. **Dark First**: Modern dark theme as primary (easier on eyes during runs)
2. **Data Dense**: Show maximum relevant data without clutter
3. **Action Oriented**: Quick access to start workout, view stats, adjust plans
4. **Performance**: Smooth animations, fast load times
5. **Consistency**: Unified design language across mobile and watch

---

## 🎨 COLOR SYSTEM

### Primary Palette (Dark Theme)

```dart
// Primary Colors - Athletic & Professional
static const Color primaryOrange = Color(0xFFFF6B35);     // Main brand color (running energy)
static const Color primaryBlue = Color(0xFF0099FF);       // Secondary (trust, performance)
static const Color accentGreen = Color(0xFF00E676);       // Success, goals achieved
static const Color accentPurple = Color(0xFF9C27FF);      // Premium features

// Background Colors - Deep & Modern
static const Color backgroundDark = Color(0xFF0D0F14);    // Main background
static const Color surfaceDark = Color(0xFF1A1D26);       // Cards, elevated surfaces
static const Color surfaceLight = Color(0xFF252932);      // Secondary surfaces
static const Color surfaceHover = Color(0xFF2D313D);      // Hover states

// Text Colors - Hierarchy
static const Color textPrimary = Color(0xFFFFFFFF);       // Main text (100% opacity)
static const Color textSecondary = Color(0xB3FFFFFF);     // Secondary text (70% opacity)
static const Color textTertiary = Color(0x80FFFFFF);      // Tertiary text (50% opacity)
static const Color textDisabled = Color(0x4DFFFFFF);      // Disabled text (30% opacity)

// AISRI Zone Colors - Heart Rate Training Zones
static const Color zoneAR = Color(0xFF4CAF50);            // Active Recovery (50-60%)
static const Color zoneF = Color(0xFF2196F3);             // Foundation (60-70%)
static const Color zoneEN = Color(0xFF03A9F4);            // Endurance (70-80%)
static const Color zoneTH = Color(0xFFFF9800);            // Threshold (80-87%)
static const Color zoneP = Color(0xFFFF5722);             // Peak (87-95%)
static const Color zoneSP = Color(0xFFF44336);            // Sprint (95-100%)

// Status Colors
static const Color success = Color(0xFF00E676);           // Completed, achieved
static const Color warning = Color(0xFFFFC107);           // Warning, attention
static const Color error = Color(0xFFFF5252);             // Error, injury risk
static const Color info = Color(0xFF448AFF);              // Info, tips
```

---

## 📝 TYPOGRAPHY

### Font Family
- **Primary**: Inter (modern, readable, athletic)
- **Alternative Headers**: Montserrat
- **Alternative Body**: Roboto

### Text Styles

```dart
class AppTextStyles {
  // Display - Hero sections
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 57,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -0.25,
  );
  
  // Headline - Section titles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  
  // Title - Card headers
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );
  
  // Body - Main content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  // Label - Buttons, badges
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  // Special - Stats, metrics
  static const TextStyle statValue = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.5,
  );
}
```

---

## 📐 SPACING & LAYOUT

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 100.0;
}
```

---

## 🧩 COMPONENT LIBRARY

### Primary Card
```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 2),
        blurRadius: 8,
      ),
    ],
  ),
)
```

### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryOrange,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100),
    ),
  ),
)
```

### AISRI Zone Badge
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.zoneTH.withOpacity(0.15),
    borderRadius: BorderRadius.circular(100),
    border: Border.all(color: AppColors.zoneTH, width: 1),
  ),
  child: Text('THRESHOLD', style: AppTextStyles.labelSmall),
)
```

---

## 📱 SCREEN LAYOUTS

### 1. Dashboard Screen
- Welcome section with AISRI score
- Today's workout card (hero style)
- Weekly summary (4 metric cards)
- Upcoming workouts list

### 2. Workout Detail Screen
- Zone indicator banner
- Timer/metrics display
- Workout structure breakdown
- Heart rate zones reference
- Instructions section

### 3. Live Workout Screen
- Large timer
- Current metrics (distance, pace, HR, cadence)
- Zone progress bar
- Interval progress
- Map view (collapsible)

### 4. Calendar Screen
- Month view with workout indicators
- Today's plan details
- Week summary card
- Quick navigation

### 5. Stats & Analytics Screen
- AISRI score trend chart
- Key metrics cards
- Zone distribution chart
- Personal bests list
- Training load graph

### 6. Profile Screen
- User avatar and info
- AISRI score display
- Connected devices list
- Settings menu
- Quick stats

### 7. Kura Coach Screen
- AI coach header
- Current training plan card
- Coach insights (new badges)
- Suggested workouts
- Ask Coach button

---

## ⌚ SMARTWATCH DESIGN

### Watch Face
```
┌─────────────────┐
│    12:34 PM     │
│                 │
│   78 AISRI      │
│   ████░░        │
│                 │
│   4.2 km TODAY  │
│                 │
│  [START] [STATS]│
└─────────────────┘
```

### Workout Screen (Watch)
```
┌─────────────────┐
│  Zone TH  162   │
│     5.2 km      │
│    00:23:45     │
│    4:35 /km     │
│  [←] [⏸] [LOCK] │
└─────────────────┘
```

---

## 💻 THEME IMPLEMENTATION

```dart
// lib/theme/app_theme.dart

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryOrange,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryOrange,
      secondary: AppColors.primaryBlue,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
    ),
    
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      headlineLarge: AppTextStyles.headlineLarge,
      titleLarge: AppTextStyles.titleLarge,
      bodyLarge: AppTextStyles.bodyLarge,
      labelLarge: AppTextStyles.labelLarge,
    ),
    
    cardTheme: CardTheme(
      color: AppColors.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
```

### Usage in main.dart
```dart
MaterialApp(
  theme: AppTheme.darkTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.dark,
)
```

---

## 🚀 IMPLEMENTATION ROADMAP

### Phase 1: Theme Foundation (Week 1-2)
- Create color constants
- Define text styles
- Configure Flutter theme
- Apply to existing screens

### Phase 2: Component Library (Week 3-4)
- Build reusable card components
- Create button variants
- Design zone indicators
- Develop stat display widgets

### Phase 3: Screen Redesign (Week 5-8)
- Implement Dashboard screen
- Redesign Workout screens
- Update Calendar view
- Revamp Stats/Analytics
- Polish Profile screen

### Phase 4: Watch Integration (Week 9-10)
- Design Garmin data fields
- Create watch face
- Develop workout app

### Phase 5: Polish & Testing (Week 11-12)
- Animations and transitions
- Performance optimization
- Accessibility features
- User testing

---

## 📚 DESIGN RESOURCES

### Fonts to Install
```yaml
# pubspec.yaml
fonts:
  - family: Inter
    fonts:
      - asset: assets/fonts/Inter-Regular.ttf
      - asset: assets/fonts/Inter-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Inter-Bold.ttf
        weight: 700
      - asset: assets/fonts/Inter-ExtraBold.ttf
        weight: 800
```

### Flutter Packages
- `flutter_animate` - Smooth animations
- `fl_chart` - Charts and graphs
- `shimmer` - Loading skeletons
- `cached_network_image` - Image loading

### Design Inspiration
- Strava (activity feed, stats)
- Garmin Connect (workout structure)
- TrainingPeaks (training calendar)
- Nike Run Club (motivation)
- Apple Fitness+ (modern UI)

---

## 🎯 DESIGN GOALS

### User Experience
- ⚡ Fast: <2 seconds to start workout
- 🎯 Clear: Understand current zone at a glance
- 📊 Data-Rich: See all key metrics without scrolling
- 🌙 Eye-Friendly: Dark theme for night runs
- 🏃 Action-First: Primary CTA always visible

### Technical
- 📱 Native Feel: Flutter Material 3
- ⚡ 60 FPS: Smooth animations
- 🔋 Battery Efficient: Optimized
- 🌐 Offline Support: Core features work offline
- ♿ Accessible: Screen reader support

---

**Created**: 2026-02-10  
**Version**: 7.0 - Modern Dark Edition  
**Status**: Design System Ready  
**Next**: Create Figma mockups and implement theme
