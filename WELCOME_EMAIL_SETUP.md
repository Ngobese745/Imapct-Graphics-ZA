# Welcome Email Setup Guide

## Overview
This guide explains how to set up automated welcome emails for new users in the Impact Graphics ZA app using Sender.net.

## What's Implemented

### 1. Welcome Email Service (`lib/services/welcome_email_service.dart`)
- **Purpose**: Sends welcome emails to new users via Sender.net API
- **Key Features**:
  - Triggers Sender.net workflow for new user onboarding
  - Uses only the user's name (email template contains all other information)
  - Handles errors gracefully without affecting user signup process
  - Includes test functionality

### 2. Integration with AuthService
- **Location**: `lib/services/auth_service.dart`
- **Integration Points**:
  - Main signup flow (after successful user profile creation)
  - Fallback signup flow (keychain error recovery)
- **Error Handling**: Welcome email failures don't prevent user signup

## Sender.net Setup Required

### Step 1: Create Welcome Group
1. Log into your Sender.net account
2. Go to **Subscribers** → **Groups**
3. Create a new group called "Welcome Group" or similar
4. Note the group ID (you'll need this for the code)

### Step 2: Create Welcome Workflow
1. Go to **Automations** → **Workflows**
2. Create a new workflow called "Welcome New Users"
3. Set trigger: **New subscriber added to group** → Select your welcome group
4. Add action: **Send email**

### Step 3: Configure Email Template
1. In the workflow, click on the email action
2. Use the HTML template from `email_templates/sender_net_welcome_template.html`
3. Configure these custom fields:
   - `{{client_name}}` - User's full name
   - `{{message_body}}` - Welcome message content
   - `{{welcome_trigger}}` - Trigger field (set to "true")

### Step 4: Update Group ID in Code
In `lib/services/welcome_email_service.dart`, update the group ID:
```dart
'groups': ['YOUR_WELCOME_GROUP_ID_HERE'], // Replace with actual group ID
```

## Testing

### Run Test Script
```bash
cd /Volumes/work/Impact\ Graphics\ ZA/impact_graphics_za
dart test_welcome_email.dart
```

### Test New User Signup
1. Run the app
2. Create a new user account
3. Check the console logs for welcome email status
4. Check the user's email inbox

## Email Template Features

The welcome email template includes:
- **Professional branding** with Impact Graphics ZA colors and logo
- **Personalized greeting** using `{{client_name}}`
- **Service overview** showcasing company capabilities
- **Call-to-action** button to contact the company
- **Contact information** and social links
- **Responsive design** for mobile and desktop
- **Unsubscribe link** for compliance

## Customization

### Modify Welcome Message
Edit the `message_body` field in the welcome email service:
```dart
'message_body': 'Your custom welcome message here',
```

### Update Email Template
Modify `email_templates/sender_net_welcome_template.html` and update in Sender.net

### Add More Fields
If you need additional personalization, add fields to both:
1. The Sender.net workflow template
2. The `requestBody` in `welcome_email_service.dart`

## Troubleshooting

### Common Issues
1. **Group ID not found**: Verify the group exists in Sender.net
2. **Template not rendering**: Check field names match exactly
3. **Emails not sending**: Verify API key and permissions
4. **User signup failing**: Check console logs for welcome email errors

### Debug Steps
1. Check console logs for detailed error messages
2. Test with the standalone test script
3. Verify Sender.net workflow is active
4. Check API key permissions in Sender.net

## Security Notes
- API key is currently hardcoded (consider moving to environment variables)
- Welcome email failures don't affect user signup process
- All email operations are logged for debugging

## Future Enhancements
- Move API key to secure environment variables
- Add retry logic for failed welcome emails
- Implement email preferences for users
- Add A/B testing for welcome email templates
