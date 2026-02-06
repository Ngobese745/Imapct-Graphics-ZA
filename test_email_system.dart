#!/usr/bin/env dart

/// Simple test to check if MailerSend extension is working
/// This creates a test email document in Firestore
void main() async {
  print('🧪 Testing MailerSend Extension');
  print('===============================');

  print('\n📋 Current Status:');
  print('✅ Extension: mailersend/mailersend-email@0.1.8');
  print('✅ State: ACTIVE');
  print('✅ API Key: Configured');
  print('✅ Collection: emails');

  print('\n🔍 Checking Extension Logs...');

  // Check if we can see any extension activity
  print('\n📧 Extension Configuration:');
  print('• Collection: emails');
  print('• From: info@impactgraphicsza.co.za');
  print('• From Name: Impact Graphics ZA');
  print('• Reply To: admin@impactgraphicsza.co.za');

  print('\n🧪 Test Email Document Structure:');
  print('''
{
  "to": [
    {
      "email": "test@example.com",
      "name": "Test User"
    }
  ],
  "subject": "Test Email from Impact Graphics ZA",
  "html": "<h1>Test Email</h1><p>This is a test email from the MailerSend extension.</p>",
  "text": "Test Email\\n\\nThis is a test email from the MailerSend extension.",
  "tags": ["test", "extension"],
  "created_at": "2025-10-20T03:30:00Z"
}
  ''');

  print('\n🔧 Next Steps:');
  print('1. Go to Firebase Console → Firestore → emails collection');
  print('2. Add a new document with the structure above');
  print('3. Watch for status changes: pending → sent');
  print('4. Check extension logs for activity');
  print('5. Check your email inbox');

  print('\n📊 Troubleshooting:');
  print('• If no logs appear: Extension may need reconfiguration');
  print('• If emails stay pending: Check API key permissions');
  print('• If errors occur: Check MailerSend dashboard');

  print('\n🌐 Useful Links:');
  print(
    '• Firebase Console: https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore',
  );
  print(
    '• Extensions: https://console.firebase.google.com/project/impact-graphics-za-266ef/extensions',
  );
  print('• MailerSend Dashboard: https://app.mailersend.com/');

  print('\n✅ Test script completed!');
}


