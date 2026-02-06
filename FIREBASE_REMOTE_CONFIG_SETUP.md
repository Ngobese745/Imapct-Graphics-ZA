# 🔥 Firebase Remote Config Setup Guide

## Overview
Firebase Remote Config allows you to dynamically configure your app behavior without releasing new versions. This guide will help you set up Remote Config for your Impact Graphics ZA app.

## 📋 Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/impact-graphics-za-266ef/config)
2. Select your project: **IMPACT GRAPHICS ZA**
3. Click on **Remote Config** in the left sidebar

## ⚙️ Step 2: Create Configuration Parameters

Click **"Create configuration"** and add the following parameters:

### 🚨 Maintenance & App Control
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `maintenance_mode` | `false` | Enable/disable maintenance mode |
| `maintenance_message` | `"We are currently performing maintenance. Please try again later."` | Message shown during maintenance |
| `app_version_required` | `"2.0.0"` | Minimum required app version |

### 🎛️ Feature Flags
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `enable_gold_tier` | `true` | Enable/disable Gold Tier feature |
| `enable_referral_system` | `true` | Enable/disable referral system |
| `enable_loyalty_points` | `true` | Enable/disable loyalty points |
| `enable_social_media_boost` | `true` | Enable/disable social media boost |
| `enable_marketing_packages` | `true` | Enable/disable marketing packages |
| `enable_daily_ads` | `true` | Enable/disable daily ads |

### 💰 Payment Configuration
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `enable_wallet_funding` | `true` | Enable/disable wallet funding |
| `min_wallet_amount` | `10.0` | Minimum wallet funding amount |
| `max_wallet_amount` | `10000.0` | Maximum wallet funding amount |

### 🎯 Ad Configuration
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `daily_ad_limit` | `100` | Daily ad limit per user |
| `ad_reward_amount` | `10.0` | Reward amount per ad completion |

### 📧 Email Configuration
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `enable_email_notifications` | `true` | Enable/disable email notifications |
| `enable_welcome_emails` | `true` | Enable/disable welcome emails |
| `enable_order_emails` | `true` | Enable/disable order emails |

### 🎨 UI Configuration
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `primary_color` | `"#8B0000"` | Primary app color |
| `secondary_color` | `"#00AA00"` | Secondary app color |
| `enable_dark_mode` | `true` | Enable/disable dark mode |

### 📱 Marketing Messages
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `welcome_message` | `"Welcome to Impact Graphics ZA!"` | Welcome message |
| `app_description` | `"Professional graphic design services for your business."` | App description |

### 🔗 Social Media Links
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `facebook_url` | `"https://facebook.com/impactgraphicsza"` | Facebook page URL |
| `instagram_url` | `"https://instagram.com/impactgraphicsza"` | Instagram page URL |
| `twitter_url` | `"https://twitter.com/impactgraphicsza"` | Twitter page URL |

### 🆘 Support Configuration
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `support_email` | `"support@impactgraphicsza.co.za"` | Support email |
| `support_phone` | `"+27 68 367 5755"` | Support phone |
| `business_hours` | `"Mon-Fri: 9:00 AM - 5:00 PM"` | Business hours |

### ⚡ Performance Settings
| Parameter Key | Default Value | Description |
|---------------|---------------|-------------|
| `cache_duration` | `3600` | Cache duration in seconds |
| `max_retry_attempts` | `3` | Max retry attempts |
| `request_timeout` | `30` | Request timeout in seconds |

## 🚀 Step 3: Publish Configuration

1. After adding all parameters, click **"Publish changes"**
2. Add a description (e.g., "Initial Remote Config setup")
3. Click **"Publish"**

## 🔧 Step 4: Set Up Conditions (Optional)

You can create conditions to show different values to different users:

### Example Conditions:
- **New Users**: Show different welcome message
- **Premium Users**: Enable additional features
- **Specific App Versions**: Show version-specific features

### How to Create Conditions:
1. Click on a parameter
2. Click **"Add value for condition"**
3. Choose condition type (e.g., "App version")
4. Set condition criteria
5. Set the value for that condition

## 📱 Step 5: Test in Your App

### Using Remote Config in Your App:

```dart
// Initialize (already done in main.dart)
await RemoteConfigService().initialize();

// Check maintenance mode
if (RemoteConfigService().isMaintenanceMode) {
  // Show maintenance screen
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => const MaintenanceScreen(),
  ));
}

// Check feature flags
if (RemoteConfigService().isGoldTierEnabled) {
  // Show Gold Tier features
}

// Get configuration values
final supportEmail = RemoteConfigService().supportEmail;
final primaryColor = RemoteConfigService().primaryColor;
```

## 🔄 Step 6: Update Configuration

### Real-time Updates:
- Changes are fetched when the app starts
- Changes are cached for 1 hour (configurable)
- Force refresh: `RemoteConfigService().forceRefresh()`

### Publishing Updates:
1. Modify parameters in Firebase Console
2. Click **"Publish changes"**
3. Users will get updates on next app start

## 🧪 Testing

### Test Different Scenarios:
1. **Maintenance Mode**: Set `maintenance_mode` to `true`
2. **Feature Flags**: Disable features temporarily
3. **A/B Testing**: Use conditions to test different values

### Debug Information:
- Check console logs for Remote Config status
- Use `RemoteConfigService().getAllValues()` to see all current values

## 📊 Monitoring

### Firebase Console:
- View parameter usage
- Monitor fetch success rates
- See active users

### App Analytics:
- Track how configuration changes affect user behavior
- Monitor feature usage

## 🚨 Common Use Cases

### 1. Emergency Maintenance
```dart
// Set maintenance_mode to true in Firebase Console
// App will show maintenance screen immediately
```

### 2. Feature Rollout
```dart
// Gradually enable new features
// Use conditions to target specific user groups
```

### 3. A/B Testing
```dart
// Test different UI colors, messages, or features
// Use conditions to split users into groups
```

### 4. Dynamic Pricing
```dart
// Update service prices without app updates
// Use conditions for different user tiers
```

## ✅ Benefits

- **🚀 Instant Updates**: Change app behavior without app store approval
- **🎯 Targeted Changes**: Different values for different user groups
- **🧪 A/B Testing**: Test features with real users
- **🚨 Emergency Control**: Quickly disable features or enable maintenance mode
- **📊 Analytics**: Monitor how changes affect user behavior

## 🔗 Next Steps

1. Set up the parameters in Firebase Console
2. Test with different values
3. Create conditions for targeted updates
4. Monitor usage and performance
5. Use for feature rollouts and A/B testing

---
*Remote Config setup guide for Impact Graphics ZA v2.0*  
*Created: $(date)*
