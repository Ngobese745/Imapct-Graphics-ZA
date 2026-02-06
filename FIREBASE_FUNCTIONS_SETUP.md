# Firebase Functions Setup Guide - Push Notifications

## 🚀 Overview

This guide will help you deploy Firebase Cloud Functions to enable **true push notifications** that work even when the app is closed or the phone is locked.

## 📋 Prerequisites

1. **Firebase CLI** installed globally
2. **Node.js** (version 18 or higher)
3. **Firebase project** already set up

## 🔧 Installation Steps

### Step 1: Install Firebase CLI (if not already installed)
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Initialize Firebase Functions
```bash
cd functions
npm install
```

### Step 4: Deploy Firebase Functions
```bash
firebase deploy --only functions
```

## 📱 How It Works

### **Automatic Notifications:**
- When an admin changes an order status to "accepted", "declined", "completed", or "in_progress"
- The Firebase Function automatically sends a push notification to the user
- Works even if the app is closed or phone is locked

### **Manual Notifications:**
- Admins can send notifications from the admin dashboard
- Notifications are sent via Firebase Cloud Messaging (FCM)
- Users receive notifications immediately

## 🔄 Notification Flow

1. **User places order** → Order stored in Firestore
2. **Admin changes order status** → Firebase Function triggered
3. **Function sends push notification** → User receives notification
4. **User can tap notification** → App opens to relevant screen

## 📊 Supported Notification Types

### **Order Notifications:**
- ✅ Order Accepted
- ❌ Order Declined  
- 🎉 Order Completed
- 🔄 Order In Progress

### **Payment Notifications:**
- 💳 Payment Successful
- ❌ Payment Failed

### **System Notifications:**
- 📢 Announcements
- 🔧 Maintenance Updates
- 🎨 New Services

## 🛠️ Testing

### **Test Local Notifications:**
1. Open the app
2. Go to Admin Dashboard
3. Click the notification bell icon
4. Check for local notification

### **Test Push Notifications:**
1. Deploy Firebase Functions
2. Create a test order
3. Change order status in admin dashboard
4. Check for push notification (even with app closed)

## 🔧 Configuration Files

### **functions/index.js**
- Contains all Firebase Cloud Functions
- Handles push notification sending
- Manages order status change triggers

### **functions/package.json**
- Dependencies for Firebase Functions
- Node.js version specification

### **firebase.json**
- Firebase project configuration
- Functions deployment settings

## 🚨 Troubleshooting

### **Common Issues:**

1. **Functions not deploying:**
   ```bash
   firebase functions:log
   ```

2. **Notifications not received:**
   - Check FCM token is saved in Firestore
   - Verify notification permissions on device
   - Check Firebase Console for errors

3. **Permission denied:**
   ```bash
   firebase login --reauth
   ```

### **Debug Steps:**
1. Check Firebase Console → Functions → Logs
2. Verify FCM tokens in Firestore
3. Test with Firebase Console → Cloud Messaging
4. Check device notification settings

## 📈 Monitoring

### **Firebase Console:**
- Functions → Logs (for function execution)
- Cloud Messaging → Analytics (for delivery rates)
- Firestore → Data (for FCM tokens)

### **App Logs:**
- Check Flutter console for FCM token generation
- Monitor notification permission status
- Track notification delivery success/failure

## 🔐 Security

### **Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Orders can be read by user and admin
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
      allow write: if request.auth != null;
    }
  }
}
```

## 🎯 Next Steps

1. **Deploy the functions** using the commands above
2. **Test with a real order** to verify push notifications work
3. **Monitor the logs** to ensure everything is working correctly
4. **Customize notification messages** as needed

## 📞 Support

If you encounter any issues:
1. Check the Firebase Console logs
2. Verify all dependencies are installed
3. Ensure Firebase project is properly configured
4. Test with Firebase Console's Cloud Messaging feature

---

**🎉 Congratulations!** Your app now supports true push notifications that work even when the app is closed!
