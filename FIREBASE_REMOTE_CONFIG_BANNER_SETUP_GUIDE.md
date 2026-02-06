# Firebase Remote Config - Development Banner Setup Guide

## Quick Access
**Firebase Console Remote Config**: https://console.firebase.google.com/project/impact-graphics-za-266ef/config

---

## 📋 Step-by-Step Setup Instructions

### **Step 1: Open Firebase Console**
1. Click this link: https://console.firebase.google.com/project/impact-graphics-za-266ef/config
2. You should see the "Remote Config" page
3. Look for the "Add parameter" button

### **Step 2: Add Banner Parameters**

You need to add **5 parameters** total. Here's how to add each one:

---

## ✅ Parameter 1: Banner Visibility (Toggle)

**Click "Add parameter"** and enter:

```
Parameter key: show_development_banner
```

**Then:**
1. Select **"Boolean"** from the data type dropdown
2. Toggle the switch to **ON** (true)
3. (Optional) Add description: "Toggle to show/hide the development banner"
4. Click **"Add parameter"** or **"Save"**

**Visual:**
```
┌─────────────────────────────────────────────┐
│ Parameter key: show_development_banner      │
│ Data type: [Boolean ▼]                      │
│ Default value: [●ON  ○OFF]                  │
│ Description: Toggle to show/hide...         │
│                                  [Add]       │
└─────────────────────────────────────────────┘
```

---

## 📝 Parameter 2: Banner Title

**Click "Add parameter"** and enter:

```
Parameter key: development_banner_title
```

**Then:**
1. Select **"String"** from the data type dropdown
2. In the text box, enter: `🚧 App Under Development`
3. (Optional) Add description: "The title text displayed in the banner"
4. Click **"Add parameter"** or **"Save"**

**Visual:**
```
┌─────────────────────────────────────────────┐
│ Parameter key: development_banner_title     │
│ Data type: [String ▼]                       │
│ Default value:                               │
│ ┌─────────────────────────────────────────┐ │
│ │ 🚧 App Under Development                │ │
│ └─────────────────────────────────────────┘ │
│ Description: The title text...              │
│                                  [Add]       │
└─────────────────────────────────────────────┘
```

---

## 💬 Parameter 3: Banner Message

**Click "Add parameter"** and enter:

```
Parameter key: development_banner_message
```

**Then:**
1. Select **"String"** from the data type dropdown
2. In the text box, enter: `We're still working on improving your experience! Report any issues or suggestions via the menu.`
3. (Optional) Add description: "The message text displayed in the banner"
4. Click **"Add parameter"** or **"Save"**

**Visual:**
```
┌─────────────────────────────────────────────┐
│ Parameter key: development_banner_message   │
│ Data type: [String ▼]                       │
│ Default value:                               │
│ ┌─────────────────────────────────────────┐ │
│ │ We're still working on improving your   │ │
│ │ experience! Report any issues or        │ │
│ │ suggestions via the menu.               │ │
│ └─────────────────────────────────────────┘ │
│ Description: The message text...            │
│                                  [Add]       │
└─────────────────────────────────────────────┘
```

---

## 🎨 Parameter 4: Banner Background Color

**Click "Add parameter"** and enter:

```
Parameter key: development_banner_color
```

**Then:**
1. Select **"String"** from the data type dropdown
2. In the text box, enter: `#FF6B35`
3. (Optional) Add description: "Background color of the banner (hex format)"
4. Click **"Add parameter"** or **"Save"**

**Visual:**
```
┌─────────────────────────────────────────────┐
│ Parameter key: development_banner_color     │
│ Data type: [String ▼]                       │
│ Default value:                               │
│ ┌─────────────────────────────────────────┐ │
│ │ #FF6B35                                 │ │
│ └─────────────────────────────────────────┘ │
│ Description: Background color (hex format)  │
│                                  [Add]       │
└─────────────────────────────────────────────┘
```

**Color Preview:**
- `#FF6B35` = 🟠 Orange (recommended for development)

---

## 🎨 Parameter 5: Banner Text Color

**Click "Add parameter"** and enter:

```
Parameter key: development_banner_text_color
```

**Then:**
1. Select **"String"** from the data type dropdown
2. In the text box, enter: `#FFFFFF`
3. (Optional) Add description: "Text color of the banner (hex format)"
4. Click **"Add parameter"** or **"Save"**

**Visual:**
```
┌─────────────────────────────────────────────┐
│ Parameter key: development_banner_text_color│
│ Data type: [String ▼]                       │
│ Default value:                               │
│ ┌─────────────────────────────────────────┐ │
│ │ #FFFFFF                                 │ │
│ └─────────────────────────────────────────┘ │
│ Description: Text color (hex format)        │
│                                  [Add]       │
└─────────────────────────────────────────────┘
```

**Color Preview:**
- `#FFFFFF` = ⚪ White (recommended for text)

---

## 🚀 Step 3: Publish Changes

**IMPORTANT**: After adding all 5 parameters, you must publish them!

1. Look for the **"Publish changes"** button (usually at the top right)
2. Click **"Publish changes"**
3. Confirm the publication
4. Wait for confirmation message

**Visual:**
```
┌─────────────────────────────────────────────┐
│ Remote Config                               │
│                        [Publish changes] ✓  │
├─────────────────────────────────────────────┤
│ Parameters (5)                              │
│ ✓ show_development_banner        true      │
│ ✓ development_banner_title       🚧 App... │
│ ✓ development_banner_message     We're...  │
│ ✓ development_banner_color       #FF6B35   │
│ ✓ development_banner_text_color  #FFFFFF   │
└─────────────────────────────────────────────┘
```

---

## ✅ Step 4: Verify Setup

After publishing, verify all parameters are visible:

**You should see:**
```
✓ show_development_banner        Boolean  true
✓ development_banner_title       String   🚧 App Under Development
✓ development_banner_message     String   We're still working on...
✓ development_banner_color       String   #FF6B35
✓ development_banner_text_color  String   #FFFFFF
```

---

## 🧪 Testing the Banner

### **Test 1: Verify Banner Appears**
1. Open your app: https://impact-graphics-za-266ef.web.app
2. You should see the orange banner at the top
3. Banner should say "🚧 App Under Development"

### **Test 2: Verify Banner Click**
1. Click anywhere on the banner
2. Should navigate to the suggestions screen

### **Test 3: Verify Banner Dismiss**
1. Click the "×" button on the banner
2. Banner should disappear
3. Refresh page - banner should reappear

### **Test 4: Hide Banner Remotely**
1. In Firebase Console, change `show_development_banner` to `false`
2. Click "Publish changes"
3. Refresh your app
4. Banner should NOT appear

### **Test 5: Change Banner Color**
1. In Firebase Console, change `development_banner_color` to `#8B0000` (red)
2. Click "Publish changes"
3. Refresh your app
4. Banner should now be red instead of orange

---

## 🎨 Color Reference

### **Pre-defined Colors**

| Color Name | Hex Code | Preview | Use Case |
|------------|----------|---------|----------|
| Orange     | `#FF6B35` | 🟠 | Development (current) |
| Red        | `#8B0000` | 🔴 | Alert/Warning |
| Blue       | `#1976D2` | 🔵 | Information |
| Green      | `#388E3C` | 🟢 | Success |
| Purple     | `#7B1FA2` | 🟣 | Premium |
| Yellow     | `#FFA000` | 🟡 | Warning |
| Dark Gray  | `#424242` | ⚫ | Neutral |
| Teal       | `#00897B` | 🔷 | Modern |

### **How to Change Colors**
1. Copy the hex code from the table above
2. In Firebase Console, find `development_banner_color`
3. Click to edit
4. Paste the new hex code
5. Click "Publish changes"

---

## 📝 Example Configurations

### **Example 1: Beta Testing Banner**
```
show_development_banner: true
development_banner_title: ⚠️ Beta Version
development_banner_message: You're testing our new features! Report bugs via the menu.
development_banner_color: #FFA000
development_banner_text_color: #000000
```

### **Example 2: Maintenance Notice**
```
show_development_banner: true
development_banner_title: 🔧 Scheduled Maintenance
development_banner_message: We'll be performing maintenance tonight from 10 PM - 2 AM.
development_banner_color: #1976D2
development_banner_text_color: #FFFFFF
```

### **Example 3: New Features Announcement**
```
show_development_banner: true
development_banner_title: ✨ New Features Available!
development_banner_message: Check out our latest updates! Share your feedback via suggestions.
development_banner_color: #7B1FA2
development_banner_text_color: #FFFFFF
```

### **Example 4: Hide Banner**
```
show_development_banner: false
```

---

## 🔄 Update Frequency

**How often does the app check for Remote Config updates?**
- **On App Start**: Always fetches latest config
- **During App Use**: Every 1 hour (default)
- **Manual Refresh**: Users can force refresh by restarting the app

**To see changes immediately:**
1. Make changes in Firebase Console
2. Publish changes
3. Refresh/restart the app

---

## 🛠️ Troubleshooting

### **Problem: Banner not showing**
**Solution:**
1. Check `show_development_banner` is set to `true`
2. Verify you clicked "Publish changes"
3. Refresh the app or clear cache
4. Check browser console for errors

### **Problem: Banner shows wrong color**
**Solution:**
1. Verify hex code is correct format: `#RRGGBB`
2. Make sure you didn't include spaces
3. Check you published the changes
4. Try a different color to test

### **Problem: Changes not appearing**
**Solution:**
1. Wait up to 1 hour for automatic update
2. Or refresh/restart the app
3. Clear browser cache
4. Verify changes were published (not saved as draft)

### **Problem: Banner text is cut off**
**Solution:**
1. Make message shorter
2. Or let it wrap to multiple lines (it should automatically)
3. Test on different screen sizes

---

## 📱 Quick Reference Card

### **To Show Banner:**
```
show_development_banner: true
```

### **To Hide Banner:**
```
show_development_banner: false
```

### **To Change Color:**
```
development_banner_color: #YOUR_HEX_CODE
```

### **To Change Text:**
```
development_banner_title: Your New Title
development_banner_message: Your new message
```

---

## 🔗 Useful Links

### **Firebase Console**
- **Remote Config**: https://console.firebase.google.com/project/impact-graphics-za-266ef/config
- **Project Overview**: https://console.firebase.google.com/project/impact-graphics-za-266ef/overview
- **Hosting**: https://console.firebase.google.com/project/impact-graphics-za-266ef/hosting

### **Your App**
- **Live URL**: https://impact-graphics-za-266ef.web.app
- **Documentation**: See `DEVELOPMENT_BANNER_FEATURE_COMPLETE.md`

### **Color Tools**
- **HTML Color Picker**: https://htmlcolorcodes.com/color-picker/
- **Material Design Colors**: https://materialui.co/colors/
- **Color Contrast Checker**: https://webaim.org/resources/contrastchecker/

---

## 📊 All Parameters Summary

| Parameter Key | Type | Default Value | Description |
|--------------|------|---------------|-------------|
| `show_development_banner` | Boolean | `true` | Toggle banner visibility |
| `development_banner_title` | String | `🚧 App Under Development` | Banner title text |
| `development_banner_message` | String | `We're still working on...` | Banner message text |
| `development_banner_color` | String | `#FF6B35` | Background color (hex) |
| `development_banner_text_color` | String | `#FFFFFF` | Text color (hex) |

---

## ✅ Setup Checklist

Use this checklist to ensure everything is configured correctly:

- [ ] Opened Firebase Console Remote Config page
- [ ] Added `show_development_banner` (Boolean) = `true`
- [ ] Added `development_banner_title` (String) = `🚧 App Under Development`
- [ ] Added `development_banner_message` (String) = `We're still working on...`
- [ ] Added `development_banner_color` (String) = `#FF6B35`
- [ ] Added `development_banner_text_color` (String) = `#FFFFFF`
- [ ] Clicked "Publish changes"
- [ ] Refreshed app to verify banner appears
- [ ] Tested clicking banner (navigates to suggestions)
- [ ] Tested dismissing banner (click ×)
- [ ] Tested hiding banner remotely (`show_development_banner` = `false`)

---

## 🎉 You're All Set!

Once you've completed all the steps above, your development banner will be live and fully functional. Users will see the banner when they open the app, and you can update it anytime without deploying a new version!

**Need help?** Check the troubleshooting section or refer to:
- `DEVELOPMENT_BANNER_FEATURE_COMPLETE.md`
- `FIREBASE_REMOTE_CONFIG_SETUP.md`

**Happy configuring!** 🚀✨



