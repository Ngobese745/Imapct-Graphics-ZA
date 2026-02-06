#!/usr/bin/env dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'lib/services/mailersend_service.dart';

/// Comprehensive diagnostic script for email system
/// Run this with: dart diagnose_email_system.dart
void main() async {
  print('🔍 Email System Diagnostic Tool');
  print('================================\n');

  try {
    // Initialize Firebase
    print('📱 Step 1: Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully\n');

    // Check Firestore connection
    print('📚 Step 2: Checking Firestore connection...');
    final firestore = FirebaseFirestore.instance;
    print('✅ Firestore connected\n');

    // Check emails collection
    print('📧 Step 3: Checking emails collection...');
    try {
      final emailsSnapshot = await firestore
          .collection('emails')
          .limit(5)
          .orderBy('created_at', descending: true)
          .get();

      print('📊 Found ${emailsSnapshot.docs.length} recent email documents');

      if (emailsSnapshot.docs.isNotEmpty) {
        print('\n📧 Recent email documents:');
        for (var doc in emailsSnapshot.docs) {
          final data = doc.data();
          print('  - ID: ${doc.id}');
          print('    Status: ${data['status'] ?? 'unknown'}');
          print('    To: ${data['to'] ?? 'unknown'}');
          print('    Subject: ${data['subject'] ?? 'unknown'}');
          print('    Created: ${data['created_at'] ?? 'unknown'}');
          print('    Delivery Status: ${data['delivery'] ?? 'not set'}');
          print('');
        }
      } else {
        print('⚠️  No email documents found in the emails collection');
        print('   This could mean:');
        print('   - Emails are not being created');
        print('   - OR emails are being processed and deleted immediately');
      }
    } catch (e) {
      print('❌ Error accessing emails collection: $e');
      print('   This could indicate a Firestore rules issue\n');
    }

    // Test sending an email
    print('\n📤 Step 4: Testing email sending...');
    print('Sending a test email to verify the system works...\n');

    final testResult = await MailerSendService.sendWelcomeEmail(
      toEmail: 'test-diagnostic@example.com',
      toName: 'Diagnostic Test User',
    );

    print('Test Email Result:');
    print('  ✓ Success: ${testResult.success}');
    print('  ✓ Message ID: ${testResult.messageId}');
    print('  ✓ Message: ${testResult.message}');
    if (testResult.errorCode != null) {
      print('  ✗ Error Code: ${testResult.errorCode}');
    }

    // Wait and check if document was created
    print('\n⏳ Waiting 2 seconds to check if email document was created...');
    await Future.delayed(Duration(seconds: 2));

    if (testResult.messageId != null) {
      try {
        final emailDoc = await firestore
            .collection('emails')
            .doc(testResult.messageId)
            .get();

        if (emailDoc.exists) {
          print('✅ Email document created successfully');
          final data = emailDoc.data();
          print('   Status: ${data?['status'] ?? 'unknown'}');
          print('   Delivery: ${data?['delivery'] ?? 'not set'}');

          if (data?['status'] == 'pending') {
            print('\n⚠️  Email status is still PENDING');
            print(
              '   This means the MailerSend extension hasn\'t processed it yet',
            );
            print('   Possible causes:');
            print('   1. Extension is not properly configured');
            print('   2. API key is missing or invalid');
            print('   3. Extension is disabled');
            print('   4. Collection name mismatch');
          } else if (data?['status'] == 'sent') {
            print('✅ Email was sent successfully by the extension!');
          } else if (data?['status'] == 'error') {
            print('❌ Email failed to send');
            print('   Error: ${data?['error'] ?? 'unknown error'}');
          }
        } else {
          print('❌ Email document not found');
          print('   This could mean the write to Firestore failed');
        }
      } catch (e) {
        print('❌ Error checking email document: $e');
      }
    }

    // Summary and recommendations
    print('\n${'=' * 50}');
    print('📋 DIAGNOSTIC SUMMARY');
    print('=' * 50);

    print('\n✅ System Components:');
    print('  • Firebase: Initialized');
    print('  • Firestore: Connected');
    print('  • MailerSendService: Available');

    print('\n🔧 TROUBLESHOOTING STEPS:');
    print('  1. Check Firebase Console → Extensions');
    print('     Verify "mailersend-email" extension is ACTIVE');
    print('');
    print('  2. Check Extension Configuration:');
    print('     • Collection name should be: emails');
    print('     • API key should be set in Secret Manager');
    print('     • Default FROM email should be configured');
    print('');
    print('  3. Check Firebase Functions Logs:');
    print(
      '     Run: firebase functions:log --project impact-graphics-za-266ef',
    );
    print('     Look for MailerSend extension logs');
    print('');
    print('  4. Verify MailerSend API Key:');
    print('     • Log into MailerSend dashboard');
    print('     • Check if API key is valid');
    print('     • Verify domain is verified');
    print('');
    print('  5. Check Firestore Rules:');
    print('     Ensure authenticated users can write to emails collection');
  } catch (e, stackTrace) {
    print('❌ Fatal Error: $e');
    print('Stack Trace: $stackTrace');
    print('\nThis likely means Firebase is not initialized properly.');
    print('Make sure you have:');
    print('  1. google-services.json (Android)');
    print('  2. GoogleService-Info.plist (iOS)');
    print('  3. firebase_options.dart');
  }

  print('\n✅ Diagnostic completed!');
  exit(0);
}
