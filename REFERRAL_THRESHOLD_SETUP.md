# Referral Earnings R200 Threshold - Setup Guide

## ✅ What Has Been Implemented

### 1. **Modified Files**
- `lib/services/referral_service.dart` - Updated to use pending earnings threshold
- `functions/index.js` - Added Cloud Functions for migration and payout checking
- `REFERRAL_PAYOUT_THRESHOLD.md` - Complete documentation

### 2. **New Features**
- ✅ Earnings accumulate in `pendingReferralEarnings` field
- ✅ Automatic wallet credit when pending reaches R200+
- ✅ Transaction records for all payouts
- ✅ Helper methods to get earnings summary
- ✅ Manual payout option for admins
- ✅ Cloud Functions for migration and checking

## 🚀 Deployment Steps

### Step 1: Deploy Cloud Functions
```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za"
cd functions
firebase deploy --only functions:initializePendingReferralEarnings,functions:checkReferralPayouts
```

### Step 2: Initialize Existing Users (One-Time)
Run this from your Flutter app (admin only):

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> initializeReferralEarnings() async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('initializePendingReferralEarnings');
    
    final result = await callable.call();
    print('Initialization result: ${result.data}');
    // Expected output:
    // {
    //   success: true,
    //   message: 'Initialization complete',
    //   totalUsers: 150,
    //   updated: 150,
    //   skipped: 0
    // }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Step 3: Update Firestore Security Rules
Add these rules to protect the new fields:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      
      allow update: if request.auth != null && 
                      request.auth.uid == userId &&
                      // Users cannot modify their own earnings or wallet
                      !request.resource.data.diff(resource.data)
                        .affectedKeys()
                        .hasAny([
                          'pendingReferralEarnings', 
                          'walletBalance', 
                          'lastReferralPayout'
                        ]);
    }
    
    match /transactions/{transactionId} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      // Only cloud functions can write transactions
      allow write: if false;
    }
  }
}
```

Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

## 📊 Testing the Implementation

### Test 1: Check Pending Earnings
```dart
import 'package:impact_graphics_za/services/referral_service.dart';

// In your app
final userId = FirebaseAuth.instance.currentUser!.uid;
final summary = await ReferralService.getReferralEarningsSummary(userId);

print('Pending: R${summary['pending']}');
print('Paid: R${summary['paid']}');
print('Total: R${summary['total']}');
```

### Test 2: Simulate Referral Earnings
```dart
// Create test referrals to accumulate earnings
await ReferralService.checkAndProcessReferral(
  userId: 'test_user_id',
  userName: 'Test User',
  userEmail: 'test@example.com',
  referralCode: 'IMPACT1234',
);
// This adds R10 to pending earnings

// Simulate a purchase by referred user
await ReferralService.processReferralPurchase(
  referredUserId: 'test_user_id',
  purchaseAmount: 600.0, // Will add R90 (15%)
);
// Total: R100 -> Should auto-credit to wallet
```

### Test 3: Check Auto-Payout
After accumulating R100:
```dart
// Check user document
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final userData = userDoc.data()!;
print('Wallet Balance: R${userData['walletBalance']}'); // Should have +R100
print('Pending Earnings: R${userData['pendingReferralEarnings']}'); // Should be 0

// Check transactions
final transactions = await FirebaseFirestore.instance
    .collection('transactions')
    .where('userId', isEqualTo: userId)
    .where('type', isEqualTo: 'referral_payout')
    .get();

print('Payout transactions: ${transactions.docs.length}');
```

## 🎨 UI Updates (Optional but Recommended)

### Update Referral Screen to Show Pending Earnings

```dart
import 'package:impact_graphics_za/services/referral_service.dart';

class ReferralEarningsWidget extends StatelessWidget {
  final String userId;

  const ReferralEarningsWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: ReferralService.getReferralEarningsSummary(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final summary = snapshot.data!;
        final pending = summary['pending']!;
        final paid = summary['paid']!;
        final progress = (pending / 100.0).clamp(0.0, 1.0);
        final remaining = 100.0 - pending;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Referral Earnings', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                
                // Pending earnings with progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pending Earnings:'),
                    Text('R${pending.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, 
                                       color: Colors.orange)),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.green,
                ),
                SizedBox(height: 4),
                Text(
                  remaining > 0 
                      ? 'R${remaining.toStringAsFixed(2)} more needed for payout'
                      : 'Ready for payout!',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                
                SizedBox(height: 16),
                Divider(),
                
                // Total paid out
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Paid Out:'),
                    Text('R${paid.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, 
                                       color: Colors.green)),
                  ],
                ),
                
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lifetime Earnings:', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('R${(pending + paid).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18,
                                       fontWeight: FontWeight.bold,
                                       color: Theme.of(context).primaryColor)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

## 📝 How It Works

### Earning Flow
1. User A refers User B → **+R10** added to pending
2. User A refers User C → **+R10** added to pending (Total: R20)
3. User B makes R100 purchase → **+R15** (15%) added to pending (Total: R35)
4. ...continues accumulating...
5. When pending reaches **R200+** → Automatically credited to wallet, pending reset to R0

### Example Scenario
```
Day 1: Refer 5 users → Pending: R50
Day 2: Refer 3 users → Pending: R80
Day 3: More referrals... Pending: R180
Day 4: One referred user purchases R200 → +R30 → Pending: R210
       → Auto-payout triggered! ✅
       → Wallet: +R210
       → Pending: R0
       → Transaction record created
       → User receives notification
```

## ⚙️ Maintenance

### Check System Health
```dart
// Get summary for all users (admin only)
final usersQuery = await FirebaseFirestore.instance
    .collection('users')
    .where('pendingReferralEarnings', isGreaterThan: 0)
    .get();

print('Users with pending earnings: ${usersQuery.docs.length}');

for (var doc in usersQuery.docs) {
  final data = doc.data();
  print('${data['name']}: R${data['pendingReferralEarnings']}');
}
```

### Manual Payout (if needed)
```dart
final result = await ReferralService.manualPayout(
  userId: 'user_id',
  adminId: 'admin_id',
  reason: 'User closing account',
);
print(result);
```

## 🔒 Security Notes

- ✅ Pending earnings field is protected by security rules
- ✅ Only referral service can modify pending earnings
- ✅ Transaction records are immutable
- ✅ Manual payout requires admin authentication
- ✅ All operations are logged

## 📞 Support

If you encounter issues:
1. Check Firestore logs for errors
2. Verify user has `pendingReferralEarnings` field
3. Check transaction history for payout records
4. Use `getReferralEarningsSummary()` for debugging

---

**Ready to deploy!** 🚀

