# Email System Fix - MailerSend Extension Configuration

## Problem Identified

The MailerSend extension is installed and ACTIVE, but the API key is missing from Firebase Secret Manager. This is why emails are not being sent.

## Current Extension Configuration

```
Extension: mailersend/mailersend-email@0.1.8
Instance ID: mailersend-email
Status: ACTIVE
Location: us-east1

Configuration:
- EMAIL_COLLECTION: emails
- MAILERSEND_API_KEY: projects/${param:PROJECT_NUMBER}/secrets/mailersend-email-MAILERSEND_API_KEY/versions/latest
- DEFAULT_FROM_EMAIL: info@impactgraphicsza.co.za
- DEFAULT_FROM_NAME: Impact Graphics ZA
- DEFAULT_REPLY_TO_EMAIL: admin@impactgraphicsza.co.za
- DEFAULT_REPLY_TO_NAME: Impact Graphics ZA
```

## Solution

The extension expects the API key to be stored in Google Secret Manager with a specific name. We have created the secret, but you need to **reconfigure the extension to use it**.

## Step-by-Step Fix

### Option 1: Reconfigure via Firebase Console (RECOMMENDED)

1. **Open Firebase Console**
   ```
   https://console.firebase.google.com/project/impact-graphics-za-266ef/extensions
   ```

2. **Click on the MailerSend extension** (mailersend-email)

3. **Click "Reconfigure"** or **"Manage"** button

4. **Update the API Key field**:
   - When asked for `MAILERSEND_API_KEY`, select from Secret Manager:
   - Choose the secret we just created: `MAILERSEND_EMAIL_MAILERSEND_API_KEY` or `MAILERSEND_API_KEY`
   
5. **Verify other settings**:
   - Email Collection: `emails`
   - Default FROM email: `info@impactgraphicsza.co.za`
   - Default FROM name: `Impact Graphics ZA`
   - Default REPLY-TO email: `admin@impactgraphicsza.co.za`
   - Default REPLY-TO name: `Impact Graphics ZA`

6. **Click "Save" or "Reconfigure"**

7. **Wait for the extension to redeploy** (usually takes 2-3 minutes)

### Option 2: Update Secret Name via gcloud CLI

If you prefer CLI, update the extension using gcloud:

```bash
# Set the correct secret name that matches the extension configuration
gcloud secrets create mailersend-email-MAILERSEND_API_KEY \
  --data-file=- \
  --project=impact-graphics-za-266ef \
  <<< 'mlsn.45bb9103d2b0f627e4648d9655ced8ab656be77811c94f16bbfdbc7e957b1b4c'

# Grant the extension service account access to the secret
gcloud secrets add-iam-policy-binding mailersend-email-MAILERSEND_API_KEY \
  --member="serviceAccount:ext-mailersend-email@impact-graphics-za-266ef.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=impact-graphics-za-266ef
```

## Verification Steps

After reconfiguring:

1. **Check Extension Logs**:
   ```bash
   firebase functions:log --project impact-graphics-za-266ef 2>&1 | grep -i mailersend
   ```

2. **Send a Test Email**:
   ```bash
   dart test_mailersend.dart
   ```

3. **Check Firestore**:
   - Go to Firebase Console → Firestore
   - Check the `emails` collection
   - Look for documents with `status: 'pending'` → should change to `status: 'sent'`

4. **Check MailerSend Dashboard**:
   - Log into https://www.mailersend.com/
   - Go to Activity → Emails
   - Verify emails are being sent

## Common Issues

### Issue 1: Secret Not Found
**Error**: `Secret [projects/884752435887/secrets/mailersend-email-MAILERSEND_API_KEY] not found`

**Solution**: The secret name must exactly match what the extension expects. Use Firebase Console to reconfigure and let it create the secret automatically.

### Issue 2: Permission Denied
**Error**: `Permission denied on secret`

**Solution**: Grant the extension service account access:
```bash
gcloud secrets add-iam-policy-binding MAILERSEND_EMAIL_MAILERSEND_API_KEY \
  --member="serviceAccount:ext-mailersend-email@impact-graphics-za-266ef.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=impact-graphics-za-266ef
```

### Issue 3: Extension Not Processing Emails
**Check**:
1. Extension is ACTIVE (firebase ext:list)
2. Firebase Functions are deployed (firebase deploy --only functions)
3. Firestore rules allow writes to `emails` collection

## Testing the Fix

Run the diagnostic script:
```bash
bash check_mailersend_extension.sh
```

This will:
- Check if extension is active
- Verify API key exists
- Check recent logs
- Provide recommendations

## Alternative: Manual Reconfiguration via Console

If CLI methods don't work, you can always reconfigure through the Firebase Console:

1. Go to: https://console.firebase.google.com/project/impact-graphics-za-266ef/extensions
2. Find "mailersend-email" extension
3. Click "Reconfigure"
4. When asked for API key:
   - Either select existing secret from dropdown
   - Or paste the API key directly: `mlsn.45bb9103d2b0f627e4648d9655ced8ab656be77811c94f16bbfdbc7e957b1b4c`
5. Complete reconfiguration
6. Wait for deployment to finish

## Expected Behavior After Fix

✅ **What should work**:
- Emails written to Firestore `emails` collection are picked up by extension
- Extension sends emails via MailerSend API
- Email status changes from `pending` → `sent` (or `error` if failed)
- Users receive emails in their inbox
- Logs show extension activity: `ext-mailersend-email`

## Support

If issues persist after reconfiguration:

1. **Check MailerSend Dashboard**:
   - Verify API key is valid
   - Check domain verification status
   - Review sending limits

2. **Check Firebase Logs**:
   ```bash
   firebase functions:log --project impact-graphics-za-266ef
   ```

3. **Verify Firestore Rules**:
   - Ensure authenticated users can write to `emails` collection
   - Check for any rule errors in Firebase Console

4. **Contact MailerSend Support**:
   - If API key issues persist
   - If emails are rejected by MailerSend

## Quick Fix Summary

**The fastest fix**: Go to Firebase Console → Extensions → mailersend-email → Reconfigure → Paste API key → Save

That's it! The email system should start working immediately after reconfiguration.

