#!/usr/bin/env dart

import 'lib/services/mailersend_service.dart';

/// Test script for MailerSend service
/// Run this with: dart test_mailersend.dart
void main() async {
  print('🧪 Testing MailerSend Service Integration');
  print('=====================================');

  // Test proposal email
  print('\n📧 Testing Proposal Email...');
  final proposalResult = await MailerSendService.sendProposalEmail(
    toEmail: 'test@example.com',
    toName: 'Test Client',
    subject: 'Test Proposal - Logo Design Package',
    body:
        'This is a test proposal email sent via MailerSend Firebase extension. We are excited to work with you on your logo design project!',
    proposalType: 'Logo Design Package',
    proposalValue: '2500',
  );

  print('Proposal Email Result:');
  print('  Success: ${proposalResult.success}');
  print('  Message ID: ${proposalResult.messageId}');
  print('  Message: ${proposalResult.message}');
  if (proposalResult.errorCode != null) {
    print('  Error Code: ${proposalResult.errorCode}');
  }

  // Test welcome email
  print('\n📧 Testing Welcome Email...');
  final welcomeResult = await MailerSendService.sendWelcomeEmail(
    toEmail: 'newuser@example.com',
    toName: 'New User',
  );

  print('Welcome Email Result:');
  print('  Success: ${welcomeResult.success}');
  print('  Message ID: ${welcomeResult.messageId}');
  print('  Message: ${welcomeResult.message}');
  if (welcomeResult.errorCode != null) {
    print('  Error Code: ${welcomeResult.errorCode}');
  }

  // Test payment confirmation
  print('\n📧 Testing Payment Confirmation...');
  final paymentResult = await MailerSendService.sendPaymentConfirmation(
    toEmail: 'customer@example.com',
    toName: 'Test Customer',
    transactionId: 'TXN-123456789',
    amount: 2500.00,
    serviceName: 'Logo Design Package',
    orderNumber: 'ORD-2024-001',
    paymentMethod: 'Paystack',
  );

  print('Payment Confirmation Result:');
  print('  Success: ${paymentResult.success}');
  print('  Message ID: ${paymentResult.messageId}');
  print('  Message: ${paymentResult.message}');
  if (paymentResult.errorCode != null) {
    print('  Error Code: ${paymentResult.errorCode}');
  }

  // Test appointment reminder
  print('\n📧 Testing Appointment Reminder...');
  final appointmentResult = await MailerSendService.sendAppointmentReminder(
    toEmail: 'client@example.com',
    toName: 'Test Client',
    appointmentDate: '2024-01-15',
    appointmentTime: '2:00 PM',
    appointmentType: 'Discovery Call',
  );

  print('Appointment Reminder Result:');
  print('  Success: ${appointmentResult.success}');
  print('  Message ID: ${appointmentResult.messageId}');
  print('  Message: ${appointmentResult.message}');
  if (appointmentResult.errorCode != null) {
    print('  Error Code: ${appointmentResult.errorCode}');
  }

  print('\n✅ Test completed!');
  print('\n📋 Next Steps:');
  print('1. Check your Firebase Console → Firestore → emails collection');
  print('2. Verify the MailerSend extension is processing the emails');
  print('3. Check your email inbox for test emails');
  print('4. Monitor Firebase Functions logs for any errors');
}
