# Automated Billing System

## Overview
The automated billing system automatically sends invoice emails to clients when their package subscriptions are due for billing. This system runs daily and processes all active packages that have reached their next billing date.

## How It Works

### 1. Daily Scheduled Function
- **Function Name**: `autoBilling`
- **Schedule**: Daily at 9:00 AM UTC (11:00 AM SAST)
- **Timezone**: Africa/Johannesburg
- **Trigger**: Cloud Scheduler (Pub/Sub)

### 2. Process Flow

#### Step 1: Query Due Packages
The system queries the `package_subscriptions` collection for:
- Packages where `nextBillingDate <= today`
- Packages with `status = 'active'`

#### Step 2: Process Each Package
For each due package:
1. **Generate Invoice Email**: Creates a branded HTML email template
2. **Generate Payment Link**: Creates Paystack payment link with:
   - Amount in Rand (rounded)
   - Client email
   - Client name
3. **Send Email**: Writes to Firestore `emails` collection (triggers MailerSend)
4. **Update Package**: Updates `nextBillingDate` based on billing cycle
5. **Log Results**: Records success/failure in `billing_logs` collection

#### Step 3: Update Billing Dates
After successful email sending, the system calculates and updates the next billing date:
- **Monthly**: +1 month
- **Quarterly**: +3 months
- **Yearly/Annual**: +1 year
- **Weekly**: +7 days
- **Default**: Monthly

### 3. Email Template Features
- **Branded Design**: Impact Graphics ZA logo and styling
- **Payment Options**: Paystack payment button + bank transfer details
- **Professional Layout**: Invoice format with package details
- **Important Notice**: "Ignore if already paid" message
- **Contact Information**: Support email and WhatsApp
- **Banking Details**: Capitec Business account information

### 4. Error Handling & Logging
- **Billing Logs**: All results stored in `billing_logs` collection
- **Success Tracking**: Records successful email sends and date updates
- **Error Tracking**: Logs failures with error messages
- **Daily Summary**: Provides counts of successful vs failed operations

## Database Collections

### package_subscriptions
```javascript
{
  clientName: "John Doe",
  clientEmail: "john@example.com",
  packageName: "Growth Package",
  packagePrice: 1500.00,
  billingCycle: "monthly", // monthly, quarterly, yearly, weekly
  nextBillingDate: Timestamp,
  lastBillingDate: Timestamp,
  status: "active", // active, paused, expired
  isManuallyCreated: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### billing_logs
```javascript
{
  date: "2025-01-08",
  timestamp: Timestamp,
  totalPackages: 5,
  successful: 4,
  failed: 1,
  results: [
    {
      packageId: "abc123",
      clientName: "John Doe",
      clientEmail: "john@example.com",
      success: true,
      nextBillingDate: "2025-02-08"
    }
  ]
}
```

## Paystack Integration
- **Payment URL**: `https://paystack.shop/pay/n6c6hp792r`
- **Parameters**:
  - `amount`: Package price in Rand (rounded)
  - `email`: Client email (URL encoded)
  - `name`: Client name (URL encoded)

## Email Features
- **Subject**: "Monthly Invoice for [Package Name] - Impact Graphics ZA"
- **From**: noreply@impactgraphicsza.co.za
- **Reply-To**: info@impactgraphicsza.co.za
- **Tags**: ['package', 'invoice', 'subscription', 'auto-billing']

## Monitoring & Maintenance

### View Billing Logs
Access the `billing_logs` collection in Firestore to monitor:
- Daily billing results
- Success/failure rates
- Error messages
- Package processing details

### Manual Testing
You can test the system by:
1. Creating a test package with `nextBillingDate` set to today
2. Manually triggering the function (if needed)
3. Checking the `billing_logs` collection for results

### Function URLs
- **Manual Trial Check**: https://manualtrialcheck-3i5wxkmmia-uc.a.run.app
- **Get Trial Stats**: https://gettrialstats-3i5wxkmmia-uc.a.run.app
- **Expire User Trial**: https://expireusertrial-3i5wxkmmia-uc.a.run.app

## Benefits
1. **Automated Process**: No manual intervention required
2. **Consistent Billing**: Ensures all clients receive invoices on time
3. **Professional Emails**: Branded, professional invoice templates
4. **Multiple Payment Options**: Paystack + bank transfer options
5. **Comprehensive Logging**: Full audit trail of all billing activities
6. **Error Handling**: Robust error handling and retry capabilities
7. **Flexible Billing Cycles**: Supports monthly, quarterly, yearly, and weekly billing

## Security
- **Firestore Rules**: Admin-only access to `package_subscriptions`
- **Function Authentication**: Firebase Admin SDK authentication
- **Email Security**: Secure MailerSend integration
- **Payment Security**: Paystack's secure payment processing

## Future Enhancements
- **Payment Confirmation**: Integration with Paystack webhooks
- **Reminder Emails**: Pre-billing reminders (e.g., 3 days before)
- **Failed Payment Handling**: Automatic retry for failed payments
- **Analytics Dashboard**: Admin dashboard for billing analytics
- **Custom Billing Cycles**: Support for custom billing periods



