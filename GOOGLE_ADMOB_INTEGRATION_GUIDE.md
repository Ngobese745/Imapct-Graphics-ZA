# 💰 Google AdMob Integration Guide - Earn Money with Ads

## 🎯 What is Google AdMob?

Google AdMob allows you to earn money by displaying ads in your app:
- **Banner Ads**: Small ads at top/bottom of screen
- **Interstitial Ads**: Full-screen ads between pages
- **Rewarded Ads**: Users watch ad to get rewards (loyalty points, wallet credits)
- **Native Ads**: Ads that blend with your app design

### Expected Earnings:
- **Small app** (1,000 active users): $50-200/month
- **Medium app** (10,000 users): $500-2,000/month
- **Large app** (100,000+ users): $5,000-20,000/month

---

## 📋 Setup Steps

### Step 1: Create AdMob Account

1. **Go to**: https://admob.google.com/
2. **Sign in** with your Google account (colane.comfort.5@gmail.com)
3. **Click**: "Get Started"
4. **Accept** AdMob Terms and Conditions
5. **Select** country: South Africa
6. **Choose** currency: ZAR (South African Rand)

### Step 2: Add Your App to AdMob

1. **In AdMob Console**, click **"Apps"** → **"Add App"**
2. **Select**: "No" (app is not on Play Store yet)
   - Or "Yes" if you've published it
3. **Enter app name**: "Impact Graphics ZA"
4. **Select platform**: 
   - Android (for Android app)
   - iOS (for iPhone app)
   - Or both if you have both versions
5. **Click**: "Add"

### Step 3: Create Ad Units

For each type of ad you want:

**Banner Ad**:
1. Click "Ad units" → "Add ad unit"
2. Select "Banner"
3. Name: "Home Banner" (or any name)
4. Click "Create ad unit"
5. **Copy the Ad Unit ID** (looks like: ca-app-pub-XXXXX/YYYYY)

**Interstitial Ad**:
1. Same steps, select "Interstitial"
2. Name: "Order Completion Ad"
3. **Copy the Ad Unit ID**

**Rewarded Ad**:
1. Same steps, select "Rewarded"
2. Name: "Loyalty Points Reward"
3. **Copy the Ad Unit ID**

### Step 4: Get Your App ID

1. In AdMob Console, go to **Apps** → Your app
2. **Copy the App ID** (looks like: ca-app-pub-XXXXX~YYYYY)
3. Keep this for the next steps

---

## 🔧 Flutter Integration

### Step 1: Add AdMob Package

Add to `pubspec.yaml`:

```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za"
flutter pub add google_mobile_ads
```

### Step 2: Configure Android

**File**: `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_ADMOB_APP_ID"/>
```

### Step 3: Configure iOS

**File**: `ios/Runner/Info.plist`

Add:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-YOUR_ADMOB_APP_ID</string>
```

---

## 💻 Code Implementation

### Step 1: Initialize AdMob

I'll create an AdMob service for you:

```dart
// lib/services/admob_service.dart
import 'package:google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Replace with YOUR AdMob IDs
  static const String appId = 'ca-app-pub-XXXXX~YYYYY';
  static const String bannerAdUnitId = 'ca-app-pub-XXXXX/YYYYY';
  static const String interstitialAdUnitId = 'ca-app-pub-XXXXX/YYYYY';
  static const String rewardedAdUnitId = 'ca-app-pub-XXXXX/YYYYY';

  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    print('AdMob initialized');
  }

  // Load banner ad
  Future<void> loadBannerAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) async {
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
    await bannerAd?.load();
  }

  // Load interstitial ad
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          print('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (interstitialAd != null) {
      interstitialAd!.show();
      interstitialAd = null; // Dispose after showing
      loadInterstitialAd(); // Load next ad
    }
  }

  // Load rewarded ad
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          print('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  // Show rewarded ad with callback for rewards
  Future<void> showRewardedAd({
    required Function(RewardedAd ad, RewardItem reward) onUserEarnedReward,
  }) async {
    if (rewardedAd != null) {
      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd(); // Load next ad
        },
      );
      rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      rewardedAd = null;
    }
  }

  void dispose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAd?.dispose();
  }
}
```

---

## 🎨 Where to Place Ads (Best Practices)

### 1. Banner Ads (Non-Intrusive)
**Good Locations**:
- ✅ Bottom of Dashboard screen
- ✅ Bottom of Service Hub
- ✅ Bottom of Orders screen

**Avoid**:
- ❌ During checkout/payment
- ❌ In chat/consultation screens
- ❌ During critical user actions

### 2. Interstitial Ads (Full-Screen)
**Good Timing**:
- ✅ After completing an order
- ✅ After 3-4 screen navigations
- ✅ When user finishes reading resources/docs

**Avoid**:
- ❌ Right when app opens
- ❌ During payment process
- ❌ Too frequently (max 1 per minute)

### 3. Rewarded Ads (Best for Your App!)
**Perfect For**:
- ✅ **Watch ad → Get 50 loyalty points**
- ✅ **Watch ad → Get R10 wallet credit**
- ✅ **Watch ad → Unlock premium content**

**Example Implementation**:
```dart
// In wallet screen, add button:
ElevatedButton.icon(
  onPressed: () => _watchAdForCredit(),
  icon: Icon(Icons.play_circle),
  label: Text('Watch Ad - Get R10 Credit'),
)

void _watchAdForCredit() {
  AdMobService().showRewardedAd(
    onUserEarnedReward: (ad, reward) {
      // User watched the ad!
      // Give them R10 wallet credit
      WalletService.addFunds(userId, 10.0, 'Ad reward');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('R10 added to your wallet!')),
      );
    },
  );
}
```

---

## 💡 Strategic Ad Placement for Your App

### Recommended Setup:

**1. Dashboard Screen** (Banner at bottom)
- Shows all the time
- Doesn't interfere with functionality
- Earns passive income

**2. After Order Placement** (Interstitial)
- User just placed order
- Natural break point
- Good engagement moment

**3. Loyalty Rewards** (Rewarded Ad)
- "Watch ad to earn 100 points"
- "Watch ad to get R20 wallet credit"
- Users CHOOSE to watch = better engagement

**4. Service Hub** (Banner at bottom)
- Users browse services
- More time on screen = more impressions

---

## 💵 Revenue Optimization

### Ad Types by Revenue:

1. **Rewarded Ads**: $2-10 per 1000 views (HIGHEST)
   - Use for loyalty points/wallet credits
   
2. **Interstitial Ads**: $1-5 per 1000 views (HIGH)
   - Use after key actions
   
3. **Banner Ads**: $0.50-2 per 1000 views (MODERATE)
   - Use for passive income

### Best Strategy for Your App:

**Free Tier Users**: Show ads
- Banner on dashboard
- Interstitial after order
- Rewarded for bonuses

**Paid Tier Users** (Gold/Premium): No ads
- Better user experience
- Incentive to upgrade

**Example**:
```dart
// Only show ads to free users
if (!user.isGoldTier && !user.isPremiumPackage) {
  _showBannerAd();
}
```

---

## 🚀 Quick Start Implementation

### Option 1: I Can Implement It For You

I can add AdMob integration to your app with:
- Banner ads on dashboard
- Rewarded ads for wallet credits
- Proper placement and timing
- No ads for premium users

**Just say**: "Add AdMob to my app" and tell me your AdMob App ID and Ad Unit IDs.

### Option 2: DIY Implementation

1. Follow steps above
2. Add `google_mobile_ads` package
3. Create `admob_service.dart`
4. Add banner to dashboard
5. Test with test ad IDs first

---

## 🧪 Testing with Test Ads

**Before going live**, use these test IDs:

**Android**:
- Banner: `ca-app-pub-3940256099942544/6300978111`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Rewarded: `ca-app-pub-3940256099942544/5224354917`

**iOS**:
- Banner: `ca-app-pub-3940256099942544/2934735716`
- Interstitial: `ca-app-pub-3940256099942544/4411468910`
- Rewarded: `ca-app-pub-3940256099942544/1712485313`

---

## 📊 Expected Revenue (South Africa)

### Assumptions:
- 100 daily active users
- 5 ad impressions per user per day
- Average CPM: $1.50 (South Africa rate)

### Monthly Estimate:
```
100 users × 5 ads × 30 days = 15,000 impressions/month
15,000 ÷ 1000 × $1.50 = $22.50/month (≈R400-450)
```

### If You Grow to 1,000 Users:
```
1,000 users × 5 ads × 30 days = 150,000 impressions
150,000 ÷ 1000 × $1.50 = $225/month (≈R4,000-4,500)
```

---

## ✨ Best Ad Strategy for Impact Graphics ZA

### Scenario 1: Wallet Credit Rewards (Recommended!)

**Add "Watch Ad" button in Wallet Screen**:
- User clicks "Earn R10 - Watch Ad"
- Shows 30-second rewarded video
- After watching, adds R10 to wallet
- Win-win: User gets credit, you earn money

**Revenue**: $0.05-0.20 per ad watched
**User benefit**: Free wallet credit
**Engagement**: High (users choose to watch)

### Scenario 2: Loyalty Points Boost

**In Loyalty/Rewards Section**:
- "Watch ad → Get 50 bonus points"
- Shows rewarded ad
- User earns loyalty points
- You earn ad revenue

### Scenario 3: Unlock Features

**Premium Content Access**:
- "Watch ad to unlock this resource"
- "Watch ad for premium template"
- Alternative to paying

---

## 🎯 Implementation Priority

### Phase 1 (Start Small):
1. Add rewarded ads for wallet credits
2. Test with real users
3. Monitor earnings

### Phase 2 (If Successful):
1. Add banner to dashboard (if not annoying)
2. Add interstitial after order placement
3. Optimize placement

### Phase 3 (Scale):
1. A/B test ad placements
2. Add native ads in feed
3. Optimize for highest CPM

---

## 📱 User Experience Considerations

### Good Ad Practices:
- ✅ Give users value (rewards, credits)
- ✅ Make ads optional (rewarded)
- ✅ Don't show during critical actions
- ✅ No ads for paying customers
- ✅ Respect user experience

### Bad Ad Practices:
- ❌ Too many ads
- ❌ Ads during payment
- ❌ Auto-play video ads
- ❌ Covering important buttons
- ❌ Showing to premium users

---

## 🔍 AdMob Requirements

### To Get Approved:
- ✅ App must be published (Google Play or App Store)
- ✅ No prohibited content
- ✅ Follow Google policies
- ✅ Have privacy policy
- ✅ Minimum 1000 active users (for some ad types)

### Timeline:
- Sign up: Instant
- App review: 1-3 days
- First earnings: After approval
- Payout: Monthly (minimum $100)

---

## 💳 Payment Setup

### How You Get Paid:
1. Earnings accumulate in AdMob
2. Once you reach $100 (≈R1,800), you get paid
3. Payment methods:
   - Bank transfer (EFT)
   - Wire transfer
   - Western Union

### Setup Payment:
1. AdMob Console → Payments
2. Add payment information
3. Verify address and tax info
4. Set payment threshold

---

## 🚀 Quick Start (If You Want Me to Implement)

I can add AdMob to your app right now with:

### What I'll Add:
1. ✅ AdMob service class
2. ✅ Rewarded ad for wallet credits
3. ✅ Banner ad on dashboard (optional)
4. ✅ Only show to free users (not Gold tier)
5. ✅ Proper initialization
6. ✅ Error handling

### What You Need to Provide:
- Your AdMob App ID
- Ad Unit IDs for each ad type
- Where you want ads displayed

---

## 🎯 My Recommendation

**Start with Rewarded Ads Only**:

**Why**:
- Best user experience
- Highest revenue per ad
- Users CHOOSE to watch
- Gives value to users
- Builds goodwill

**Implementation**:
1. Add "Earn R10" button in Wallet screen
2. User watches 30-second ad
3. Gets R10 wallet credit automatically
4. You earn $0.10-0.50 per ad watched

**If 50 users watch daily**:
- Daily: 50 × $0.20 = $10
- Monthly: $300 (≈R5,400)
- Plus you keep users happy!

---

## 📋 Next Steps

**Want me to implement AdMob?**

Tell me:
1. Do you want me to add AdMob integration?
2. Which ad types? (Rewarded, Banner, Interstitial)
3. Have you created AdMob account yet?

Or I can:
- Create the AdMob service file
- Add rewarded ads for wallet credits
- Add banner ads (optional)
- Implement proper placement

---

## 🎊 Bottom Line

**AdMob can add $100-500/month** to your income with just:
- Rewarded ads for wallet credits
- Good user experience
- No annoying pop-ups

**Would you like me to implement it? Just provide your AdMob IDs!** 💰

---

## 🔗 Useful Links

- AdMob Sign Up: https://admob.google.com/
- Flutter AdMob Guide: https://pub.dev/packages/google_mobile_ads
- AdMob Policies: https://support.google.com/admob/answer/6128543
- Revenue Calculator: https://www.blog.google/products/admob/admob-revenue-calculator/

