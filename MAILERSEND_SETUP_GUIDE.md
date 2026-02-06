# MailerSend Firebase Extension Setup Guide

## Overview
This guide will help you migrate from Sender.net to MailerSend using the Firebase extension for more cost-effective email sending.

## Prerequisites
- Firebase project with Firestore enabled
- Flutter app with Firebase configured
- MailerSend account (free tier available)

## Step 1: Create MailerSend Account

1. Go to [MailerSend.com](https://mailersend.com)
2. Sign up for a free account
3. Verify your email address
4. Complete the account setup

## Step 2: Get MailerSend API Key

1. Log into your MailerSend dashboard
2. Go to **Settings** → **API Tokens**
3. Click **Create New Token**
4. Give it a name (e.g., "Firebase Extension")
5. Select **Full Access** permissions
6. Click **Create Token**
7. **Copy the API key immediately** (you won't be able to see it again)

## Step 3: Configure Firebase Extension

Based on your screenshot, complete these settings:

### Required Settings:
1. **Cloud Functions location**: Select your preferred region (e.g., `us-central1`)
2. **Emails documents collection**: Keep as `emails` (default)
3. **MailerSend API key**: 
   - Click "Create secret"
   - Enter your MailerSend API key: `mlsn.45bb9103d2b0f627e4648d9655ced8ab656be77811c94f16bbfdbc7e957b1b4c`
   - Give it a name like "mailersend-api-key"
4. **Default FROM email address**: Enter your verified sender email
   - Example: `noreply@yourdomain.com`
   - Or use MailerSend's default: `noreply@mailersend.net`

### Optional Settings:
- **Reply-to email**: Your support email
- **Default FROM name**: "Impact Graphics ZA"

## Step 4: Verify Domain (Important!)

1. In MailerSend dashboard, go to **Domains**
2. Add your domain (e.g., `impactgraphicsza.co.za`)
3. Follow the DNS verification steps
4. **Important**: Without domain verification, emails may go to spam

## Step 5: Test the Integration

Run the test script to verify everything works:

```bash
cd /Volumes/work/Pre\ Release/impact_graphics_za_production_backup_20251008_011440
dart test_mailersend.dart
```

## Step 6: Monitor the Setup

1. **Firebase Console**:
   - Go to Firestore → `emails` collection
   - Check if documents are being created
   - Look for `status` field changes from "pending" to "sent"

2. **MailerSend Dashboard**:
   - Go to **Activity** → **Emails**
   - Monitor sent emails and delivery status

3. **Firebase Functions Logs**:
   - Go to Firebase Console → Functions
   - Check logs for any errors

## Step 7: Update Your App

The migration is already complete! The app now uses:
- `MailerSendService` instead of `EmailService`
- Firebase Firestore `emails` collection instead of Sender.net API
- Professional HTML email templates

## Email Types Supported

✅ **Proposal Emails**: Professional branded proposals
✅ **Welcome Emails**: New user onboarding
✅ **Payment Confirmation Emails**: Transaction receipts with order details
✅ **Appointment Reminders**: Meeting notifications
✅ **Custom HTML**: Fully branded email templates

## Cost Comparison

| Service | Free Tier | Paid Plans |
|---------|-----------|------------|
| **Sender.net** | Limited | $15+/month |
| **MailerSend** | 12,000 emails/month | $10+/month |

## Troubleshooting

### Common Issues:

1. **Emails not sending**:
   - Check Firebase Functions logs
   - Verify MailerSend API key is correct
   - Ensure domain is verified in MailerSend

2. **Emails going to spam**:
   - Verify your domain in MailerSend
   - Set up SPF, DKIM, and DMARC records
   - Use a professional FROM address

3. **Extension not working**:
   - Check Firebase Functions are deployed
   - Verify Firestore rules allow writes to `emails` collection
   - Check Cloud Functions logs

### Firestore Rules

Make sure your Firestore rules allow writes to the emails collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /emails/{document} {
      allow write: if true; // Allow writes for MailerSend extension
    }
  }
}
```

## Migration Complete! 🎉

Your app now uses MailerSend for all email communications. The migration includes:

- ✅ Professional HTML email templates
- ✅ Cost-effective email sending
- ✅ Better deliverability
- ✅ Firebase integration
- ✅ Comprehensive error handling

## Next Steps

1. Test all email functionality in your app
2. Monitor email delivery rates
3. Set up email analytics in MailerSend
4. Consider upgrading to paid plan as your volume grows

## Support

- **MailerSend Docs**: https://developers.mailersend.com/
- **Firebase Extension Docs**: Check Firebase Console
- **App Issues**: Check the Flutter/Dart code for any remaining Sender.net references
