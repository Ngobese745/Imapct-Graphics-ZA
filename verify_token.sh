#!/bin/bash

# Script to verify FCM token is saved
echo "🔍 Checking if FCM token is saved in Firestore..."
echo ""
echo "User ID: ql4Q5hcudNVg0CYemEQzGtGAm9p1"
echo ""
echo "Please check Firebase Console manually:"
echo "1. Go to: https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore"
echo "2. Click on 'users' collection"
echo "3. Find document: ql4Q5hcudNVg0CYemEQzGtGAm9p1"
echo "4. Look for field: fcmToken"
echo ""
echo "If fcmToken exists with a long string value → ✅ Ready for push notifications!"
echo "If fcmToken is missing or null → ❌ Need to debug further"
echo ""

