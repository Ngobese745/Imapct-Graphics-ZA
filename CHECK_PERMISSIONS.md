# 🔐 Check Firebase Permissions

## Your Current Login

**Email**: colane.comfort.5@gmail.com

You need to verify this account has the correct permissions to deploy Cloud Functions.

---

## ✅ Check Your Permissions

### Step 1: Open IAM & Admin

**Click this link**:
```
https://console.cloud.google.com/iam-admin/iam?project=impact-graphics-za-266ef
```

### Step 2: Find Your Email

Look for: **colane.comfort.5@gmail.com** in the list

### Step 3: Check Your Role

You need ONE of these roles:
- ✅ **Owner**
- ✅ **Editor**
- ✅ **Cloud Functions Admin**
- ✅ **Firebase Admin**

### Step 4: If You DON'T Have These Roles

**You'll need to add the role:**

1. **Click** "GRANT ACCESS" button (top right)
2. **Enter** your email: colane.comfort.5@gmail.com
3. **Select role**: 
   - Choose "Editor" (recommended)
   - Or "Cloud Functions Admin"
4. **Click** "SAVE"

---

## 🔍 What to Look For

In the IAM page, you should see something like:

```
Member                        Role
colane.comfort.5@gmail.com    Editor
                             (or Owner/Cloud Functions Admin)
```

If you see your email with "Viewer" or no role, that's the problem!

---

## 📸 Take a Screenshot

Can you:
1. Open the IAM page (link above)
2. Find your email (colane.comfort.5@gmail.com)
3. Tell me what **role** it shows?

This will help me understand the exact issue!

