# Firebase Remote Config - Quick Start Guide 🚀

## ⚡ 5-Minute Setup

### **Step 1: Open Firebase Console**
👉 **Click here**: https://console.firebase.google.com/project/impact-graphics-za-266ef/config

---

### **Step 2: Add These 5 Parameters**

Click "Add parameter" and copy these **EXACTLY**:

#### **1️⃣ Banner Visibility**
```
Parameter key: show_development_banner
Data type: Boolean
Default value: ON (true)
```

#### **2️⃣ Banner Title**
```
Parameter key: development_banner_title
Data type: String
Default value: 🚧 App Under Development
```

#### **3️⃣ Banner Message**
```
Parameter key: development_banner_message
Data type: String
Default value: We're still working on improving your experience! Report any issues or suggestions via the menu.
```

#### **4️⃣ Banner Color**
```
Parameter key: development_banner_color
Data type: String
Default value: #FF6B35
```

#### **5️⃣ Text Color**
```
Parameter key: development_banner_text_color
Data type: String
Default value: #FFFFFF
```

---

### **Step 3: Publish**
1. Click **"Publish changes"** button (top right)
2. Confirm
3. Done! ✅

---

### **Step 4: Test**
1. Open app: https://impact-graphics-za-266ef.web.app
2. Refresh page
3. You should see the orange banner! 🎉

---

## 🎯 Quick Actions

### **Hide the banner:**
```
show_development_banner: false
→ Publish changes
```

### **Change to red:**
```
development_banner_color: #8B0000
→ Publish changes
```

### **Change to blue:**
```
development_banner_color: #1976D2
→ Publish changes
```

### **Change message:**
```
development_banner_message: Your new message here
→ Publish changes
```

---

## 📋 Copy-Paste Values

**Parameter Keys (copy one at a time):**
```
show_development_banner
development_banner_title
development_banner_message
development_banner_color
development_banner_text_color
```

**Default Values (copy one at a time):**
```
true
🚧 App Under Development
We're still working on improving your experience! Report any issues or suggestions via the menu.
#FF6B35
#FFFFFF
```

---

## 🎨 Color Codes (copy to use)

```
Orange:  #FF6B35
Red:     #8B0000
Blue:    #1976D2
Green:   #388E3C
Purple:  #7B1FA2
Yellow:  #FFA000
```

---

## ✅ Checklist

- [ ] Open Firebase Console
- [ ] Add 5 parameters
- [ ] Click "Publish changes"
- [ ] Test in app

---

## 🆘 Need Help?

See detailed guide: `FIREBASE_REMOTE_CONFIG_BANNER_SETUP_GUIDE.md`

**Firebase Console**: https://console.firebase.google.com/project/impact-graphics-za-266ef/config

**Your App**: https://impact-graphics-za-266ef.web.app

---

**That's it! You're done! 🎉**



