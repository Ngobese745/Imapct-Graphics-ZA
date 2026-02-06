# Google Sign-In Fix Instructions for Android

## Problem
Google Sign-In is failing on Android with error code 10 (`DEVELOPER_ERROR`). This means the OAuth 2.0 client is not properly configured in the Firebase Console.

## Root Cause
The current app package name `com.impactgraphics.za.impact_graphics_za` does not have a properly configured Android OAuth client in the Firebase project.

## Current SHA-1 Fingerprint
```
B2:47:90:29:76:1A:32:45:6E:EE:38:95:AA:1C:0D:6A:2F:6C:5E:1F
```

## Solution - Configure OAuth Client in Firebase Console

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **impact-graphics-za-266ef**

### Step 2: Add Android OAuth Client
1. Go to **Project Settings** (gear icon)
2. Scroll down to **Your apps**
3. Find the Android app with package name: `com.impactgraphics.za.impact_graphics_za`
4. If it doesn't exist, click **Add app** and create it
5. Add the SHA-1 fingerprint:
   ```
   B2:47:90:29:76:1A:32:45:6E:EE:38:95:AA:1C:0D:6A:2F:6C:5E:1F
   ```

### Step 3: Enable Google Sign-In
1. Go to **Authentication** in the Firebase Console
2. Click on **Sign-in method** tab
3. Ensure **Google** is enabled

### Step 4: Download New google-services.json
1. In **Project Settings**, find your Android app
2. Click **Download google-services.json**
3. Replace the file at:
   ```
   /Volumes/work/Pre release/impact_graphics_za_production_backup_20251008_011440/android/app/google-services.json
   ```

### Step 5: Rebuild the App
```bash
cd "/Volumes/work/Pre release/impact_graphics_za_production_backup_20251008_011440"
flutter clean
flutter pub get
flutter run -d <device-id>
```

## Verification
The new `google-services.json` should have an entry like this for `com.impactgraphics.za.impact_graphics_za`:

```json
{
  "client_info": {
    "mobilesdk_app_id": "1:884752435887:android:...",
    "android_client_info": {
      "package_name": "com.impactgraphics.za.impact_graphics_za"
    }
  },
  "oauth_client": [
    {
      "client_id": "884752435887-4rf9jhikf4ht028d0gbikmvfgl2o13hr.apps.googleusercontent.com",
      "client_type": 1,
      "android_info": {
        "package_name": "com.impactgraphics.za.impact_graphics_za",
        "certificate_hash": "b2479029761a32456eee3895aa1c0d6a2f6c5e1f"
      }
    },
    {
      "client_id": "884752435887-f57pbhsivqj444gdf0anmhq5ld1krcj1.apps.googleusercontent.com",
      "client_type": 3
    }
  ]
}
```

## Alternative: Use Existing Package Name
If you prefer not to configure a new OAuth client, you could change your app's package name back to `com.delivery.impactgraphicsza`, which already has a working OAuth client configured.

## Code Changes Already Made
The following code changes have already been applied:
- ✅ `lib/services/google_signin_config.dart` - Configured `serverClientId` for Android
- ✅ `android/app/proguard-rules.pro` - Added Google Sign-In ProGuard rules
- ✅ `lib/widgets/guest_chatbot_widget.dart` - Guest chatbot is working
- ✅ `lib/main.dart` - Guest chatbot FAB added to guest screen

## Testing
After completing the Firebase Console configuration and downloading the new `google-services.json`:
1. The Google Sign-In should work without error code 10
2. Users should be able to sign in with their Google accounts
3. No warnings about `clientId` should appear in the logs



