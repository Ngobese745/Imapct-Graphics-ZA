# Referral Program Terms & Conditions Update

## Date: October 13, 2025

## Summary
Updated the Terms and Conditions (Section 9: REFERRAL PROGRAM) to accurately reflect the actual implementation of the referral program.

---

## Changes Made

### ❌ OLD Terms (Incorrect):
```
### 9.1 How It Works
- Share your unique referral code
- Earn 10% commission on referred user's first purchase
- Commission credited to wallet
- Maximum R1000 per referral

### 9.2 Restrictions
- Cannot refer yourself
- Fraud detection in place
- Commission subject to verification
```

### ✅ NEW Terms (Accurate):
```
### 9.1 How It Works
- Share your unique referral code with friends and colleagues
- Earn R10 bonus after successfully referring 20 users
- Earn 15% commission on all purchases made by your referred users
- Referral earnings accumulate in a "pending" state until they reach R200
- Once pending earnings reach R200, they are automatically credited to your wallet

### 9.2 Earnings Structure
- Milestone Bonus: R10 after 20 successful referrals
- Purchase Commission: 15% of referred user's purchase amount
- Minimum Payout: R200 threshold (earnings accumulate until reached)
- Automatic Payout: When pending earnings ≥ R200, funds are credited to wallet

### 9.3 Usage Restrictions
- Referral earnings can ONLY be used to purchase services within the app
- Referral funds cannot be withdrawn as cash
- Referral funds cannot be transferred to other users
- Pending earnings are visible but cannot be used until payout threshold is reached

### 9.4 Program Restrictions
- Cannot refer yourself or create duplicate accounts
- Self-referrals will result in account suspension
- Fraud detection systems monitor all referral activity
- Suspicious activity may result in forfeiture of earnings
- Commission subject to verification of legitimate purchases
- IMPACT GRAPHICS ZA reserves the right to modify or terminate the program
```

---

## Key Corrections

### 1. **Earnings Structure**
- **OLD**: 10% commission on first purchase only
- **NEW**: 15% commission on ALL purchases + R10 milestone bonus after 20 referrals

### 2. **Payout System**
- **OLD**: Immediate credit to wallet
- **NEW**: Pending earnings accumulate until R200 threshold, then auto-payout

### 3. **Usage Restrictions**
- **OLD**: No mention of usage restrictions
- **NEW**: Clear statement that funds can only be used for app purchases, not withdrawals

### 4. **Milestone Rewards**
- **OLD**: No mention of milestone bonuses
- **NEW**: R10 bonus after 20 successful referrals

### 5. **Per-Referral Limit**
- **OLD**: Maximum R1000 per referral
- **NEW**: No per-referral limit, only minimum payout threshold

---

## Implementation Details (Reference)

### From `lib/services/referral_service.dart`:

1. **Registration Reward**:
   - After 20 successful referrals: R10 added to pending earnings
   
2. **Purchase Commission**:
   ```dart
   final earnings = purchaseAmount * 0.15; // 15% commission
   ```

3. **Payout Threshold**:
   ```dart
   if (newPendingEarnings >= 200.0) {
       // Credit to wallet and reset pending
   }
   ```

4. **Pending Earnings**:
   - Stored in `pendingReferralEarnings` field
   - Visible to user but not usable until payout
   - Automatically credited when threshold reached

---

## User-Facing Benefits

### ✅ More Transparency
- Clear breakdown of how earnings are calculated
- Explicit payout threshold information
- Visible pending earnings tracking

### ✅ Better Expectations
- Users know they need R200 to receive payout
- Progress towards payout is trackable
- Milestone rewards clearly stated

### ✅ Usage Clarity
- Users understand funds are for services only
- No confusion about withdrawal options
- Clear anti-fraud policies

---

## Files Modified
1. `TERMS_AND_CONDITIONS.md` - Section 9: REFERRAL PROGRAM

## Related Documentation
- `REFERRAL_PAYOUT_THRESHOLD.md` - Technical implementation details
- `REFERRAL_THRESHOLD_SETUP.md` - Setup and configuration guide
- `lib/services/referral_service.dart` - Service implementation

---

**Status**: ✅ Complete
**Reviewed by**: AI Assistant
**Approved for**: Production Use

