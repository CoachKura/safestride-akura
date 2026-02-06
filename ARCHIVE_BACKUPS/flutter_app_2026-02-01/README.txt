Akura SafeStride - Flutter Mobile App (Archived)
================================================

Date Archived: February 1, 2026
Status: 100% complete (6 screens: Dashboard, GPS Tracker, Logger, History, Profile, Home)
Technology: Dart + Flutter SDK 3.35.1

File Count: 830 files
Location: E:\Akura Safe Stride\safestride\ARCHIVE_BACKUPS\flutter_app_2026-02-01

Reason Archived:
----------------
- Strategic decision to use React PWA for unified website + mobile platform
- React PWA integrates with existing website codebase
- Avoids maintaining 3 separate codebases (Website, Flutter Android, Flutter iOS)
- Faster deployment and instant updates (no app store delays)
- Better for rapid iteration and testing
- Works on Android emulator via browser

Flutter App Features (Preserved):
---------------------------------
 6 Complete Screens
 GPS tracking service with Haversine distance calculation
 Supabase backend integration
 Authentication service
 Activity logging and management
 Bottom navigation with 5 tabs
 Material Design UI

Can be restored in future if native apps are needed.

Restoration Instructions:
------------------------
1. Copy this folder back to E:\Akura Safe Stride\safestride\akura_mobile
2. Run: flutter pub get
3. Run: flutter run

Active Project:
--------------
React PWA: E:\Akura Safe Stride\safestride\mobile_new
