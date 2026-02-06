# 🐛 Portfolio Navigation Debugging Guide

## 🔍 How to Debug

### Step 1: Restart the App
**Important**: You must restart the app for the new callbacks to be registered!

```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za"
# Stop the app completely and restart it
```

### Step 2: Check Console on App Start
When the app starts, you should see:
```
=== SETTING UP PORTFOLIO NAVIGATION CALLBACK (User Dashboard) ===
Callback set successfully for user dashboard
```

Or if you're an admin:
```
=== SETTING UP PORTFOLIO NAVIGATION CALLBACK (Admin Dashboard) ===
Callback set successfully for admin dashboard
```

### Step 3: Click "View Details" on Notification
When you click the "View Details" button, watch the console. You should see:

```
=== NOTIFICATION NAVIGATION HANDLER ===
Type: portfolio_update
Action: view_portfolio
Data: {type: portfolio_update, action: view_portfolio, ...}
Portfolio update notification detected!
=== GENERAL NOTIFICATION HANDLER ===
Action: view_portfolio
Callback set: true
View portfolio action detected!
Calling navigation callback...
=== PORTFOLIO NAVIGATION CALLBACK TRIGGERED (User) ===
Current index before: 0
Navigating to Services Hub (index 1)
Current index after: 1
Navigation callback called
```

---

## ❌ Common Issues & Solutions

### Issue 1: No Logs Appear
**Problem**: Console is empty when clicking "View Details"  
**Solution**: 
1. Make sure you're viewing the console/logs
2. Restart the app completely
3. Try running: `flutter logs`

### Issue 2: Callback Shows as `false`
**Problem**: Logs show `Callback set: false`  
**Solution**:
1. Restart the app (callbacks set in initState)
2. Check you're on the correct dashboard (user vs admin)

### Issue 3: Wrong Type or Action
**Problem**: Logs show different type/action than expected  
**Solution**:
1. Check Firestore `notifications` collection
2. Verify notification has:
   - `type: 'portfolio_update'`
   - `action: 'view_portfolio'`

### Issue 4: Callback Not Triggered
**Problem**: Logs stop at "Calling navigation callback..."  
**Solution**:
1. Check if callback is actually set (should show `true`)
2. Verify `setState` is being called
3. Try adding a print statement in the callback

---

## 🔧 Manual Test

### Test if Callback is Set:
Add this temporary button in your dashboard to test:

```dart
ElevatedButton(
  onPressed: () {
    print('Testing portfolio navigation...');
    NotificationService.navigateToPortfolio();
  },
  child: Text('Test Navigate to Portfolio'),
)
```

If this works, the callback is set correctly.

---

## 📊 What Each Log Means

| Log Message | Meaning |
|------------|---------|
| `SETTING UP PORTFOLIO NAVIGATION CALLBACK` | Dashboard is registering callback |
| `Callback set successfully` | Callback registration complete |
| `NOTIFICATION NAVIGATION HANDLER` | Notification was tapped |
| `Type: portfolio_update` | Correct notification type |
| `Action: view_portfolio` | Correct action |
| `Portfolio update notification detected!` | Type matched in switch |
| `GENERAL NOTIFICATION HANDLER` | Routing to general handler |
| `Callback set: true` | Callback is available |
| `View portfolio action detected!` | Action matched in switch |
| `Calling navigation callback...` | About to trigger navigation |
| `PORTFOLIO NAVIGATION CALLBACK TRIGGERED` | Callback executed |
| `Current index before: 0` | Was on Home |
| `Current index after: 1` | Now on Services Hub |

---

## 🧪 Step-by-Step Debugging

### 1. Verify Server is Running
```bash
pm2 status
# Should show link-preview-server as online
```

### 2. Restart the App
- Completely close the app
- Restart it fresh
- This ensures callbacks are registered

### 3. Add Portfolio Item (as admin)
- Go to Service Hub
- Click "Add Portfolio Item"
- Paste a URL
- Let it autofill
- Click "Add Portfolio Item"

### 4. Check Notification (as user)
- Notification should appear
- Title: "New Portfolio Item Added!"
- Badge: "SYSTEM"
- Buttons: "Close" and "View Details"

### 5. Click "View Details"
- Click the button
- Watch the console for logs
- App should navigate to Services Hub

### 6. Check Console Logs
Look for the log sequence above. If any step is missing, that's where the issue is.

---

## 🔍 Detailed Troubleshooting

### If Logs Show Type is Wrong:
**Check Firestore**:
```
Collection: notifications
Document: (notification ID)
Field 'type': Should be 'portfolio_update'
Field 'action': Should be 'view_portfolio'
```

### If Callback is Null:
**Check initState**:
- Verify `_setupPortfolioNotificationCallback()` is called
- Check logs for "SETTING UP PORTFOLIO NAVIGATION CALLBACK"
- If not present, callback wasn't registered

### If Navigation Doesn't Happen:
**Check setState**:
- Logs should show "Current index after: 1"
- If stuck at 0, setState might not be working
- Try hot restart instead of hot reload

---

## 🚀 Quick Fix Script

Save this as `test_notification_nav.dart` in lib/screens:

```dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class TestNotificationNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Navigation')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            print('Test button clicked');
            NotificationService.navigateToPortfolio({'test': 'data'});
          },
          child: Text('Test Portfolio Navigation'),
        ),
      ),
    );
  }
}
```

Add to your dashboard temporarily to test if navigation works.

---

## 📱 Expected Console Output (Complete Flow)

```
[App Start]
=== SETTING UP PORTFOLIO NAVIGATION CALLBACK (User Dashboard) ===
Callback set successfully for user dashboard

[Admin Adds Portfolio Item]
=== SENDING LOCAL NOTIFICATION ===
Title: New Portfolio Item Added!
Body: Check out our latest work: ...
Type: portfolio_update
Action: view_portfolio

[User Clicks "View Details"]
Local notification tapped: {"type":"portfolio_update","action":"view_portfolio",...}
=== NOTIFICATION NAVIGATION HANDLER ===
Type: portfolio_update
Action: view_portfolio
Data: {type: portfolio_update, action: view_portfolio, ...}
Portfolio update notification detected!
=== GENERAL NOTIFICATION HANDLER ===
Action: view_portfolio
Callback set: true
View portfolio action detected!
Calling navigation callback...
=== PORTFOLIO NAVIGATION CALLBACK TRIGGERED (User) ===
Current index before: 0
Navigating to Services Hub (index 1)
Current index after: 1
Navigation callback called
```

---

## ✅ Next Steps

1. **Restart the app completely** (don't use hot reload)
2. **Click "View Details" on a notification**
3. **Check the console logs**
4. **Share the logs** if it still doesn't work

The detailed logs will show exactly where the navigation is failing!

---

## 🔄 If Still Not Working

Run the app with verbose logging:
```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za"
flutter run --verbose
```

Then click "View Details" and send me the console output.

