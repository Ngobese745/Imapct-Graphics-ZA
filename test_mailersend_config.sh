#!/bin/bash

echo "🧪 MailerSend Extension Test Script"
echo "==================================="
echo ""

PROJECT_ID="impact-graphics-za-266ef"

echo "📋 Current Extension Status:"
firebase ext:list --project $PROJECT_ID | grep mailersend
echo ""

echo "🔍 Recent Extension Logs (last 20 lines):"
firebase functions:log --project $PROJECT_ID 2>&1 | grep -i "ext-mailersend\|mailersend\|processDocumentCreated" | tail -20
echo ""

echo "📧 Test Email Document for Firestore:"
echo "====================================="
cat << 'EOF'
{
  "to": [
    {
      "email": "your-email@example.com",
      "name": "Test User"
    }
  ],
  "subject": "MailerSend Extension Test",
  "html": "<h1>Test Email</h1><p>This is a test email from the MailerSend extension.</p><p>If you receive this, the email system is working!</p>",
  "text": "Test Email\n\nThis is a test email from the MailerSend extension.\n\nIf you receive this, the email system is working!",
  "tags": ["test", "extension"],
  "created_at": "2025-10-20T01:53:06Z"
}
EOF
echo ""

echo "🔧 Instructions:"
echo "1. Go to Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "2. Navigate to 'emails' collection"
echo "3. Add a new document with the JSON above"
echo "4. Watch for status changes: pending → sent"
echo "5. Check your email inbox"
echo ""

echo "📊 Monitoring Commands:"
echo "• Check logs: firebase functions:log --project $PROJECT_ID | grep -i mailersend"
echo "• Check status: firebase ext:list --project $PROJECT_ID"
echo ""

echo "🌐 Useful Links:"
echo "• Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "• Extensions: https://console.firebase.google.com/project/$PROJECT_ID/extensions"
echo "• MailerSend Dashboard: https://app.mailersend.com/"
echo ""

echo "✅ Test script completed!"


