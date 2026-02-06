# 🔥 Firestore Index Setup Guide

## Overview
Your web app requires two composite indexes to be created in Firebase Firestore for optimal performance. These indexes are needed for pending payments and delayed subscriptions queries.

## Required Indexes

### 1. Pending Payments Index
**Collection:** `pending_payments`  
**Fields:** `status`, `userId`, `createdAt`, `__name__`  
**Order:** Ascending, Ascending, Ascending, Ascending

**Quick Setup URL:**
```
https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmFwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BlbmRpbmdfcGF5bWVudHMvaW5kZXhlcy9fEAEaCgoGc3RhdHVzEAEaCgoGdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

### 2. Delayed Subscriptions Index
**Collection:** `delayed_subscriptions`  
**Fields:** `status`, `activationDate`, `__name__`  
**Order:** Ascending, Ascending, Ascending

**Quick Setup URL:**
```
https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2RlbGF5ZWRfc3Vic2NyaXB0aW9ucy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoSCg5hY3RpdmF0aW9uRGF0ZRABGgwKCF9fbmFtZV9fEAE
```

## Setup Instructions

### Method 1: Direct URL (Recommended)
1. Click on the **Quick Setup URL** above for each index
2. The Firebase Console will open with the index pre-configured
3. Click **"Create Index"** button
4. Wait for the index to be built (usually takes 1-2 minutes)

### Method 2: Manual Setup
1. Go to [Firebase Console](https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes)
2. Click **"Create Index"**
3. Select the appropriate collection
4. Add the required fields in the correct order
5. Set all fields to "Ascending"
6. Click **"Create"**

## Benefits
- ✅ **Eliminates Firestore errors** in console logs
- ✅ **Improves query performance** for pending payments and subscriptions
- ✅ **Reduces Firebase costs** by optimizing database operations
- ✅ **Better user experience** with faster loading times

## Status
After creating these indexes, you should no longer see these error messages in your console:
- `❌ Error checking pending payments: [cloud_firestore/failed-precondition]`
- `❌ Error checking pending subscriptions: [cloud_firestore/failed-precondition]`

## Verification
Once the indexes are created and built, refresh your web app and check the browser console. The error messages should disappear, and you'll see successful completion messages instead.

---
*Created: $(date)*  
*Project: Impact Graphics ZA v2.0*
