# MailerSend Extension Auto-Configuration Guide

## Status: ⚠️ Manual Configuration Required

The auto-configuration script encountered some Firebase CLI limitations. Here's the manual configuration process:

---

## 🚀 **Quick Fix: Manual Configuration**

### **Step 1: Open Firebase Console**
```
https://console.firebase.google.com/project/impact-graphics-za-266ef/extensions
```

### **Step 2: Find MailerSend Extension**
- Look for `mailersend-email` in the extensions list
- Click on it to open the extension details

### **Step 3: Click "Reconfigure"**
- Click the "Reconfigure" button
- This will open the configuration wizard

### **Step 4: Enter Configuration**
When prompted, enter these values:

```
Cloud Functions location: us-central1
Emails documents collection: emails
MailerSend API key: mlsn.45bb9103d2b0f627e4648d9655ced8ab656be77811c94f16bbfdbc7e957b1b4c
Default FROM email address: info@impactgraphicsza.co.za
Default FROM name: Impact Graphics ZA
Default reply to email address: admin@impactgraphicsza.co.za
Default reply to name: Impact Graphics ZA Support
Default template ID: (leave empty)
```

### **Step 5: Save and Wait**
- Click "Save" or "Deploy"
- Wait 2-3 minutes for the extension to redeploy

---

## 🧪 **Test the Configuration**

### **Method 1: Firebase Console Test**

1. **Go to Firestore**: https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore
2. **Navigate to `emails` collection**
3. **Add a new document** with this content:

```json
{
  "to": [
    {
      "email": "your-email@example.com",
      "name": "Test User"
    }
  ],
  "subject": "Test Email from Impact Graphics ZA",
  "html": "<h1>Test Email</h1><p>This is a test email from the MailerSend extension.</p><p>If you receive this, the email system is working!</p>",
  "text": "Test Email\n\nThis is a test email from the MailerSend extension.\n\nIf you receive this, the email system is working!",
  "tags": ["test", "configuration"],
  "created_at": "2025-10-20T01:53:06Z"
}
```

4. **Watch for changes**: The document should get a `delivery` field with status information
5. **Check your email inbox**

### **Method 2: App Test**

1. **Use your app** to send a proposal email
2. **Check Firestore** for new documents in the `emails` collection
3. **Monitor logs** for extension activity

---

## 📊 **Monitor Extension Activity**

### **Check Extension Logs**
```bash
firebase functions:log --project impact-graphics-za-266ef | grep -i mailersend
```

### **Check Extension Status**
```bash
firebase ext:list --project impact-graphics-za-266ef
```

---

## 🔍 **Troubleshooting**

### **If Extension Still Not Working**

1. **Check Service Account**: The extension service account might not exist yet
2. **Wait Longer**: Extension redeployment can take 5-10 minutes
3. **Check API Key**: Verify the API key is valid in MailerSend dashboard

### **If Emails Stay Pending**

1. **Check Extension Logs**: Look for error messages
2. **Verify API Key**: Ensure it has proper permissions in MailerSend
3. **Check Domain**: Ensure sender domain is verified

---

## 📧 **What Will Work After Configuration**

- ✅ **Proposal Emails**: From proposal screen
- ✅ **Welcome Emails**: When new users sign up  
- ✅ **Payment Confirmations**: After successful payments
- ✅ **Appointment Reminders**: From appointments screen
- ✅ **Invoice Emails**: For package subscriptions

---

## 🎯 **Expected Timeline**

- **Configuration**: 5 minutes
- **Extension Redeploy**: 2-3 minutes
- **Testing**: 5 minutes
- **Total**: 10-15 minutes

---

## 📞 **Support Resources**

### **Firebase Console Links**
- **Extensions**: https://console.firebase.google.com/project/impact-graphics-za-266ef/extensions
- **Firestore**: https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore
- **Functions Logs**: https://console.firebase.google.com/project/impact-graphics-za-266ef/functions/logs

### **MailerSend Dashboard**
- **Main Dashboard**: https://app.mailersend.com/
- **API Tokens**: https://app.mailersend.com/api-tokens
- **Domains**: https://app.mailersend.com/domains
- **Activity**: https://app.mailersend.com/activity

---

## ✅ **Summary**

**Current Status**: Extension installed but needs reconfiguration  
**Solution**: Manual reconfiguration via Firebase Console  
**Time Required**: 10-15 minutes  
**Expected Result**: All email functionality restored  

**Next Step**: Go to the Firebase Console link above and reconfigure the MailerSend extension with the provided settings.

---

**The email system will be working once you complete the manual configuration!** 📧✨🚀


