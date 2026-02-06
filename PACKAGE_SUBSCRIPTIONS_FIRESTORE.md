# Package Subscriptions Firestore Structure

## Collection: `package_subscriptions`

This collection stores all package subscription information for both manual and automated packages.

### Document Structure

```typescript
{
  // Client Information
  clientName: string,           // Full name of the client
  clientEmail: string,          // Email address of the client
  userId?: string,              // Firebase User ID (null for manual subscriptions)
  
  // Package Information
  packageName: string,          // Name of the package (e.g., "Growth Package")
  packagePrice: number,         // Price in Rands (e.g., 5000.00)
  billingCycle: string,         // 'monthly' | 'quarterly' | 'semi-annually' | 'annually'
  
  // Status & Dates
  status: string,               // 'active' | 'paused' | 'expired' | 'cancelled'
  nextBillingDate: Timestamp,   // When the next payment is due
  createdAt: Timestamp,         // When the subscription was created
  updatedAt: Timestamp,         // Last update timestamp
  lastPaymentDate?: Timestamp,  // When the last payment was received
  pausedAt?: Timestamp,         // When the subscription was paused
  reactivatedAt?: Timestamp,    // When the subscription was reactivated
  cancelledAt?: Timestamp,      // When the subscription was cancelled
  
  // Manual vs Automated
  isManuallyCreated: boolean,   // true if created by admin manually
  
  // Additional Information
  notes?: string,               // Admin notes about the package
  paystackReference?: string,   // Paystack payment reference
  invoiceNumber?: string,       // Generated invoice number
}
```

### Required Indexes

Add these indexes in Firebase Console:

1. **Active Packages by Next Billing Date**
   - Collection: `package_subscriptions`
   - Fields: `status` (Ascending), `nextBillingDate` (Ascending)

2. **Client Email Search**
   - Collection: `package_subscriptions`
   - Fields: `clientEmail` (Ascending), `nextBillingDate` (Ascending)

3. **Manual Packages**
   - Collection: `package_subscriptions`
   - Fields: `isManuallyCreated` (Ascending), `createdAt` (Descending)

### Firestore Security Rules

Add these rules to `firestore.rules`:

```javascript
// Package Subscriptions Collection
match /package_subscriptions/{subscriptionId} {
  // Admin can read/write all
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
  
  // Users can only read their own subscriptions
  allow read: if request.auth != null && 
    resource.data.userId == request.auth.uid;
    
  // Users cannot create or update subscriptions
  allow create, update, delete: if false;
}
```

### Sample Document

```json
{
  "clientName": "Colane Ngobese",
  "clientEmail": "colane@example.com",
  "userId": null,
  "packageName": "Growth Package",
  "packagePrice": 8500.00,
  "billingCycle": "monthly",
  "status": "active",
  "nextBillingDate": "2025-02-16T00:00:00Z",
  "createdAt": "2025-01-16T10:30:00Z",
  "updatedAt": "2025-01-16T10:30:00Z",
  "isManuallyCreated": true,
  "notes": "Client prefers WhatsApp communication for invoices",
  "invoiceNumber": "PKG-A1B2C3D4"
}
```

### Usage Examples

#### Create Manual Package Subscription

```dart
await FirebaseFirestore.instance
    .collection('package_subscriptions')
    .add({
  'clientName': 'Colane Ngobese',
  'clientEmail': 'colane@example.com',
  'packageName': 'Growth Package',
  'packagePrice': 8500.00,
  'billingCycle': 'monthly',
  'nextBillingDate': Timestamp.fromDate(nextBillingDate),
  'status': 'active',
  'isManuallyCreated': true,
  'notes': 'VIP client',
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

#### Query Active Packages

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('package_subscriptions')
    .where('status', isEqualTo: 'active')
    .orderBy('nextBillingDate')
    .get();
```

#### Update Next Billing Date

```dart
await FirebaseFirestore.instance
    .collection('package_subscriptions')
    .doc(packageId)
    .update({
  'nextBillingDate': Timestamp.fromDate(newDate),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

## Features Implemented

✅ **Active Packages Screen** - Shows all active subscriptions with client details  
✅ **Package Detail Screen** - Manage individual packages (update price, dates, notes)  
✅ **Manual Package Creation** - Create packages for clients without accounts  
✅ **Email Invoice System** - Automated invoice emails with Paystack payment links  
✅ **Search & Filter** - Search by client name/email, filter by status  
✅ **Status Management** - Active, Paused, Expired, Cancelled states  
✅ **Billing Cycle Support** - Monthly, Quarterly, Semi-Annual, Annual  
✅ **Payment Tracking** - Next billing date, last payment date  
✅ **Admin Notes** - Add internal notes for each package  

## Email Integration

The system uses `PackageInvoiceEmailService` to send branded invoice emails via Sender.net API.

### Email Template Features:
- Professional branded design
- Package details with pricing
- Next billing date
- Paystack payment link button
- Important notice about ignoring if already paid
- Contact information

### Paystack Integration

Payment links are generated automatically using Paystack's Transaction Initialize API:
- Amount converted to kobo automatically
- Metadata includes package ID and name
- Callback URL redirects to app after payment
- Fallback to manual payment if Paystack fails

## Monitoring & Maintenance

### Tasks to Monitor:
1. **Expiring Soon** - Packages with billing date within 7 days
2. **Overdue** - Packages past their billing date
3. **Manual Packages** - Track manually created subscriptions
4. **Payment Confirmations** - Verify Paystack webhook callbacks

### Automated Tasks (Future Enhancement):
- Send reminder emails 7 days before billing
- Auto-send invoices on billing date
- Auto-update status when payment received
- Monthly billing reports

## Migration from Old System

If you have existing marketing packages in `marketing_packages` collection, they remain separate. The new `package_subscriptions` collection is specifically for client subscriptions.

To migrate existing client packages:
1. Export data from old system
2. Transform to new structure
3. Import with `isManuallyCreated: false`
4. Link to existing user IDs where applicable




