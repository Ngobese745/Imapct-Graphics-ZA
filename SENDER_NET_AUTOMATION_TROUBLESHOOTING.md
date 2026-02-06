# Sender.net Welcome Email Automation Troubleshooting Guide

## ✅ What's Working
- API integration is working correctly
- Subscribers are being added to the "Welcome" group (ID: b4KQA6)
- Custom fields are being set properly
- Flutter app integration is functioning

## 🔍 Troubleshooting Steps

### Step 1: Verify Automation Workflow Exists
1. Log into your Sender.net dashboard
2. Navigate to **Automation** → **Workflows**
3. Look for a workflow that should trigger on group addition
4. If no workflow exists, you need to create one

### Step 2: Check Workflow Configuration
If a workflow exists, verify these settings:

#### Trigger Settings:
- **Trigger Type**: "Subscriber added to group"
- **Group**: "Welcome" (ID: b4KQA6)
- **Status**: Active/Enabled

#### Action Settings:
- **Action Type**: "Send email"
- **Email Template**: Your welcome email template
- **Recipient**: The subscriber who was added

### Step 3: Test the Workflow
1. In Sender.net, go to **Automation** → **Workflows**
2. Find your welcome workflow
3. Click **Test** or **Preview**
4. Select a test subscriber from the "Welcome" group
5. Run the test to see if the email is sent

### Step 4: Check Automation Logs
1. Go to **Automation** → **Logs** or **Activity**
2. Look for recent entries when you added test subscribers
3. Check if the workflow was triggered
4. Look for any error messages

### Step 5: Verify Email Template
1. Go to **Templates** or **Emails**
2. Find your welcome email template
3. Make sure it's published and active
4. Check if it uses the correct merge fields:
   - `{{client_name}}` for the user's name
   - `{{message_body}}` for the welcome message

## 🚨 Common Issues and Solutions

### Issue 1: No Automation Workflow
**Problem**: No workflow exists to trigger welcome emails
**Solution**: Create a new automation workflow with:
- Trigger: Subscriber added to group "Welcome"
- Action: Send email with your template

### Issue 2: Workflow Not Active
**Problem**: Workflow exists but is disabled
**Solution**: Enable the workflow in Sender.net dashboard

### Issue 3: Wrong Trigger Group
**Problem**: Workflow is set to trigger on a different group
**Solution**: Update the trigger to use group "Welcome" (ID: b4KQA6)

### Issue 4: Email Template Issues
**Problem**: Template is not published or has errors
**Solution**: Publish the template and test it manually

### Issue 5: Automation Delays
**Problem**: Sender.net has processing delays
**Solution**: Wait 5-10 minutes and check again

## 🧪 Testing Steps

### Test 1: Manual Workflow Test
1. Go to Sender.net dashboard
2. Find your welcome workflow
3. Click "Test" or "Preview"
4. Select a test subscriber
5. Send test email

### Test 2: Add New Test Subscriber
1. Use the Flutter app to create a new account
2. Check Sender.net dashboard for the new subscriber
3. Verify they're in the "Welcome" group
4. Check automation logs for workflow trigger

### Test 3: Check Email Delivery
1. Check the test email address
2. Look in spam/junk folder
3. Check Sender.net delivery logs

## 📞 Sender.net Support

If the issue persists after following these steps:
1. Contact Sender.net support
2. Provide them with:
   - Your account details
   - Group ID: b4KQA6
   - Test subscriber email addresses
   - Screenshots of your automation workflow settings

## 🔧 Quick Fix Checklist

- [ ] Automation workflow exists
- [ ] Workflow is active/enabled
- [ ] Trigger is set to "Subscriber added to group"
- [ ] Correct group "Welcome" (b4KQA6) is selected
- [ ] Action is set to "Send email"
- [ ] Email template is published and active
- [ ] Template uses correct merge fields
- [ ] Test the workflow manually
- [ ] Check automation logs
- [ ] Verify email delivery

## 📧 Test Email Addresses

Use these test emails to verify the automation:
- `test-${timestamp}@impactgraphicsza.co.za`
- `newuser-${timestamp}@impactgraphicsza.co.za`

Remember to check spam folders and Sender.net delivery logs!
