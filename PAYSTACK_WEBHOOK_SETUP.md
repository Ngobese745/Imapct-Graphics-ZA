# Paystack Webhook Setup Guide

This guide explains how to set up Paystack webhooks to automatically verify payments and process orders, solving the mobile app restart issue.

## 🎯 Problem Solved

**Issue:** On mobile devices, when users return from Paystack payment tab, the web app restarts, breaking payment verification.

**Solution:** Paystack webhooks work independently of browser sessions, automatically processing payments even when the app restarts.

## 📋 Setup Steps

### 1. Configure Paystack Webhook URL

1. Log in to your [Paystack Dashboard](https://dashboard.paystack.com/)
2. Go to **Settings** → **Webhooks**
3. Click **Add Webhook**
4. Set the webhook URL to: `https://impact-graphics-za-266ef.web.app/paystack-webhook`
5. Select these events:
   - `charge.success`
   - `subscription.create`
   - `subscription.enable`
   - `subscription.disable`
6. Save the webhook

### 2. Deploy the Webhook Handler

The webhook handler is already created and will be deployed with your app:

- **File:** `web/paystack-webhook.html`
- **Route:** `/paystack-webhook`
- **Function:** `functions/src/paystack-webhook.ts`

### 3. Test the Webhook

1. Make a test payment
2. Check Firebase Functions logs for webhook activity
3. Verify orders are created automatically
4. Check notifications are sent

## 🔄 How It Works

### Payment Flow with Webhooks:

1. **User initiates payment** → Order created with `pending` status
2. **User completes payment on Paystack** → Paystack sends webhook
3. **Webhook processes payment** → Order status updated to `completed`
4. **User returns to app** → App checks for completed orders
5. **Payment verified** → Cart cleared, notifications sent

### Backup Verification:

If webhook fails, the app still has:
- Manual "Verify Payment" button
- Automatic polling every 3 seconds for 5 minutes
- Pending payment data stored in Firestore

## 📱 Mobile vs Desktop Behavior

### Desktop:
- User can manually click "Verify Payment" ✓
- App doesn't restart when returning from Paystack tab ✓
- Both webhook and manual verification work ✓

### Mobile:
- App restarts when returning from Paystack tab ❌
- Manual verification often fails due to restart ❌
- **Webhook automatically processes payment** ✓
- User sees success message when app reloads ✓

## 🔧 Configuration

### Webhook Events Handled:

| Event | Description | Action |
|-------|-------------|--------|
| `charge.success` | Payment completed | Process order, clear cart, send notification |
| `subscription.create` | Subscription created | Log subscription creation |
| `subscription.enable` | Subscription enabled | Activate Gold Tier |
| `subscription.disable` | Subscription disabled | Deactivate Gold Tier |

### Webhook Security:

- Signature verification (optional)
- Event validation
- Error handling and logging
- Duplicate payment prevention

## 🚀 Deployment

The webhook system is automatically deployed when you deploy your app:

```bash
# Deploy web app (includes webhook handler)
firebase deploy --only hosting

# Deploy Firebase Functions (webhook endpoint)
firebase deploy --only functions
```

## 📊 Monitoring

### Check Webhook Activity:

1. **Firebase Functions Logs:**
   ```bash
   firebase functions:log
   ```

2. **Paystack Dashboard:**
   - Go to Settings → Webhooks
   - Check delivery status and response codes

3. **Firestore Collections:**
   - `orders` - Check for completed orders
   - `notifications` - Check for payment notifications
   - `pending_payments` - Should be cleared after successful payment

### Success Indicators:

- ✅ Webhook receives `charge.success` events
- ✅ Orders automatically created with `completed` status
- ✅ User cart cleared after payment
- ✅ Payment notifications sent
- ✅ No more "payment not verified" issues on mobile

## 🛠️ Troubleshooting

### Webhook Not Working:

1. **Check URL:** Ensure webhook URL is correct
2. **Check Events:** Verify correct events are selected
3. **Check Logs:** Look for errors in Firebase Functions logs
4. **Test Payment:** Make a test payment and monitor logs

### Payment Still Not Verified:

1. **Check Webhook Delivery:** Look at Paystack dashboard
2. **Check Firestore:** Verify order was created
3. **Check Manual Verification:** Use "Verify Payment" button as backup
4. **Check Pending Payments:** Verify pending payment data exists

### Common Issues:

- **CORS Errors:** Webhook endpoint should handle CORS properly
- **Timeout Issues:** Webhook should respond within 30 seconds
- **Duplicate Processing:** Webhook should check if payment already processed
- **Missing Data:** Ensure all required payment data is stored

## 📈 Benefits

### For Users:
- ✅ Automatic payment processing
- ✅ No more manual verification needed
- ✅ Works reliably on mobile devices
- ✅ Faster order completion

### For Business:
- ✅ Reduced support tickets
- ✅ Higher payment success rate
- ✅ Better user experience
- ✅ Automated order processing

## 🔄 Fallback System

Even with webhooks, the app maintains:

1. **Manual Verification Button** - For edge cases
2. **Automatic Polling** - Checks payment status every 3 seconds
3. **Pending Payment Storage** - Data preserved across app restarts
4. **Error Handling** - Graceful fallbacks for all scenarios

This ensures 100% payment verification reliability! 🚀
