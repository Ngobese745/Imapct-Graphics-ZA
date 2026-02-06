# Referral Earnings Payout Threshold System

## Overview
The referral earnings system has been updated to implement a **R200 minimum payout threshold**. This means that referral earnings will accumulate in a "pending" state and only be credited to the user's wallet once they reach R200 or more.

## How It Works

### 1. **Earning Referral Income**
Users earn referral income in two ways:
- **R10** when a referred user registers
- **15%** of the purchase amount when a referred user makes a purchase

### 2. **Pending Earnings Accumulation**
- All referral earnings are added to `pendingReferralEarnings` field in the user document
- Users can see their pending earnings but cannot use them until payout
- Example:
  ```
  Referral 1: R10 → Pending: R10
  Referral 2: R10 → Pending: R20
  Referral 3: R15 (15% of R100 purchase) → Pending: R35
  ...continues accumulating...
  ```

### 3. **Automatic Payout at R200**
When pending earnings reach **R200 or more**, the system automatically:
1. Credits the full pending amount to the user's wallet
2. Resets `pendingReferralEarnings` to R0
3. Creates a transaction record with type `referral_payout`
4. Updates `lastReferralPayout` timestamp
5. Sends a notification to the user

Example:
```
Pending: R195
New referral: +R10
Total: R205 ≥ R200 ✓
→ R205 credited to wallet
→ Pending reset to R0
```

## Firestore Data Structure

### User Document Updates
```javascript
{
  // Existing fields...
  "walletBalance": 500.00,              // Actual wallet balance
  "pendingReferralEarnings": 75.50,    // NEW: Accumulated but not yet paid
  "lastReferralPayout": Timestamp,     // NEW: Last time earnings were paid out
  "referralCode": "IMPACT1234"
}
```

### Transaction Types
```javascript
{
  "type": "referral_payout",           // NEW: Identifies payout transactions
  "amount": 205.00,
  "description": "Referral earnings payout - R205.00",
  "transactionId": "REFERRAL_PAYOUT_1234567890",
  "status": "completed",
  "userId": "user_id",
  "createdAt": Timestamp
}
```

## API Methods

### Get Pending Earnings
```dart
double pending = await ReferralService.getPendingEarnings(userId);
print('Pending: R${pending.toStringAsFixed(2)}');
```

### Get Earnings Summary
```dart
Map<String, double> summary = await ReferralService.getReferralEarningsSummary(userId);
print('Pending: R${summary['pending']}');
print('Total Paid: R${summary['paid']}');
print('Lifetime Earnings: R${summary['total']}');
```

### Manual Payout (Admin Only)
```dart
// Trigger payout even if below R200 - for special cases
var result = await ReferralService.manualPayout(
  userId: 'user_id',
  adminId: 'admin_id',
  reason: 'User request - closing account',
);
```

## Migration for Existing Users

To initialize the `pendingReferralEarnings` field for existing users, run this Firestore update:

```javascript
// In Firebase Console or Cloud Function
const users = await db.collection('users').get();
const batch = db.batch();

users.docs.forEach(doc => {
  if (!doc.data().hasOwnProperty('pendingReferralEarnings')) {
    batch.update(doc.ref, {
      pendingReferralEarnings: 0.0
    });
  }
});

await batch.commit();
```

Or use the provided Cloud Function (see below).

## UI Display Recommendations

### Referral Dashboard
Show users their earnings breakdown:
```
┌─────────────────────────────────┐
│  Referral Earnings              │
├─────────────────────────────────┤
│  Pending Earnings:   R 175.50   │
│  (R24.50 more needed for payout)│
│                                 │
│  Total Paid Out:     R 250.00   │
│  Lifetime Earnings:  R 325.50   │
└─────────────────────────────────┘
```

### Progress Indicator
```dart
double pending = 175.50;
double progress = (pending / 200.0).clamp(0.0, 1.0);

LinearProgressIndicator(
  value: progress,
  backgroundColor: Colors.grey[200],
  color: Colors.green,
)
Text('${pending.toStringAsFixed(2)} / R200.00');
```

## Benefits of This System

1. **Reduces Transaction Costs**: Fewer micro-transactions
2. **Fraud Prevention**: Harder to abuse with small fake referrals
3. **User Motivation**: Encourages users to refer more people
4. **Clear Milestones**: R200 is a tangible goal
5. **Better Accounting**: Easier to track and audit payouts

## Testing Scenarios

### Test 1: Accumulation Below Threshold
```
1. User A refers User B → +R10 (Pending: R10)
2. User A refers User C → +R10 (Pending: R20)
3. Check: wallet unchanged, pending = R20 ✓
```

### Test 2: Automatic Payout at Threshold
```
1. User has Pending: R195
2. Referred user makes R40 purchase → +R6 (15%)
3. Total: R201 >= R200
4. Check: wallet +R201, pending = R0 ✓
5. Check: transaction record created ✓
```

### Test 3: Large Single Earning
```
1. User has Pending: R0
2. Referred user makes R1000 purchase → +R150 (15%)
3. Total: R150 < R200
4. Check: wallet unchanged, pending = R150 ✓
```

## Security Considerations

- Pending earnings are stored in Firestore, ensure proper security rules
- Only the referral service can modify `pendingReferralEarnings`
- Manual payouts should be admin-only
- Transaction records are immutable after creation

## Firestore Security Rules Update

```javascript
match /users/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  
  allow update: if request.auth != null && request.auth.uid == userId &&
    // Users cannot modify their own pending earnings or wallet balance
    !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['pendingReferralEarnings', 'walletBalance', 'lastReferralPayout']);
}
```

## Support & Maintenance

For issues or questions about the referral payout system:
1. Check Firestore for user's `pendingReferralEarnings` value
2. Review transaction logs for `referral_payout` type
3. Use `getReferralEarningsSummary()` for complete history
4. Manual payout available for edge cases

---

**Last Updated**: October 2, 2025
**Version**: 1.0.0

