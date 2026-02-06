# 🔥 Firebase Billing Setup - Step-by-Step Guide

## 🎯 What We're Doing

Upgrading your Firebase project to **Blaze Plan** to enable Cloud Functions for push notifications.

**Time Required**: 5-10 minutes  
**Cost**: FREE (within free tier limits)  
**Result**: Real push notifications even when app is closed!

---

## 📋 Step-by-Step Instructions

### Step 1: Open Firebase Console

1. **Open your browser**
2. **Go to**: https://console.firebase.google.com/
3. **Login** with your Google account (if not already logged in)
4. You should see your Firebase projects listed

### Step 2: Select Your Project

1. **Click on**: **"IMPACT GRAPHICS ZA"** 
   - Project ID: `impact-graphics-za-266ef`
2. Wait for the project dashboard to load

### Step 3: Navigate to Billing Settings

**Option A** (Recommended):
1. Look at the **left sidebar**
2. Scroll down to find the ⚙️ **Settings** icon (gear icon)
3. Click on **"Usage and billing"**

**Option B** (Alternative):
1. Look at the **left sidebar**
2. Find **"Upgrade"** button/link
3. Click on it directly

### Step 4: Upgrade to Blaze Plan

You'll see a page comparing plans:

**Spark Plan (Current)** → **Blaze Plan (Target)**

1. **Look for**: "Blaze (Pay as you go)" plan
2. **Click**: **"Select plan"** or **"Upgrade"** button
3. You'll see a confirmation screen

### Step 5: Add Payment Method

1. **Google will ask for a payment method**:
   - Credit Card
   - Or Debit Card
   - Or Google Pay

2. **Fill in**:
   - Card number
   - Expiration date
   - CVV/Security code
   - Billing address

3. **Click**: **"Add payment method"** or **"Continue"**

### Step 6: Set Budget Alerts (Optional but Recommended)

1. **After adding payment method**, you'll see budget options
2. **Set a budget alert**: e.g., R50 or R100/month
3. This sends you an email if costs exceed your threshold
4. **Note**: You likely won't reach this with your app usage

### Step 7: Confirm Upgrade

1. **Review** the plan details
2. **Check**: "I understand the charges" (if shown)
3. **Click**: **"Purchase"** or **"Upgrade"** button
4. Wait for confirmation (usually instant)

### Step 8: Verify Upgrade

You should see:
- ✅ "Successfully upgraded to Blaze plan"
- Or a green checkmark/success message
- The sidebar should now show "Blaze plan"

---

## ✅ After Billing is Enabled

Once you see the confirmation, **STOP** and let me know!

I'll immediately run:
```bash
firebase deploy --only functions
```

This will:
1. Deploy the Cloud Functions (2-3 minutes)
2. Enable automatic push notifications
3. Make everything work!

---

## 💳 Payment Information

### What You'll Pay:

**Month 1-12**: $0.00 (FREE)  
**Ongoing**: $0.00/month (stays within free tier)

### Free Tier Limits (More than Enough):
- ✅ Cloud Functions: 2,000,000 invocations/month
- ✅ Your usage: ~1,000-5,000 invocations/month
- ✅ Firestore: 50,000 reads + 20,000 writes/day
- ✅ FCM Messages: **UNLIMITED & FREE**

### When Would You Pay?

Only if you exceed free tier:
- Over 2 million function calls/month
- Over 50K Firestore reads per day
- Very unlikely for your business size

### Typical Small Business Costs:
- Month 1-6: $0.00
- Month 7-12: $0.00 - $2.00
- After 1 year: $0.00 - $5.00/month (if growing rapidly)

---

## 🔒 Security Note

- Your card is stored securely by Google
- Google Cloud Platform handles all billing
- Same payment system as Google Ads, Google Cloud
- Can remove payment method anytime
- Can downgrade back to Spark plan anytime (but will lose Cloud Functions)

---

## 📞 Need Help?

### Common Issues:

**Issue 1: "Can't find Upgrade button"**
- Look in left sidebar
- Try clicking Settings → Usage and billing
- Or look for "Spark plan" badge at top

**Issue 2: "Payment declined"**
- Try a different card
- Check card has international payments enabled
- Contact your bank if needed

**Issue 3: "Upgrade button greyed out"**
- Make sure you're logged in with correct account
- Check you have admin access to the project
- Try logging out and back in

---

## 🎯 Quick Reference

### What to Click:
1. Firebase Console → Your Project
2. Settings (⚙️) → Usage and billing
3. Upgrade to Blaze
4. Add payment method
5. Confirm upgrade
6. ✅ Done!

---

## 📱 Contact Me When Done

Once you see the success message, come back here and say:

**"Billing enabled!"**

I'll immediately deploy the functions and test the push notifications!

---

## 🚀 Ready?

Open this link now:
**https://console.firebase.google.com/project/impact-graphics-za-266ef/overview**

Follow the steps above, and let me know when you see the "Successfully upgraded" message!

I'm here to help if you get stuck on any step. 🙌

