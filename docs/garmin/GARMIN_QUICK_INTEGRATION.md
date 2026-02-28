# 🚀 Quick Integration Guide - Garmin to SafeStride App

## Step 1: Add to Profile Screen

Update `lib/screens/profile_screen.dart` to include Garmin connection option:

```dart
// Import the Garmin screen
import 'garmin_connect_screen.dart';

// In your Profile/Settings screen, add this option:
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF0066CC).withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.watch,
      color: Color(0xFF0066CC),
      size: 24,
    ),
  ),
  title: const Text('Garmin Connect'),
  subtitle: const Text('Sync your Garmin devices'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Show connection status
      FutureBuilder<bool>(
        future: GarminOAuthService().isConnected(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      const SizedBox(width: 8),
      const Icon(Icons.arrow_forward_ios, size: 16),
    ],
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GarminConnectScreen(),
      ),
    );
  },
)
```

## Step 2: Add to Main Navigation (Optional)

If you want quick access from bottom nav or drawer:

```dart
// In your navigation menu
IconButton(
  icon: const Icon(Icons.watch),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GarminConnectScreen(),
      ),
    );
  },
  tooltip: 'Garmin Connect',
)
```

## Step 3: Add Deep Link Handler

Update `lib/main.dart` to handle Garmin OAuth callback:

```dart
void _handleDeepLink(Uri uri) {
  developer.log('Received deep link: $uri');

  // Handle Garmin OAuth callback
  if (uri.scheme == 'io.supabase.safestride' && 
      uri.host == 'garmin-callback') {
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      developer.log('Garmin OAuth error: $error');
    } else if (code != null) {
      developer.log('Received Garmin authorization code: $code');
      final garminService = GarminOAuthService();
      garminService.exchangeCodeForToken(
        code,
        'io.supabase.safestride://garmin-callback',
      ).then((success) {
        developer.log('Garmin connection ${success ? 'successful' : 'failed'}');
      });
    }
  }

  // Existing Strava handler...
}
```

## Step 4: Deploy Database Migration

```bash
# Connect to your Supabase project
cd database

# Run migration (use Supabase SQL Editor or psql)
# Copy contents of migration_garmin_integration.sql and execute
```

Or via Supabase Dashboard:
1. Open SQL Editor
2. Copy `database/migration_garmin_integration.sql`
3. Paste and Run

## Step 5: Test the Integration

### Test Data Field on Simulator
```powershell
cd garmin_connectiq\AISRIZoneMonitor
.\Build-Simulator.ps1
```

### Test UI Flow
1. Run app: `flutter run`
2. Navigate to Profile → Garmin Connect
3. Verify UI displays correctly
4. Test connection button (will show browser flow)

### Test Database
```sql
-- Check tables exist
SELECT * FROM garmin_connections LIMIT 1;
SELECT * FROM garmin_activities LIMIT 1;
SELECT * FROM garmin_pushed_workouts LIMIT 1;
SELECT * FROM garmin_devices LIMIT 1;
```

## Step 6: Apply for Garmin API

1. Go to: https://developer.garmin.com/
2. Sign up for developer account
3. Create new application:
   - Name: AKURA SafeStride
   - Type: OAuth Application
   - Redirect URI: `io.supabase.safestride://garmin-callback`
   - Scopes: activity:read, activity:write, workouts:read, workouts:write
4. Wait for approval (2-4 weeks)
5. Update OAuth credentials in `garmin_oauth_service.dart`

## Step 7: Submit Connect IQ Data Field

1. Build for production:
   ```powershell
   cd garmin_connectiq\AISRIZoneMonitor
   .\Build-And-Deploy.ps1
   ```

2. Create Connect IQ Store listing:
   - Screenshots from real device
   - Description (see MARKETING.md)
   - Category: Running
   - Price: Free (or $1.99)

3. Submit for review
4. Wait 1-2 weeks for approval

## Complete! 🎉

Your Garmin integration is now live. Users can:
- ✅ Connect their Garmin accounts
- ✅ Sync activities automatically
- ✅ Push workouts to their watches
- ✅ Use AISRI Zone data field during runs

---

## Troubleshooting

### "OAuth error: invalid_client"
- Garmin API not approved yet
- Check client ID and secret
- Verify redirect URI matches exactly

### "No devices found"
- User hasn't synced watch to Garmin Connect
- Check Garmin Connect app is up to date
- Verify API permissions include device access

### Data field won't install
- Check Connect IQ version compatibility
- Verify device is on compatibility list
- Try restarting watch

### Database errors
- Verify RLS policies are enabled
- Check user is authenticated
- Inspect Supabase logs

---

**Need Help?** Check `GARMIN_INTEGRATION_STATUS.md` for full documentation.
