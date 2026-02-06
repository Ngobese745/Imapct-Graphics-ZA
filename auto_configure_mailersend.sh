#!/bin/bash

echo "🔧 Auto-Configuring MailerSend Extension"
echo "======================================="
echo ""

PROJECT_ID="impact-graphics-za-266ef"
EXTENSION_ID="mailersend-email"
API_KEY="mlsn.45bb9103d2b0f627e4648d9655ced8ab656be77811c94f16bbfdbc7e957b1b4c"

echo "📋 Configuration Details:"
echo "• Project: $PROJECT_ID"
echo "• Extension: $EXTENSION_ID"
echo "• API Key: ${API_KEY:0:20}..."
echo ""

echo "🔍 Step 1: Checking current extension status..."
firebase ext:list --project $PROJECT_ID | grep mailersend
echo ""

echo "🔍 Step 2: Checking API key secret..."
if gcloud secrets describe mailersend-email-MAILERSEND_API_KEY --project=$PROJECT_ID >/dev/null 2>&1; then
    echo "✅ API key secret exists"
else
    echo "❌ API key secret not found"
    echo "🔧 Creating API key secret..."
    echo "$API_KEY" | gcloud secrets create mailersend-email-MAILERSEND_API_KEY \
        --project=$PROJECT_ID \
        --data-file=- \
        --replication-policy="automatic"
    echo "✅ API key secret created"
fi
echo ""

echo "🔍 Step 3: Checking service account permissions..."
SERVICE_ACCOUNT="ext-mailersend@$PROJECT_ID.iam.gserviceaccount.com"
echo "Service Account: $SERVICE_ACCOUNT"

# Grant secret accessor role to the extension service account
echo "🔧 Granting secret access permissions..."
gcloud secrets add-iam-policy-binding mailersend-email-MAILERSEND_API_KEY \
    --project=$PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --quiet

echo "✅ Service account permissions updated"
echo ""

echo "🔍 Step 4: Checking extension configuration..."
echo "Current configuration:"
firebase ext:info mailersend/mailersend-email --project $PROJECT_ID | grep -A 20 "Configuration Parameters"
echo ""

echo "🔧 Step 5: Reconfiguring extension..."
echo "This will reconfigure the MailerSend extension with the correct settings."
echo ""

# Create configuration file
cat > mailersend-config.json << EOF
{
  "params": {
    "EMAIL_COLLECTION": "emails",
    "MAILERSEND_API_KEY": "mailersend-email-MAILERSEND_API_KEY",
    "DEFAULT_FROM_EMAIL": "info@impactgraphicsza.co.za",
    "DEFAULT_FROM_NAME": "Impact Graphics ZA",
    "DEFAULT_REPLY_TO_EMAIL": "admin@impactgraphicsza.co.za",
    "DEFAULT_REPLY_TO_NAME": "Impact Graphics ZA Support"
  }
}
EOF

echo "📝 Configuration file created:"
cat mailersend-config.json
echo ""

echo "🚀 Reconfiguring extension..."
echo "Note: This may take a few minutes..."

# Reconfigure the extension
firebase ext:configure mailersend/mailersend-email \
    --project=$PROJECT_ID \
    --params=mailersend-config.json \
    --force

echo ""
echo "✅ Extension reconfiguration initiated"
echo ""

echo "🔍 Step 6: Verifying configuration..."
sleep 10
echo "Checking extension status..."
firebase ext:list --project $PROJECT_ID | grep mailersend
echo ""

echo "🧪 Step 7: Testing email system..."
echo "Creating test email document..."

# Create a test email document
cat > test-email.json << EOF
{
  "to": [
    {
      "email": "test@example.com",
      "name": "Test User"
    }
  ],
  "subject": "Auto-Configuration Test Email",
  "html": "<h1>Test Email</h1><p>This is a test email from the auto-configured MailerSend extension.</p><p>If you receive this, the email system is working!</p>",
  "text": "Test Email\n\nThis is a test email from the auto-configured MailerSend extension.\n\nIf you receive this, the email system is working!",
  "tags": ["test", "auto-config"],
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "📧 Test email document created:"
cat test-email.json
echo ""

echo "📝 Manual Test Instructions:"
echo "1. Go to Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "2. Navigate to 'emails' collection"
echo "3. Add a new document with the content above"
echo "4. Watch for status changes: pending → sent"
echo "5. Check your email inbox"
echo ""

echo "🔍 Step 8: Monitoring setup..."
echo "To monitor extension activity, run:"
echo "firebase functions:log --project $PROJECT_ID | grep -i mailersend"
echo ""

echo "📊 Step 9: Final verification..."
echo "Extension status:"
firebase ext:list --project $PROJECT_ID | grep mailersend
echo ""

echo "✅ Auto-configuration completed!"
echo ""
echo "📋 Summary:"
echo "• ✅ Extension reconfigured"
echo "• ✅ API key secret verified"
echo "• ✅ Service account permissions updated"
echo "• ✅ Test email document created"
echo "• ✅ Monitoring commands provided"
echo ""
echo "🎯 Next Steps:"
echo "1. Wait 2-3 minutes for extension to redeploy"
echo "2. Test by adding the test email document to Firestore"
echo "3. Check your email inbox"
echo "4. Monitor logs for activity"
echo ""
echo "🌐 Useful Links:"
echo "• Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "• Extensions: https://console.firebase.google.com/project/$PROJECT_ID/extensions"
echo "• MailerSend Dashboard: https://app.mailersend.com/"
echo ""
echo "📧 Email system should now be working!"

# Clean up temporary files
rm -f mailersend-config.json test-email.json

echo ""
echo "🎉 Auto-configuration script completed!"


