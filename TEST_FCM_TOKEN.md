# 🧪 Test FCM Token - Quick Verification

## 🎯 Quick Test

I found that your FCM token isn't being saved. Let's fix and verify it!

---

## ⚡ IMMEDIATE STEPS

### Step 1: RESTART THE APP RIGHT NOW

**On your phone**:
1. **Close the app completely** (swipe up, swipe away)
2. **Wait 3 seconds**
3. **Open the app again**

### Step 2: Watch the Console/Terminal

Look for these messages:
```
=== NOTIFICATION SERVICE INITIALIZATION START ===
FCM Token: [long token string]
=== SAVING FCM TOKEN ===
User ID: ql4Q5hcudNVg0CYemEQzGtGAm9p1
Token: [first 20 characters]...
✅ FCM token saved successfully to Firestore
Verified saved token exists: true
```

**If you see "✅ FCM token saved successfully"** → Great! Token is saved ✅

**If you DON'T see this** → There's an issue, tell me what you see

---

## 🔍 Manual Verification (After Restart)

### Check Firestore Console:

1. **Open**: https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore
2. **Click**: `users` collection (left side)
3. **Find**: Document ID: `ql4Q5hcudNVg0CYemEQzGtGAm9p1`
4. **Look for**: Field called `fcmToken`

**Should look like**:
```
users/
  ql4Q5hcudNVg0CYemEQzGtGAm9p1/
    email: "your@email.com"
    fcmToken: "fR3h2kL9pQx..." ← Should have this!
    lastTokenUpdate: Timestamp
    name: "Your Name"
```

**If fcmToken exists** → ✅ Ready for push notifications!

**If fcmToken is missing** → ❌ Need to debug further

---

## 📱 Test Push Notification (After Token is Saved)

### Quick Test:

1. **Verify token exists** (check Firestore as above)
2. **Close the app completely**
3. **Lock your phone**
4. **On computer as admin**:
   - Go to Orders
   - Accept or decline an order
   - OR add a portfolio item
5. **Check your locked phone** (wait 10 seconds)
6. **Push notification should appear!** 🔔

---

## 🐛 If Token Still Not Saved

### Check Phone Permissions:

**Android**:
```
Settings → Apps → Impact Graphics ZA → Permissions
- Notifications: Allowed ✅
```

**iOS**:
```
Settings → Impact Graphics ZA
- Notifications: Allow ✅
```

### Try Force Re-requesting Permission:

Sometimes the app needs to re-request notification permission.

**Solution**:
1. Uninstall the app
2. Reinstall it
3. When it asks for notification permission → **Allow**
4. Login
5. Check console for "FCM token saved successfully"

---

## 🧪 Alternative: Manual Token Refresh

If restart doesn't work, we can manually trigger token refresh:

**Tell me if you want me to add a "Refresh FCM Token" button in settings.**

---

## 📊 Debug Information

From the function logs, I can see:

**✅ Working**:
- Function triggered correctly
- Order status detected (pending → accepted)
- Notification created in Firestore
- All data correct

**❌ Issue**:
- User document exists: YES
- FCM token exists: **NO** ← This is the problem!
- Token value: `undefined` or `null`

**Root Cause**:
- Token not being saved when app initializes
- Likely because `.update()` failed if field didn't exist
- Fixed to use `.set(merge: true)` now

---

## ✅ Fix Applied

I've updated the code to:
1. Use `.set(merge: true)` instead of `.update()`
2. Add extensive logging to track token saving
3. Verify token after saving
4. Better error handling

---

## 🎯 WHAT TO DO RIGHT NOW

### 1. Close the app on your phone
### 2. Wait 3 seconds  
### 3. Open the app again
### 4. Check console for "FCM token saved successfully"
### 5. Tell me if you see it!

---

## 📞 Report Back

After restarting, tell me:

**Option A**: "I see: ✅ FCM token saved successfully"  
→ Great! Let's test push notifications!

**Option B**: "I don't see that message"  
→ Share what you DO see in console, I'll help debug

**Option C**: "I see errors"  
→ Share the error message, I'll fix it

---

**RESTART THE APP NOW AND CHECK THE CONSOLE!** 🚀

The fix is deployed - we just need the app to run with the new code and save your FCM token!

