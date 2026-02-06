import 'package:cloud_firestore/cloud_firestore.dart';

/// MailerSend service that uses Firebase extension to send emails
/// This service writes to the Firestore 'emails' collection which triggers
/// the MailerSend Firebase extension to send the actual emails
class MailerSendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send promo email with custom content using MailerSend via Firebase extension
  static Future<EmailResult> sendPromoEmailWithContent({
    required String toEmail,
    required String toName,
    required String subject,
    required String templateId,
    required String content,
    required String customMessage,
  }) async {
    try {
      print(
        '📧 MailerSend: Sending promo email with custom content to: $toEmail',
      );
      print('📧 Template ID: $templateId');

      // Create the email document for MailerSend extension
      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': subject,
        'html': _generatePromoHtmlWithContent(
          subject: subject,
          templateId: templateId,
          content: content,
          customMessage: customMessage,
          clientName: toName,
        ),
        'text': _generatePromoTextWithContent(
          subject: subject,
          templateId: templateId,
          content: content,
          customMessage: customMessage,
          clientName: toName,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'tags': ['promo', 'marketing', templateId],
        'created_at': FieldValue.serverTimestamp(),
      };

      // Write to Firestore to trigger MailerSend extension
      await _firestore.collection('emails').add(emailData);

      print('✅ MailerSend: Email queued successfully for: $toEmail');
      return EmailResult.successResult('Email sent successfully');
    } catch (e) {
      print('❌ MailerSend: Error sending email to $toEmail: $e');
      return EmailResult.errorResult('Failed to send email: $e');
    }
  }

  /// Send promo email using MailerSend via Firebase extension
  static Future<EmailResult> sendPromoEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String templateId,
    required String customMessage,
  }) async {
    try {
      print('📧 MailerSend: Sending promo email to: $toEmail');
      print('📧 Template ID: $templateId');

      // Create the email document for MailerSend extension
      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': subject,
        'html': _generatePromoHtml(
          subject: subject,
          templateId: templateId,
          customMessage: customMessage,
          clientName: toName,
        ),
        'text': _generatePromoText(
          subject: subject,
          templateId: templateId,
          customMessage: customMessage,
          clientName: toName,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'tags': ['promo', 'marketing', templateId],
        'created_at': FieldValue.serverTimestamp(),
      };

      // Write to Firestore to trigger MailerSend extension
      final docRef = await _firestore.collection('emails').add(emailData);
      print('✅ MailerSend: Email queued with ID: ${docRef.id}');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Promo email queued successfully',
      );
    } catch (e) {
      print('❌ MailerSend: Error sending promo email: $e');
      return EmailResult(
        success: false,
        messageId: null,
        message: 'Failed to send promo email: $e',
      );
    }
  }

  /// Send proposal email using MailerSend via Firebase extension
  static Future<EmailResult> sendProposalEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
      print('📧 MailerSend: Sending proposal email to: $toEmail');
      print('📧 Proposal type: $proposalType, Value: R$proposalValue');

      // Create the email document for MailerSend extension
      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': subject,
        'html': _generateProposalHtml(
          subject: subject,
          body: body,
          proposalType: proposalType,
          proposalValue: proposalValue,
          clientName: toName,
        ),
        'text': _generateProposalText(
          subject: subject,
          body: body,
          proposalType: proposalType,
          proposalValue: proposalValue,
          clientName: toName,
        ),
        'from': {
          'email':
              'noreply@impactgraphicsza.co.za', // Your verified sender email
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za', // Your support email
          'name': 'Impact Graphics ZA Support',
        },
        'template_id': null, // We're using custom HTML
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'proposal_type', 'value': proposalType},
              {'var': 'proposal_value', 'value': proposalValue},
              {'var': 'message_body', 'value': body},
            ],
          },
        ],
        'tags': ['proposal', 'business'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      // Write to Firestore emails collection to trigger MailerSend extension
      final docRef = await _firestore.collection('emails').add(emailData);

      print('📧 ✅ Email document created with ID: ${docRef.id}');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Proposal email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ Error sending proposal email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending proposal email: $e',
      );
    }
  }

  /// Send welcome email using MailerSend via Firebase extension
  static Future<EmailResult> sendWelcomeEmail({
    required String toEmail,
    required String toName,
  }) async {
    try {
      print('📧 ========================================');
      print('📧 MailerSend: Starting WELCOME EMAIL process...');
      print('📧 To Email: $toEmail');
      print('📧 To Name: $toName');
      print('📧 ========================================');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': 'Welcome to Impact Graphics ZA! 🎨',
        'html': _generateWelcomeHtml(toName),
        'text': _generateWelcomeText(toName),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
            ],
          },
        ],
        'tags': ['welcome', 'onboarding'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print('📧 MailerSend: Adding document to emails collection...');
      final docRef = await _firestore.collection('emails').add(emailData);

      print('📧 ✅ Welcome email document created with ID: ${docRef.id}');
      print('📧 ✅ MailerSend: Welcome email queued successfully');
      print('📧 ========================================');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Welcome email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ MailerSend: Error sending welcome email: $e');
      print('📧 ❌ MailerSend: Error details: ${e.toString()}');
      print('📧 ❌ MailerSend: Stack trace: ${StackTrace.current}');
      return EmailResult(
        success: false,
        message: 'Error sending welcome email: $e',
      );
    }
  }

  /// Send payment confirmation email
  static Future<EmailResult> sendPaymentConfirmation({
    required String toEmail,
    required String toName,
    required String transactionId,
    required double amount,
    required String serviceName,
    String? orderNumber,
    required String paymentMethod,
  }) async {
    try {
      print('📧 MailerSend: Starting payment confirmation email process...');
      print('📧 MailerSend: To Email: $toEmail');
      print('📧 MailerSend: To Name: $toName');
      print('📧 MailerSend: Transaction ID: $transactionId');
      print('📧 MailerSend: Amount: $amount');
      print('📧 MailerSend: Service Name: $serviceName');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': 'Payment Confirmation - Impact Graphics ZA',
        'html': _generatePaymentConfirmationHtml(
          toName,
          transactionId,
          amount,
          serviceName,
          orderNumber,
          paymentMethod,
        ),
        'text': _generatePaymentConfirmationText(
          toName,
          transactionId,
          amount,
          serviceName,
          orderNumber,
          paymentMethod,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'transaction_id', 'value': transactionId},
              {'var': 'amount', 'value': amount.toStringAsFixed(2)},
              {'var': 'service_name', 'value': serviceName},
              {'var': 'order_number', 'value': orderNumber ?? 'N/A'},
              {'var': 'payment_method', 'value': paymentMethod},
            ],
          },
        ],
        'tags': ['payment', 'confirmation'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print('📧 MailerSend: Adding document to emails collection...');
      final docRef = await _firestore.collection('emails').add(emailData);

      print('📧 ✅ Payment confirmation document created with ID: ${docRef.id}');
      print('📧 ✅ MailerSend: Payment confirmation email queued successfully');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Payment confirmation queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ MailerSend: Error sending payment confirmation: $e');
      print('📧 ❌ MailerSend: Error details: ${e.toString()}');
      return EmailResult(
        success: false,
        message: 'Error sending payment confirmation: $e',
      );
    }
  }

  /// Send refund confirmation email
  static Future<EmailResult> sendRefundConfirmation({
    required String toEmail,
    required String toName,
    required String orderNumber,
    required double refundAmount,
    required double originalAmount,
    required double cancellationFee,
    required String serviceName,
    required String reason,
  }) async {
    try {
      print('📧 MailerSend: Starting refund confirmation email process...');
      print('📧 MailerSend: To Email: $toEmail');
      print('📧 MailerSend: To Name: $toName');
      print('📧 MailerSend: Order Number: $orderNumber');
      print('📧 MailerSend: Refund Amount: $refundAmount');
      print('📧 MailerSend: Original Amount: $originalAmount');
      print('📧 MailerSend: Cancellation Fee: $cancellationFee');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': 'Refund Processed - Impact Graphics ZA',
        'html': _generateRefundConfirmationHtml(
          toName,
          orderNumber,
          refundAmount,
          originalAmount,
          cancellationFee,
          serviceName,
          reason,
        ),
        'text': _generateRefundConfirmationText(
          toName,
          orderNumber,
          refundAmount,
          originalAmount,
          cancellationFee,
          serviceName,
          reason,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'order_number', 'value': orderNumber},
              {
                'var': 'refund_amount',
                'value': refundAmount.toStringAsFixed(2),
              },
              {
                'var': 'original_amount',
                'value': originalAmount.toStringAsFixed(2),
              },
              {
                'var': 'cancellation_fee',
                'value': cancellationFee.toStringAsFixed(2),
              },
              {'var': 'service_name', 'value': serviceName},
              {'var': 'reason', 'value': reason},
            ],
          },
        ],
        'tags': ['refund', 'cancellation'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print('📧 MailerSend: Adding refund document to emails collection...');
      final docRef = await _firestore.collection('emails').add(emailData);

      print('📧 ✅ Refund confirmation document created with ID: ${docRef.id}');
      print('📧 ✅ MailerSend: Refund confirmation email queued successfully');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Refund confirmation queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ MailerSend: Error sending refund confirmation: $e');
      print('📧 ❌ MailerSend: Error details: ${e.toString()}');
      return EmailResult(
        success: false,
        message: 'Error sending refund confirmation: $e',
      );
    }
  }

  /// Send portfolio update email
  static Future<EmailResult> sendPortfolioUpdate({
    required String toEmail,
    required String toName,
    required String portfolioTitle,
    required String portfolioDescription,
    required String portfolioCategory,
    String? portfolioImageUrl,
  }) async {
    try {
      print('📧 MailerSend: Starting portfolio update email process...');
      print('📧 MailerSend: To Email: $toEmail');
      print('📧 MailerSend: Portfolio Title: $portfolioTitle');
      print('📧 MailerSend: Category: $portfolioCategory');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': 'New Portfolio Addition - Impact Graphics ZA 🎨',
        'html': _generatePortfolioUpdateHtml(
          toName,
          portfolioTitle,
          portfolioDescription,
          portfolioCategory,
          portfolioImageUrl,
        ),
        'text': _generatePortfolioUpdateText(
          toName,
          portfolioTitle,
          portfolioDescription,
          portfolioCategory,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'portfolio_title', 'value': portfolioTitle},
              {'var': 'portfolio_description', 'value': portfolioDescription},
              {'var': 'portfolio_category', 'value': portfolioCategory},
              {'var': 'portfolio_image_url', 'value': portfolioImageUrl ?? ''},
            ],
          },
        ],
        'tags': ['portfolio', 'marketing', 'showcase'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print('📧 MailerSend: Adding portfolio document to emails collection...');
      final docRef = await _firestore.collection('emails').add(emailData);

      print('📧 ✅ Portfolio update document created with ID: ${docRef.id}');
      print('📧 ✅ MailerSend: Portfolio update email queued successfully');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Portfolio update queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ MailerSend: Error sending portfolio update: $e');
      print('📧 ❌ MailerSend: Error details: ${e.toString()}');
      return EmailResult(
        success: false,
        message: 'Error sending portfolio update: $e',
      );
    }
  }

  /// Send appointment reminder email
  static Future<EmailResult> sendAppointmentReminder({
    required String toEmail,
    required String toName,
    required String appointmentDate,
    required String appointmentTime,
    required String appointmentType,
    String meetingType = 'In-Person', // Default to In-Person
  }) async {
    try {
      print('📧 MailerSend: Sending appointment reminder to: $toEmail');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': 'Appointment Reminder - Impact Graphics ZA',
        'html': _generateAppointmentReminderHtml(
          toName,
          appointmentDate,
          appointmentTime,
          appointmentType,
          meetingType,
        ),
        'text': _generateAppointmentReminderText(
          toName,
          appointmentDate,
          appointmentTime,
          appointmentType,
          meetingType,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'info@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'appointment_date', 'value': appointmentDate},
              {'var': 'appointment_time', 'value': appointmentTime},
              {'var': 'appointment_type', 'value': appointmentType},
            ],
          },
        ],
        'tags': ['appointment', 'reminder'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      final docRef = await _firestore.collection('emails').add(emailData);

      print('📧 ✅ Appointment reminder document created with ID: ${docRef.id}');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Appointment reminder queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ Error sending appointment reminder: $e');
      return EmailResult(
        success: false,
        message: 'Error sending appointment reminder: $e',
      );
    }
  }

  /// Send portfolio update email to all active users
  static Future<EmailResult> sendPortfolioUpdateEmail({
    required String toEmail,
    required String toName,
    required String portfolioLink,
  }) async {
    try {
      print('📧 ========================================');
      print('📧 MailerSend: Starting PORTFOLIO UPDATE EMAIL process...');
      print('📧 To Email: $toEmail');
      print('📧 To Name: $toName');
      print('📧 Portfolio Link: $portfolioLink');
      print('📧 ========================================');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': '🎨 New Portfolio Update - Impact Graphics ZA',
        'html': _generatePortfolioUpdateHtml(
          toName,
          'Latest Portfolio Update',
          'Check out our newest creative work!',
          'Design',
          null,
        ),
        'text': _generatePortfolioUpdateText(
          toName,
          'Latest Portfolio Update',
          'Check out our newest creative work!',
          'Design',
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'admin@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'portfolio_link', 'value': portfolioLink},
            ],
          },
        ],
        'tags': ['portfolio', 'update'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      print('📧 MailerSend: Adding document to emails collection...');
      final docRef = await _firestore.collection('emails').add(emailData);

      print(
        '📧 ✅ Portfolio update email document created with ID: ${docRef.id}',
      );
      print('📧 ✅ MailerSend: Portfolio update email queued successfully');
      print('📧 ========================================');

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Portfolio update email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ MailerSend: Error sending portfolio update email: $e');
      print('📧 ❌ MailerSend: Error details: ${e.toString()}');
      return EmailResult(
        success: false,
        message: 'Error sending portfolio update email: $e',
      );
    }
  }

  /// Send project completion email
  static Future<EmailResult> sendProjectCompletionEmail({
    required String toEmail,
    required String toName,
    required String projectName,
    required String orderNumber,
  }) async {
    try {
      print('📧 MailerSend: Sending project completion email to: $toEmail');
      print('📧 Project: $projectName');
      print('📧 Order Number: $orderNumber');

      final now = DateTime.now();
      final completionDate = '${now.day}/${now.month}/${now.year}';

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': '🎉 Project Completed - $projectName - Impact Graphics ZA',
        'html': _generateProjectCompletionHtml(
          toName,
          projectName,
          orderNumber,
          completionDate,
        ),
        'text': _generateProjectCompletionText(
          toName,
          projectName,
          orderNumber,
          completionDate,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'admin@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'project_name', 'value': projectName},
              {'var': 'order_number', 'value': orderNumber},
              {'var': 'completion_date', 'value': completionDate},
            ],
          },
        ],
        'tags': ['project-completion', 'success'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      final docRef = await _firestore.collection('emails').add(emailData);

      print(
        '📧 ✅ Project completion email document created with ID: ${docRef.id}',
      );

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Project completion email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ Error sending project completion email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending project completion email: $e',
      );
    }
  }

  /// Send Gold Tier activation email
  static Future<EmailResult> sendGoldTierActivationEmail({
    required String toEmail,
    required String toName,
    required String monthlyAmount,
  }) async {
    try {
      print('📧 MailerSend: Sending Gold Tier activation email to: $toEmail');
      print('📧 Client: $toName');
      print('📧 Monthly Amount: R$monthlyAmount');

      final now = DateTime.now();
      final activationDate = '${now.day}/${now.month}/${now.year}';
      final nextBillingDate = DateTime(now.year, now.month + 1, now.day);
      final nextBillingDateStr =
          '${nextBillingDate.day}/${nextBillingDate.month}/${nextBillingDate.year}';

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject':
            '👑 Gold Tier Activated - Welcome to Premium! - Impact Graphics ZA',
        'html': _generateGoldTierActivationHtml(
          toName,
          activationDate,
          nextBillingDateStr,
          monthlyAmount,
        ),
        'text': _generateGoldTierActivationText(
          toName,
          activationDate,
          nextBillingDateStr,
          monthlyAmount,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'admin@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'activation_date', 'value': activationDate},
              {'var': 'next_billing_date', 'value': nextBillingDateStr},
              {'var': 'monthly_amount', 'value': monthlyAmount},
            ],
          },
        ],
        'tags': ['gold-tier', 'activation', 'subscription'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      final docRef = await _firestore.collection('emails').add(emailData);

      print(
        '📧 ✅ Gold Tier activation email document created with ID: ${docRef.id}',
      );

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message: 'Gold Tier activation email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ Error sending Gold Tier activation email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending Gold Tier activation email: $e',
      );
    }
  }

  /// Send Gold Tier cancellation email
  static Future<EmailResult> sendGoldTierCancellationEmail({
    required String toEmail,
    required String toName,
    required String accessUntilDate,
  }) async {
    try {
      print('📧 MailerSend: Sending Gold Tier cancellation email to: $toEmail');
      print('📧 Client: $toName');
      print('📧 Access Until: $accessUntilDate');

      final now = DateTime.now();
      final cancellationDate = '${now.day}/${now.month}/${now.year}';

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': 'Gold Tier Subscription Cancelled - Impact Graphics ZA',
        'html': _generateGoldTierCancellationHtml(
          toName,
          cancellationDate,
          accessUntilDate,
        ),
        'text': _generateGoldTierCancellationText(
          toName,
          cancellationDate,
          accessUntilDate,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'admin@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'cancellation_date', 'value': cancellationDate},
              {'var': 'access_until_date', 'value': accessUntilDate},
            ],
          },
        ],
        'tags': ['gold-tier', 'cancellation', 'subscription'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      final docRef = await _firestore.collection('emails').add(emailData);

      print(
        '📧 ✅ Gold Tier cancellation email document created with ID: ${docRef.id}',
      );

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message:
            'Gold Tier cancellation email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ Error sending Gold Tier cancellation email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending Gold Tier cancellation email: $e',
      );
    }
  }

  /// Send Gold Tier payment reminder email
  static Future<EmailResult> sendGoldTierPaymentReminderEmail({
    required String toEmail,
    required String toName,
    required String monthlyAmount,
    required String billingDate,
    required String paymentMethod,
  }) async {
    try {
      print(
        '📧 MailerSend: Sending Gold Tier payment reminder email to: $toEmail',
      );
      print('📧 Client: $toName');
      print('📧 Billing Date: $billingDate');
      print('📧 Amount: R$monthlyAmount');

      final emailData = {
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject':
            '🔔 Payment Reminder - Gold Tier Subscription - Impact Graphics ZA',
        'html': _generateGoldTierPaymentReminderHtml(
          toName,
          monthlyAmount,
          billingDate,
          paymentMethod,
        ),
        'text': _generateGoldTierPaymentReminderText(
          toName,
          monthlyAmount,
          billingDate,
          paymentMethod,
        ),
        'from': {
          'email': 'noreply@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA',
        },
        'reply_to': {
          'email': 'admin@impactgraphicsza.co.za',
          'name': 'Impact Graphics ZA Support',
        },
        'variables': [
          {
            'email': toEmail,
            'substitutions': [
              {'var': 'client_name', 'value': toName},
              {'var': 'monthly_amount', 'value': monthlyAmount},
              {'var': 'billing_date', 'value': billingDate},
              {'var': 'payment_method', 'value': paymentMethod},
            ],
          },
        ],
        'tags': ['gold-tier', 'payment-reminder', 'subscription'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      final docRef = await _firestore.collection('emails').add(emailData);

      print(
        '📧 ✅ Gold Tier payment reminder email document created with ID: ${docRef.id}',
      );

      return EmailResult(
        success: true,
        messageId: docRef.id,
        message:
            'Gold Tier payment reminder email queued for sending via MailerSend',
      );
    } catch (e) {
      print('📧 ❌ Error sending Gold Tier payment reminder email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending Gold Tier payment reminder email: $e',
      );
    }
  }

  /// Generate HTML for proposal email
  static String _generateProposalHtml({
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
    required String clientName,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$subject - Impact Graphics ZA</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap');
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: 'Poppins', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 30px 0;">
    <tr>
      <td align="center">
        <table width="650" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.15);">
          
          <!-- Header with Logo -->
          <tr>
            <td style="background: linear-gradient(135deg, #8B0000 0%, #6B0000 50%, #4B0000 100%); padding: 50px 40px; text-align: center; position: relative;">
              <!-- Logo -->
              <div style="margin-bottom: 20px;">
                <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                     alt="Impact Graphics ZA Logo" 
                     style="max-width: 180px; height: auto; filter: brightness(0) invert(1);" 
                     onerror="this.style.display='none'">
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; letter-spacing: 1px; text-transform: uppercase;">IMPACT GRAPHICS ZA</h1>
              <div style="width: 60px; height: 3px; background-color: #ffffff; margin: 15px auto;"></div>
              <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px; opacity: 0.95; font-weight: 600;">PROPOSAL</p>
            </td>
          </tr>

          <!-- Message Section -->
          <tr>
            <td style="padding: 40px 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e9ecef; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #28a745 0%, #20c997 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">💬 MESSAGE FROM OUR TEAM</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <div style="color: #333; font-size: 15px; line-height: 1.8;">
                        ${body.replaceAll('\n', '<br>')}
                      </div>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Call to Action -->
          <tr>
            <td style="padding: 20px 40px 30px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #f0f0f0 0%, #ffffff 100%); border-radius: 12px; padding: 30px; text-align: center;">
                <tr>
                  <td>
                    <p style="margin: 0 0 20px 0; color: #333; font-size: 16px; font-weight: 600;">Ready to get started?</p>
                    <a href="mailto:info@impactgraphicsza.co.za" 
                       style="display: inline-block; 
                              background: linear-gradient(135deg, #8B0000 0%, #6B0000 100%); 
                              color: #ffffff; 
                              text-decoration: none; 
                              padding: 18px 60px; 
                              border-radius: 50px; 
                              font-size: 18px; 
                              font-weight: 700; 
                              letter-spacing: 1px;
                              text-transform: uppercase;
                              box-shadow: 0 6px 20px rgba(139,0,0,0.4);
                              transition: all 0.3s ease;">
                      📧 CONTACT US
                    </a>
                    <p style="margin: 20px 0 0 0; color: #999; font-size: 13px; line-height: 1.6;">
                      Click the button above to reply to this proposal<br>
                      or contact us using the information below
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Contact Information -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #fff8e1 0%, #fffbf0 100%); border-radius: 12px; border: 2px solid #ffd54f; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #ff9800 0%, #ff5722 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">📞 GET IN TOUCH</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">📧 Email</span><br>
                            <a href="mailto:info@impactgraphicsza.co.za" style="color: #8B0000; font-size: 15px; font-weight: 600; text-decoration: none;">info@impactgraphicsza.co.za</a>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">📱 WhatsApp</span><br>
                            <a href="https://wa.me/27683675755" style="color: #8B0000; font-size: 18px; font-weight: 700; letter-spacing: 1px; text-decoration: none;">+27 68 367 5755</a>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">🌐 Website</span><br>
                            <a href="https://impact-graphics-za-266ef.web.app" style="color: #8B0000; font-size: 15px; font-weight: 600; text-decoration: none;">impactgraphicsza.co.za</a>
                          </td>
                        </tr>
                      </table>
                      <p style="margin: 15px 0 0 0; color: #e65100; font-size: 13px; line-height: 1.6;">
                        💡 <strong>Tip:</strong> Save our number to reach us quickly via WhatsApp for any questions about this proposal!
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Why Choose Us Section -->
          <tr>
            <td style="padding: 0 40px 40px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8f8f8; border-radius: 12px; padding: 25px; text-align: center;">
                <tr>
                  <td>
                    <p style="margin: 0 0 15px 0; color: #333; font-size: 16px; font-weight: 600;">Why Choose Impact Graphics ZA?</p>
                    <p style="margin: 0; color: #666; font-size: 14px; line-height: 1.6;">
                      ✨ Professional Design Services<br>
                      🎨 Creative & Custom Solutions<br>
                      ⚡ Fast Turnaround Times<br>
                      💯 100% Client Satisfaction Guaranteed
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background: linear-gradient(135deg, #2a2a2a 0%, #1a1a1a 100%); padding: 30px; text-align: center;">
              <div style="margin-bottom: 15px;">
                <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                     alt="Impact Graphics ZA" 
                     style="max-width: 120px; height: auto; opacity: 0.6; filter: brightness(0) invert(1);" 
                     onerror="this.style.display='none'">
              </div>
              <p style="margin: 0 0 10px 0; color: #ffffff; font-size: 16px; font-weight: 600;">IMPACT GRAPHICS ZA</p>
              <p style="margin: 0 0 15px 0; color: #999; font-size: 12px; line-height: 1.6;">
                Professional Graphic Design & Marketing Solutions<br>
                Making Your Brand Stand Out
              </p>
              <div style="margin: 20px 0;">
                <a href="https://impact-graphics-za-266ef.web.app" style="color: #8B0000; text-decoration: none; font-weight: 600; font-size: 13px; margin: 0 10px;">🌐 Visit Website</a>
                <span style="color: #666;">•</span>
                <a href="https://www.facebook.com/impactgraphicsza" style="color: #8B0000; text-decoration: none; font-weight: 600; font-size: 13px; margin: 0 10px;">📱 Facebook</a>
                <span style="color: #666;">•</span>
                <a href="https://www.instagram.com/impactgraphicsza" style="color: #8B0000; text-decoration: none; font-weight: 600; font-size: 13px; margin: 0 10px;">📸 Instagram</a>
              </div>
              <div style="border-top: 1px solid #444; margin: 20px 0; padding-top: 20px;">
                <p style="margin: 0; color: #888; font-size: 11px; line-height: 1.6;">
                  © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.<br>
                  This proposal is valid for 30 days from the date of issue.<br>
                  For support, contact us at info@impactgraphicsza.co.za
                </p>
              </div>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  /// Generate text version for proposal email
  static String _generateProposalText({
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
    required String clientName,
  }) {
    return '''
═══════════════════════════════════════════════════════════════
IMPACT GRAPHICS ZA - PROPOSAL
═══════════════════════════════════════════════════════════════

💬 MESSAGE FROM OUR TEAM
───────────────────────────────────────────────────────────────

$body

───────────────────────────────────────────────────────────────
📞 GET IN TOUCH
───────────────────────────────────────────────────────────────

📧 Email: info@impactgraphicsza.co.za
📱 WhatsApp: +27 68 367 5755
🌐 Website: impactgraphicsza.co.za

💡 Tip: Save our number to reach us quickly via WhatsApp 
   for any questions about this proposal!

───────────────────────────────────────────────────────────────
✨ WHY CHOOSE IMPACT GRAPHICS ZA?
───────────────────────────────────────────────────────────────

• Professional Design Services
• Creative & Custom Solutions
• Fast Turnaround Times
• 100% Client Satisfaction Guaranteed

Ready to get started? Reply to this email or contact us using 
the information above!

═══════════════════════════════════════════════════════════════
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
Professional Graphic Design & Marketing Solutions
Making Your Brand Stand Out

This proposal is valid for 30 days from the date of issue.
For support, contact us at info@impactgraphicsza.co.za
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for welcome email
  static String _generateWelcomeHtml(String clientName) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to Impact Graphics ZA!</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 0; padding: 0; 
      background-color: #f8f9fa; 
      line-height: 1.6;
    }
    .email-wrapper { 
      max-width: 600px; 
      margin: 20px auto; 
      background-color: #ffffff; 
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    }
    
    /* Header with Logo */
    .header { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 50px 20px; 
      text-align: center; 
      position: relative;
    }
    .header::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
      opacity: 0.3;
    }
    .logo-container {
      position: relative;
      z-index: 2;
    }
    .logo { 
      max-width: 120px; 
      height: auto; 
      margin-bottom: 15px;
      filter: brightness(0) invert(1);
    }
    .brand-name { 
      font-size: 32px; 
      font-weight: 700; 
      margin: 0; 
      letter-spacing: 1px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    .brand-tagline { 
      font-size: 14px; 
      margin: 8px 0 0 0; 
      opacity: 0.9; 
      font-weight: 300;
    }
    
    /* Content Area */
    .content { padding: 50px 40px; }
    .welcome-section {
      text-align: center;
      margin-bottom: 30px;
    }
    .welcome-icon { 
      font-size: 64px; 
      color: #28a745; 
      margin-bottom: 20px;
      animation: bounce 2s infinite;
    }
    @keyframes bounce {
      0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
      40% { transform: translateY(-10px); }
      60% { transform: translateY(-5px); }
    }
    .welcome-title {
      font-size: 32px;
      color: #dc2626;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .welcome-subtitle {
      font-size: 16px;
      color: #6c757d;
      margin-bottom: 30px;
    }
    
    /* Greeting */
    .greeting {
      font-size: 18px;
      color: #333;
      margin-bottom: 20px;
      font-weight: 500;
    }
    
    /* Features Section */
    .features-section { 
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0;
      border-left: 5px solid #dc2626;
    }
    .features-title { 
      color: #dc2626; 
      font-size: 20px; 
      font-weight: 600; 
      margin-bottom: 20px;
      text-align: center;
    }
    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 15px;
      margin-top: 20px;
    }
    .feature-item { 
      background: white;
      padding: 20px; 
      border-radius: 8px; 
      text-align: center;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      transition: transform 0.3s ease;
    }
    .feature-item:hover {
      transform: translateY(-5px);
    }
    .feature-icon {
      font-size: 32px;
      margin-bottom: 10px;
      display: block;
    }
    .feature-title {
      font-weight: 600;
      color: #dc2626;
      margin-bottom: 8px;
    }
    .feature-description {
      font-size: 14px;
      color: #6c757d;
    }
    
    /* Getting Started Section */
    .getting-started { 
      background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0;
      border-left: 5px solid #28a745;
    }
    .getting-started h3 { 
      color: #dc2626; 
      font-size: 20px;
      margin-bottom: 20px;
      font-weight: 600;
    }
    .steps-list { 
      margin: 0; 
      padding-left: 0;
      list-style: none;
    }
    .steps-list li { 
      margin: 12px 0; 
      color: #333;
      position: relative;
      padding-left: 30px;
    }
    .steps-list li::before {
      content: '✓';
      position: absolute;
      left: 0;
      color: #28a745;
      font-weight: bold;
      font-size: 16px;
    }
    
    /* CTA Button */
    .cta-section {
      text-align: center;
      margin: 30px 0;
    }
    .cta-button { 
      display: inline-block; 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 15px 35px; 
      text-decoration: none; 
      border-radius: 8px; 
      font-weight: 600;
      font-size: 16px;
      transition: all 0.3s ease;
      box-shadow: 0 4px 15px rgba(30, 60, 114, 0.3);
    }
    .cta-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(30, 60, 114, 0.4);
    }
    
    /* Footer */
    .footer { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 30px 20px; 
      text-align: center; 
    }
    .footer-content {
      max-width: 500px;
      margin: 0 auto;
    }
    .footer-brand {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 10px;
    }
    .footer-tagline {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 20px;
    }
    .footer-links {
      margin: 20px 0;
    }
    .footer-links a { 
      color: #ffffff; 
      text-decoration: none; 
      margin: 0 15px;
      font-size: 14px;
      transition: opacity 0.3s ease;
    }
    .footer-links a:hover {
      opacity: 0.8;
    }
    .footer-divider {
      border: none; 
      border-top: 1px solid rgba(255, 255, 255, 0.2); 
      margin: 20px 0;
    }
    .footer-note {
      font-size: 12px; 
      opacity: 0.8;
      line-height: 1.4;
    }
    
    /* Mobile Responsiveness */
    @media (max-width: 600px) {
      .email-wrapper { margin: 10px; }
      .header { padding: 30px 15px; }
      .content { padding: 30px 20px; }
      .features-section { padding: 20px; }
      .getting-started { padding: 20px; }
      .brand-name { font-size: 24px; }
      .welcome-title { font-size: 28px; }
      .features-grid { grid-template-columns: 1fr; }
      .footer-links a { display: block; margin: 10px 0; }
    }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <!-- Header with Logo -->
    <div class="header">
      <div class="logo-container">
        <!-- Impact Graphics ZA Logo -->
        <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA Logo" class="logo" style="display: block; margin: 0 auto; max-width: 120px; height: auto; border: 0; outline: none;"
             onerror="this.src='https://impactgraphicsza.co.za/logo.png'; this.onerror=function(){this.src='https://impactgraphicsza.co.za/images/logo.png'; this.onerror=function(){this.style.display='none';};};">
        <h1 class="brand-name">IMPACT GRAPHICS ZA</h1>
        <p class="brand-tagline">Creative Solutions • Professional Results</p>
      </div>
    </div>
    
    <!-- Main Content -->
    <div class="content">
      <!-- Welcome Section -->
      <div class="welcome-section">
        <div class="welcome-icon">🎉</div>
        <h2 class="welcome-title">Welcome to the Family!</h2>
        <p class="welcome-subtitle">Your creative journey starts now</p>
      </div>
      
      <!-- Greeting -->
      <p class="greeting">Hello $clientName,</p>
      
      <p style="color: #555; margin-bottom: 30px;">
        Welcome to Impact Graphics ZA! We're absolutely thrilled to have you join our community of creative professionals. You've just taken the first step toward bringing your vision to life with professional design services.
      </p>
      
      <!-- Features Section -->
      <div class="features-section">
        <h3 class="features-title">🎨 What We Offer</h3>
        <div class="features-grid">
          <div class="feature-item">
            <span class="feature-icon">🎨</span>
            <div class="feature-title">Logo Design</div>
            <div class="feature-description">Professional branding that represents your business perfectly</div>
          </div>
          <div class="feature-item">
            <span class="feature-icon">📱</span>
            <div class="feature-title">App & Web Design</div>
            <div class="feature-description">Modern, user-friendly digital experiences</div>
          </div>
          <div class="feature-item">
            <span class="feature-icon">📄</span>
            <div class="feature-title">Marketing Materials</div>
            <div class="feature-description">Flyers, brochures, and promotional content</div>
          </div>
          <div class="feature-item">
            <span class="feature-icon">💼</span>
            <div class="feature-title">Business Stationery</div>
            <div class="feature-description">Business cards, letterheads, and corporate identity</div>
          </div>
        </div>
      </div>
      
      <!-- Getting Started -->
      <div class="getting-started">
        <h3>🚀 Getting Started is Easy</h3>
        <ul class="steps-list">
          <li>Browse our services and find what fits your needs</li>
          <li>Submit a project request with your requirements</li>
          <li>Our team will contact you within 24 hours</li>
          <li>We'll work together to bring your vision to life</li>
          <li>Receive your professional deliverables on time</li>
        </ul>
      </div>
      
      <!-- Call to Action -->
      <div class="cta-section">
        <p style="color: #555; margin-bottom: 20px;">
          Ready to start your first project? Let's create something amazing together!
        </p>
        <a href="mailto:info@impactgraphicsza.co.za" class="cta-button">Start Your Project</a>
      </div>
      
      <p style="color: #555; margin-top: 30px; text-align: center;">
        <strong>Need help or have questions?</strong><br>
        Our friendly support team is here to assist you every step of the way.
      </p>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <div class="footer-content">
        <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA" width="40" height="40" style="border-radius: 8px; margin-bottom: 15px; background: rgba(255,255,255,0.1); padding: 4px;" />
        <div class="footer-brand">Impact Graphics ZA</div>
        <p class="footer-tagline">Professional Graphic Design Services</p>
        
        <div class="footer-links">
          <a href="mailto:info@impactgraphicsza.co.za">📧 Email Support</a>
          <a href="tel:+27683675755">📱 Call Us</a>
          <a href="https://impactgraphicsza.co.za">🌐 Website</a>
        </div>
        
        <hr class="footer-divider">
        
        <p class="footer-note">
          Welcome to the Impact Graphics ZA family! We're excited to work with you.<br>
          © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text version for welcome email
  static String _generateWelcomeText(String clientName) {
    return '''
IMPACT GRAPHICS ZA - Welcome to the Family!

🎉 Welcome to Impact Graphics ZA, $clientName!

Your creative journey starts now! We're absolutely thrilled to have you join our community of creative professionals. You've just taken the first step toward bringing your vision to life with professional design services.

🎨 WHAT WE OFFER:
• Logo Design - Professional branding that represents your business perfectly
• App & Web Design - Modern, user-friendly digital experiences
• Marketing Materials - Flyers, brochures, and promotional content
• Business Stationery - Business cards, letterheads, and corporate identity

🚀 GETTING STARTED IS EASY:
✓ Browse our services and find what fits your needs
✓ Submit a project request with your requirements
✓ Our team will contact you within 24 hours
✓ We'll work together to bring your vision to life
✓ Receive your professional deliverables on time

Ready to start your first project? Let's create something amazing together!

Contact us: info@impactgraphicsza.co.za

Need help or have questions? Our friendly support team is here to assist you every step of the way.

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Creative Solutions • Professional Results
Welcome to the Impact Graphics ZA family! We're excited to work with you.
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for payment confirmation
  static String _generatePaymentConfirmationHtml(
    String clientName,
    String transactionId,
    double amount,
    String serviceName,
    String? orderNumber,
    String paymentMethod,
  ) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Confirmation - Impact Graphics ZA</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 0; padding: 0; 
      background-color: #f8f9fa; 
      line-height: 1.6;
    }
    .email-wrapper { 
      max-width: 600px; 
      margin: 20px auto; 
      background-color: #ffffff; 
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    }
    
    /* Header with Logo */
    .header { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 50px 20px; 
      text-align: center; 
      position: relative;
    }
    .header::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
      opacity: 0.3;
    }
    .logo-container {
      position: relative;
      z-index: 2;
    }
    .logo { 
      max-width: 120px; 
      height: auto; 
      margin-bottom: 15px;
      filter: brightness(0) invert(1);
    }
    .brand-name { 
      font-size: 32px; 
      font-weight: 700; 
      margin: 0; 
      letter-spacing: 1px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    .brand-tagline { 
      font-size: 14px; 
      margin: 8px 0 0 0; 
      opacity: 0.9; 
      font-weight: 300;
    }
    
    /* Content Area */
    .content { padding: 50px 40px; }
    .success-section {
      text-align: center;
      margin-bottom: 30px;
    }
    .success-icon { 
      font-size: 64px; 
      color: #28a745; 
      margin-bottom: 20px;
      animation: bounce 2s infinite;
    }
    @keyframes bounce {
      0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
      40% { transform: translateY(-10px); }
      60% { transform: translateY(-5px); }
    }
    .success-title {
      font-size: 32px;
      color: #dc2626;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .success-subtitle {
      font-size: 16px;
      color: #6c757d;
      margin-bottom: 30px;
    }
    
    /* Greeting */
    .greeting {
      font-size: 18px;
      color: #333;
      margin-bottom: 20px;
      font-weight: 500;
    }
    
    /* Payment Details Card */
    .payment-card { 
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0; 
      border: 1px solid #dee2e6;
      position: relative;
    }
    .payment-card::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 4px;
      background: linear-gradient(90deg, #1e3c72, #2a5298, #28a745);
      border-radius: 12px 12px 0 0;
    }
    .payment-title { 
      color: #dc2626; 
      font-size: 20px; 
      font-weight: 600; 
      margin-bottom: 20px;
      text-align: center;
    }
    .payment-row { 
      display: flex; 
      justify-content: space-between; 
      align-items: center;
      margin: 15px 0; 
      padding: 12px 0; 
      border-bottom: 1px solid #dee2e6; 
    }
    .payment-row:last-child { 
      border-bottom: none; 
      font-weight: 600; 
      color: #dc2626;
      padding-top: 20px;
      margin-top: 20px;
      border-top: 2px solid #dc2626;
    }
    .payment-label { 
      color: #6c757d; 
      font-weight: 500;
      font-size: 14px;
    }
    .payment-value { 
      color: #333; 
      font-weight: 600;
      font-size: 15px;
    }
    .amount { 
      color: #28a745; 
      font-size: 28px; 
      font-weight: 700;
    }
    
    /* Next Steps */
    .next-steps { 
      background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0;
      border-left: 5px solid #dc2626;
    }
    .next-steps h3 { 
      color: #dc2626; 
      font-size: 20px;
      margin-bottom: 20px;
      font-weight: 600;
    }
    .steps-list { 
      margin: 0; 
      padding-left: 0;
      list-style: none;
    }
    .steps-list li { 
      margin: 12px 0; 
      color: #333;
      position: relative;
      padding-left: 30px;
    }
    .steps-list li::before {
      content: '✓';
      position: absolute;
      left: 0;
      color: #28a745;
      font-weight: bold;
      font-size: 16px;
    }
    
    /* CTA Button */
    .cta-section {
      text-align: center;
      margin: 30px 0;
    }
    .cta-button { 
      display: inline-block; 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 15px 35px; 
      text-decoration: none; 
      border-radius: 8px; 
      font-weight: 600;
      font-size: 16px;
      transition: all 0.3s ease;
      box-shadow: 0 4px 15px rgba(30, 60, 114, 0.3);
    }
    .cta-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(30, 60, 114, 0.4);
    }
    
    /* Footer */
    .footer { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 30px 20px; 
      text-align: center; 
    }
    .footer-content {
      max-width: 500px;
      margin: 0 auto;
    }
    .footer-brand {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 10px;
    }
    .footer-tagline {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 20px;
    }
    .footer-links {
      margin: 20px 0;
    }
    .footer-links a { 
      color: #ffffff; 
      text-decoration: none; 
      margin: 0 15px;
      font-size: 14px;
      transition: opacity 0.3s ease;
    }
    .footer-links a:hover {
      opacity: 0.8;
    }
    .footer-divider {
      border: none; 
      border-top: 1px solid rgba(255, 255, 255, 0.2); 
      margin: 20px 0;
    }
    .footer-note {
      font-size: 12px; 
      opacity: 0.8;
      line-height: 1.4;
    }
    
    /* Mobile Responsiveness */
    @media (max-width: 600px) {
      .email-wrapper { margin: 10px; }
      .header { padding: 30px 15px; }
      .content { padding: 30px 20px; }
      .payment-card { padding: 20px; }
      .next-steps { padding: 20px; }
      .brand-name { font-size: 24px; }
      .success-title { font-size: 28px; }
      .payment-row { flex-direction: column; align-items: flex-start; }
      .payment-value { margin-top: 5px; }
      .footer-links a { display: block; margin: 10px 0; }
    }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <!-- Header with Logo -->
    <div class="header">
      <div class="logo-container">
        <!-- Impact Graphics ZA Logo -->
        <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA Logo" class="logo" style="display: block; margin: 0 auto; max-width: 120px; height: auto; border: 0; outline: none;"
             onerror="this.src='https://impactgraphicsza.co.za/logo.png'; this.onerror=function(){this.src='https://impactgraphicsza.co.za/images/logo.png'; this.onerror=function(){this.style.display='none';};};">
        <h1 class="brand-name">IMPACT GRAPHICS ZA</h1>
        <p class="brand-tagline">Creative Solutions • Professional Results</p>
      </div>
    </div>
    
    <!-- Main Content -->
    <div class="content">
      <!-- Success Section -->
      <div class="success-section">
        <div class="success-icon">🎉</div>
        <h2 class="success-title">Payment Confirmed!</h2>
        <p class="success-subtitle">Your transaction has been processed successfully</p>
      </div>
      
      <!-- Greeting -->
      <p class="greeting">Hello $clientName,</p>
      
      <p style="color: #555; margin-bottom: 30px;">
        Thank you for choosing Impact Graphics ZA! We have successfully received your payment and your order is now being processed by our professional team.
      </p>
      
      <!-- Payment Details -->
      <div class="payment-card">
        <h3 class="payment-title">📋 Payment Details</h3>
        
        <div class="payment-row">
          <span class="payment-label">Service Package:</span>
          <span class="payment-value">$serviceName</span>
        </div>
        
        <div class="payment-row">
          <span class="payment-label">Transaction ID:</span>
          <span class="payment-value">$transactionId</span>
        </div>
        
        ${orderNumber != null ? '''
        <div class="payment-row">
          <span class="payment-label">Order Number:</span>
          <span class="payment-value">$orderNumber</span>
        </div>
        ''' : ''}
        
        <div class="payment-row">
          <span class="payment-label">Payment Method:</span>
          <span class="payment-value">$paymentMethod</span>
        </div>
        
        <div class="payment-row">
          <span class="payment-label">Payment Date:</span>
          <span class="payment-value">${DateTime.now().toString().split(' ')[0]}</span>
        </div>
        
        <div class="payment-row">
          <span class="payment-label">Amount Paid:</span>
          <span class="payment-value amount">R${amount.toStringAsFixed(2)}</span>
        </div>
      </div>
      
      <!-- Next Steps -->
      <div class="next-steps">
        <h3>🚀 What happens next?</h3>
        <ul class="steps-list">
          <li>Your order is being reviewed and processed by our design team</li>
          <li>You will receive project updates and milestones via email</li>
          <li>Our team will contact you within 24 hours to discuss your project requirements</li>
          <li>You can track your order status and communicate with us through your dashboard</li>
          <li>Your final deliverables will be delivered according to the agreed timeline</li>
        </ul>
      </div>
      
      <!-- Call to Action -->
      <div class="cta-section">
        <p style="color: #555; margin-bottom: 20px;">
          Need immediate assistance? Our support team is here to help!
        </p>
        <a href="mailto:info@impactgraphicsza.co.za" class="cta-button">Contact Support</a>
      </div>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <div class="footer-content">
        <div class="footer-brand">Impact Graphics ZA</div>
        <p class="footer-tagline">Professional Graphic Design Services</p>
        
        <div class="footer-links">
          <a href="mailto:info@impactgraphicsza.co.za">📧 Email Support</a>
          <a href="tel:+27683675755">📱 Call Us</a>
          <a href="https://impactgraphicsza.co.za">🌐 Website</a>
        </div>
        
        <hr class="footer-divider">
        
        <p class="footer-note">
          This is an automated payment confirmation email. Please keep this email for your records.<br>
          © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text version for payment confirmation
  static String _generatePaymentConfirmationText(
    String clientName,
    String transactionId,
    double amount,
    String serviceName,
    String? orderNumber,
    String paymentMethod,
  ) {
    return '''
IMPACT GRAPHICS ZA - Payment Confirmation

✅ Payment Confirmed!

Hello $clientName,

Thank you for your payment! We have successfully received your payment and your order is now being processed.

PAYMENT DETAILS:
Service: $serviceName
Transaction ID: $transactionId
${orderNumber != null ? 'Order Number: $orderNumber' : ''}
Payment Method: $paymentMethod
Amount Paid: R${amount.toStringAsFixed(2)}
Date: ${DateTime.now().toString().split(' ')[0]}

WHAT HAPPENS NEXT?
• Your order is being processed by our team
• You will receive project updates via email
• Our team will contact you within 24 hours to discuss your project
• You can track your order status in your dashboard

If you have any questions about your payment or order, please don't hesitate to contact us.

Contact: info@impactgraphicsza.co.za | +27683675755

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Creative Solutions • Professional Results
This is a payment confirmation. Please keep this email for your records.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for refund confirmation email
  static String _generateRefundConfirmationHtml(
    String clientName,
    String orderNumber,
    double refundAmount,
    double originalAmount,
    double cancellationFee,
    String serviceName,
    String reason,
  ) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Refund Processed - Impact Graphics ZA</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 0; padding: 0; 
      background-color: #f8f9fa; 
      line-height: 1.6;
    }
    .email-wrapper { 
      max-width: 600px; 
      margin: 20px auto; 
      background-color: #ffffff; 
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    }
    
    /* Header with Logo */
    .header { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 50px 20px; 
      text-align: center; 
      position: relative;
    }
    .header::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
      opacity: 0.3;
    }
    .logo-container {
      position: relative;
      z-index: 2;
    }
    .logo { 
      max-width: 120px; 
      height: auto; 
      margin-bottom: 15px;
      filter: brightness(0) invert(1);
    }
    .brand-name { 
      font-size: 32px; 
      font-weight: 700; 
      margin: 0; 
      letter-spacing: 1px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    .brand-tagline { 
      font-size: 14px; 
      margin: 8px 0 0 0; 
      opacity: 0.9; 
      font-weight: 300;
    }
    
    /* Content Area */
    .content { padding: 50px 40px; }
    .refund-section {
      text-align: center;
      margin-bottom: 30px;
    }
    .refund-icon { 
      font-size: 64px; 
      color: #f59e0b; 
      margin-bottom: 20px;
    }
    .refund-title {
      font-size: 32px;
      color: #dc2626;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .refund-subtitle {
      font-size: 16px;
      color: #6c757d;
      margin-bottom: 30px;
    }
    
    /* Greeting */
    .greeting {
      font-size: 18px;
      color: #333;
      margin-bottom: 20px;
      font-weight: 500;
    }
    
    /* Refund Details Card */
    .refund-card { 
      background: linear-gradient(135deg, #fff5f5 0%, #fee2e2 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0;
      border-left: 5px solid #dc2626;
      box-shadow: 0 2px 10px rgba(220, 38, 38, 0.1);
    }
    .refund-title-card { 
      color: #dc2626; 
      font-size: 20px; 
      font-weight: 600; 
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .refund-row { 
      display: flex; 
      justify-content: space-between; 
      padding: 12px 0; 
      border-bottom: 1px solid rgba(0, 0, 0, 0.1);
    }
    .refund-row:last-child {
      border-bottom: none;
      padding-top: 20px;
      margin-top: 10px;
      border-top: 2px solid #dc2626;
    }
    .refund-label { 
      color: #6c757d; 
      font-weight: 500;
    }
    .refund-value { 
      color: #333; 
      font-weight: 600;
    }
    .refund-value.amount { 
      color: #16a34a; 
      font-size: 20px;
      font-weight: 700;
    }
    .refund-value.fee { 
      color: #dc2626; 
      font-weight: 600;
    }
    
    /* Info Box */
    .info-box { 
      background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
      padding: 25px; 
      border-radius: 12px; 
      margin: 30px 0;
      border-left: 5px solid #3b82f6;
    }
    .info-box h3 { 
      color: #1e40af; 
      font-size: 18px;
      margin-bottom: 15px;
      font-weight: 600;
    }
    .info-list { 
      margin: 0; 
      padding-left: 0;
      list-style: none;
    }
    .info-list li { 
      margin: 10px 0; 
      color: #475569;
      position: relative;
      padding-left: 25px;
      font-size: 14px;
    }
    .info-list li::before {
      content: 'ℹ️';
      position: absolute;
      left: 0;
      font-size: 14px;
    }
    
    /* CTA Button */
    .cta-section {
      text-align: center;
      margin: 30px 0;
    }
    .cta-button { 
      display: inline-block; 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 15px 35px; 
      text-decoration: none; 
      border-radius: 8px; 
      font-weight: 600;
      font-size: 16px;
      transition: all 0.3s ease;
      box-shadow: 0 4px 15px rgba(220, 38, 38, 0.3);
    }
    .cta-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(220, 38, 38, 0.4);
    }
    
    /* Footer */
    .footer { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 30px 20px; 
      text-align: center; 
    }
    .footer-content {
      max-width: 500px;
      margin: 0 auto;
    }
    .footer-brand {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 10px;
    }
    .footer-tagline {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 20px;
    }
    .footer-links {
      margin: 20px 0;
    }
    .footer-links a { 
      color: #ffffff; 
      text-decoration: none; 
      margin: 0 15px;
      font-size: 14px;
      transition: opacity 0.3s ease;
    }
    .footer-links a:hover {
      opacity: 0.8;
    }
    .footer-divider {
      border: none; 
      border-top: 1px solid rgba(255, 255, 255, 0.2); 
      margin: 20px 0;
    }
    .footer-note {
      font-size: 12px; 
      opacity: 0.8;
      line-height: 1.4;
    }
    
    /* Mobile Responsiveness */
    @media (max-width: 600px) {
      .email-wrapper { margin: 10px; }
      .header { padding: 30px 15px; }
      .content { padding: 30px 20px; }
      .refund-card { padding: 20px; }
      .info-box { padding: 20px; }
      .brand-name { font-size: 24px; }
      .refund-title { font-size: 28px; }
      .footer-links a { display: block; margin: 10px 0; }
    }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <!-- Header with Logo -->
    <div class="header">
      <div class="logo-container">
        <!-- Impact Graphics ZA Logo -->
        <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA Logo" class="logo" style="display: block; margin: 0 auto; max-width: 120px; height: auto; border: 0; outline: none;"
             onerror="this.src='https://impactgraphicsza.co.za/logo.png'; this.onerror=function(){this.src='https://impactgraphicsza.co.za/images/logo.png'; this.onerror=function(){this.style.display='none';};};">
        <h1 class="brand-name">IMPACT GRAPHICS ZA</h1>
        <p class="brand-tagline">Creative Solutions • Professional Results</p>
      </div>
    </div>
    
    <!-- Main Content -->
    <div class="content">
      <!-- Refund Section -->
      <div class="refund-section">
        <div class="refund-icon">💰</div>
        <h2 class="refund-title">Refund Processed</h2>
        <p class="refund-subtitle">Your order has been cancelled and refund issued</p>
      </div>
      
      <!-- Greeting -->
      <p class="greeting">Hello $clientName,</p>
      
      <p style="color: #555; margin-bottom: 30px;">
        We've successfully processed the cancellation of your order. Your refund has been credited to your wallet and is available for use immediately.
      </p>
      
      <!-- Refund Details -->
      <div class="refund-card">
        <h3 class="refund-title-card">📋 Refund Details</h3>
        
        <div class="refund-row">
          <span class="refund-label">Order Number:</span>
          <span class="refund-value">$orderNumber</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Service:</span>
          <span class="refund-value">$serviceName</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Cancellation Reason:</span>
          <span class="refund-value">$reason</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Original Amount:</span>
          <span class="refund-value">R${originalAmount.toStringAsFixed(2)}</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Cancellation Fee (25%):</span>
          <span class="refund-value fee">-R${cancellationFee.toStringAsFixed(2)}</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Refund Amount:</span>
          <span class="refund-value amount">R${refundAmount.toStringAsFixed(2)}</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Refund Date:</span>
          <span class="refund-value">${DateTime.now().toString().split(' ')[0]}</span>
        </div>
        
        <div class="refund-row">
          <span class="refund-label">Refund Method:</span>
          <span class="refund-value">Wallet Credit</span>
        </div>
      </div>
      
      <!-- Important Information -->
      <div class="info-box">
        <h3>ℹ️ Important Information</h3>
        <ul class="info-list">
          <li>Your refund of R${refundAmount.toStringAsFixed(2)} has been credited to your wallet</li>
          <li>The funds are available immediately for future orders</li>
          <li>A 25% cancellation fee has been applied as per our policy</li>
          <li>You can view your wallet balance in your dashboard</li>
          <li>This transaction has been recorded in your account history</li>
        </ul>
      </div>
      
      <!-- Call to Action -->
      <div class="cta-section">
        <p style="color: #555; margin-bottom: 20px;">
          Ready to place a new order? We're here to help bring your creative vision to life!
        </p>
        <a href="https://impactgraphicsza.co.za" class="cta-button">Browse Services</a>
      </div>
      
      <p style="color: #555; margin-top: 30px; text-align: center;">
        <strong>Have questions about your refund?</strong><br>
        Our support team is here to assist you with any concerns.
      </p>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <div class="footer-content">
        <div class="footer-brand">Impact Graphics ZA</div>
        <p class="footer-tagline">Professional Graphic Design Services</p>
        
        <div class="footer-links">
          <a href="mailto:info@impactgraphicsza.co.za">📧 Email Support</a>
          <a href="tel:+27683675755">📱 Call Us</a>
          <a href="https://impactgraphicsza.co.za">🌐 Website</a>
        </div>
        
        <hr class="footer-divider">
        
        <p class="footer-note">
          This is an automated refund confirmation email. Please keep this email for your records.<br>
          © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text version for refund confirmation email
  static String _generateRefundConfirmationText(
    String clientName,
    String orderNumber,
    double refundAmount,
    double originalAmount,
    double cancellationFee,
    String serviceName,
    String reason,
  ) {
    return '''
IMPACT GRAPHICS ZA - Refund Processed

💰 Refund Processed

Hello $clientName,

We've successfully processed the cancellation of your order. Your refund has been credited to your wallet and is available for use immediately.

REFUND DETAILS:
Order Number: $orderNumber
Service: $serviceName
Cancellation Reason: $reason
Original Amount: R${originalAmount.toStringAsFixed(2)}
Cancellation Fee (25%): -R${cancellationFee.toStringAsFixed(2)}
Refund Amount: R${refundAmount.toStringAsFixed(2)}
Refund Date: ${DateTime.now().toString().split(' ')[0]}
Refund Method: Wallet Credit

IMPORTANT INFORMATION:
• Your refund of R${refundAmount.toStringAsFixed(2)} has been credited to your wallet
• The funds are available immediately for future orders
• A 25% cancellation fee has been applied as per our policy
• You can view your wallet balance in your dashboard
• This transaction has been recorded in your account history

Ready to place a new order? We're here to help bring your creative vision to life!

Contact: info@impactgraphicsza.co.za | +27683675755

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Creative Solutions • Professional Results
This is a refund confirmation. Please keep this email for your records.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for portfolio update email
  static String _generatePortfolioUpdateHtml(
    String clientName,
    String portfolioTitle,
    String portfolioDescription,
    String portfolioCategory,
    String? portfolioImageUrl,
  ) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New Portfolio Addition - Impact Graphics ZA</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 0; padding: 0; 
      background-color: #f8f9fa; 
      line-height: 1.6;
    }
    .email-wrapper { 
      max-width: 650px; 
      margin: 20px auto; 
      background-color: #ffffff; 
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    }
    
    /* Header with Logo */
    .header { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 50px 20px; 
      text-align: center; 
      position: relative;
    }
    .header::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
      opacity: 0.3;
    }
    .logo-container {
      position: relative;
      z-index: 2;
    }
    .logo { 
      max-width: 120px; 
      height: auto; 
      margin-bottom: 15px;
      filter: brightness(0) invert(1);
    }
    .brand-name { 
      font-size: 32px; 
      font-weight: 700; 
      margin: 0; 
      letter-spacing: 1px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    .brand-tagline { 
      font-size: 14px; 
      margin: 8px 0 0 0; 
      opacity: 0.9; 
      font-weight: 300;
    }
    
    /* Content Area */
    .content { padding: 50px 40px; }
    .portfolio-section {
      text-align: center;
      margin-bottom: 30px;
    }
    .portfolio-icon { 
      font-size: 64px; 
      margin-bottom: 20px;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.1); }
    }
    .portfolio-title {
      font-size: 32px;
      color: #dc2626;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .portfolio-subtitle {
      font-size: 16px;
      color: #6c757d;
      margin-bottom: 30px;
    }
    
    /* Greeting */
    .greeting {
      font-size: 18px;
      color: #333;
      margin-bottom: 20px;
      font-weight: 500;
    }
    
    /* Portfolio Showcase Card */
    .portfolio-card { 
      background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
      padding: 0; 
      border-radius: 12px; 
      margin: 30px 0;
      overflow: hidden;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
      border: 2px solid #dc2626;
    }
    .portfolio-image-container {
      width: 100%;
      height: 300px;
      overflow: hidden;
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
      position: relative;
    }
    .portfolio-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.3s ease;
    }
    .portfolio-image:hover {
      transform: scale(1.05);
    }
    .portfolio-placeholder {
      width: 100%;
      height: 300px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 80px;
      color: rgba(255, 255, 255, 0.3);
    }
    .portfolio-content {
      padding: 30px;
    }
    .portfolio-category {
      display: inline-block;
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
      color: white;
      padding: 8px 20px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 15px;
    }
    .portfolio-project-title {
      font-size: 24px;
      color: #1f2937;
      font-weight: 700;
      margin-bottom: 15px;
      line-height: 1.3;
    }
    .portfolio-description {
      font-size: 15px;
      color: #6c757d;
      line-height: 1.8;
      margin-bottom: 20px;
    }
    
    /* Features Section */
    .features-section { 
      background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0;
      border-left: 5px solid #dc2626;
    }
    .features-title { 
      color: #dc2626; 
      font-size: 22px; 
      font-weight: 700; 
      margin-bottom: 20px;
      text-align: center;
    }
    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-top: 25px;
    }
    .feature-item { 
      background: white;
      padding: 25px; 
      border-radius: 10px; 
      text-align: center;
      box-shadow: 0 3px 15px rgba(220, 38, 38, 0.1);
      transition: all 0.3s ease;
      border: 2px solid transparent;
    }
    .feature-item:hover {
      transform: translateY(-5px);
      border-color: #dc2626;
      box-shadow: 0 6px 25px rgba(220, 38, 38, 0.2);
    }
    .feature-icon {
      font-size: 40px;
      margin-bottom: 15px;
      display: block;
    }
    .feature-title {
      font-weight: 700;
      color: #dc2626;
      margin-bottom: 10px;
      font-size: 16px;
    }
    .feature-description {
      font-size: 13px;
      color: #6c757d;
      line-height: 1.5;
    }
    
    /* CTA Section */
    .cta-section {
      text-align: center;
      margin: 40px 0;
      padding: 35px;
      background: linear-gradient(135deg, #fff1f2 0%, #ffe4e6 100%);
      border-radius: 12px;
      border: 2px dashed #dc2626;
    }
    .cta-heading {
      font-size: 24px;
      color: #dc2626;
      font-weight: 700;
      margin-bottom: 15px;
    }
    .cta-text {
      color: #6c757d;
      margin-bottom: 25px;
      font-size: 15px;
      line-height: 1.6;
    }
    .cta-buttons {
      display: flex;
      gap: 15px;
      justify-content: center;
      flex-wrap: wrap;
    }
    .cta-button { 
      display: inline-block; 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 16px 40px; 
      text-decoration: none; 
      border-radius: 8px; 
      font-weight: 700;
      font-size: 16px;
      transition: all 0.3s ease;
      box-shadow: 0 4px 15px rgba(220, 38, 38, 0.3);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .cta-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(220, 38, 38, 0.5);
    }
    .cta-button-secondary {
      background: white;
      color: #dc2626;
      border: 2px solid #dc2626;
      box-shadow: none;
    }
    .cta-button-secondary:hover {
      background: #dc2626;
      color: white;
    }
    
    /* Testimonial Box */
    .testimonial-box {
      background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
      padding: 30px;
      border-radius: 12px;
      margin: 30px 0;
      border-left: 5px solid #16a34a;
      font-style: italic;
    }
    .testimonial-text {
      font-size: 16px;
      color: #166534;
      line-height: 1.8;
      margin-bottom: 15px;
    }
    .testimonial-author {
      font-weight: 600;
      color: #15803d;
      font-style: normal;
    }
    
    /* Footer */
    .footer { 
      background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); 
      color: white; 
      padding: 40px 20px; 
      text-align: center; 
    }
    .footer-content {
      max-width: 500px;
      margin: 0 auto;
    }
    .footer-brand {
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .footer-tagline {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 25px;
    }
    .footer-links {
      margin: 25px 0;
    }
    .footer-links a { 
      color: #ffffff; 
      text-decoration: none; 
      margin: 0 15px;
      font-size: 14px;
      transition: opacity 0.3s ease;
      font-weight: 500;
    }
    .footer-links a:hover {
      opacity: 0.8;
      text-decoration: underline;
    }
    .footer-divider {
      border: none; 
      border-top: 1px solid rgba(255, 255, 255, 0.2); 
      margin: 25px 0;
    }
    .footer-note {
      font-size: 12px; 
      opacity: 0.8;
      line-height: 1.6;
    }
    .social-links {
      margin: 20px 0;
    }
    .social-links a {
      display: inline-block;
      margin: 0 10px;
      font-size: 24px;
      color: white;
      transition: transform 0.3s ease;
    }
    .social-links a:hover {
      transform: scale(1.2);
    }
    
    /* Mobile Responsiveness */
    @media (max-width: 600px) {
      .email-wrapper { margin: 10px; }
      .header { padding: 30px 15px; }
      .content { padding: 30px 20px; }
      .portfolio-content { padding: 20px; }
      .features-section { padding: 20px; }
      .cta-section { padding: 25px 15px; }
      .brand-name { font-size: 24px; }
      .portfolio-title { font-size: 28px; }
      .features-grid { grid-template-columns: 1fr; }
      .footer-links a { display: block; margin: 10px 0; }
      .cta-buttons { flex-direction: column; }
      .cta-button { width: 100%; }
    }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <!-- Header with Logo -->
    <div class="header">
      <div class="logo-container">
        <!-- Impact Graphics ZA Logo -->
        <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA Logo" class="logo" style="display: block; margin: 0 auto; max-width: 120px; height: auto; border: 0; outline: none;"
             onerror="this.src='https://impactgraphicsza.co.za/logo.png'; this.onerror=function(){this.src='https://impactgraphicsza.co.za/images/logo.png'; this.onerror=function(){this.style.display='none';};};">
        <h1 class="brand-name">IMPACT GRAPHICS ZA</h1>
        <p class="brand-tagline">Creative Solutions • Professional Results</p>
      </div>
    </div>
    
    <!-- Main Content -->
    <div class="content">
      <!-- Portfolio Section -->
      <div class="portfolio-section">
        <div class="portfolio-icon">🎨✨</div>
        <h2 class="portfolio-title">New Portfolio Addition!</h2>
        <p class="portfolio-subtitle">Check out our latest creative work</p>
      </div>
      
      <!-- Greeting -->
      <p class="greeting">Hello $clientName,</p>
      
      <p style="color: #555; margin-bottom: 30px; font-size: 16px; line-height: 1.8;">
        We're excited to share our latest project with you! Our team has just completed an amazing <strong>$portfolioCategory</strong> project, and we couldn't wait to showcase it. This is the kind of professional quality we deliver to all our clients.
      </p>
      
      <!-- Portfolio Showcase -->
      <div class="portfolio-card">
        ${portfolioImageUrl != null ? '''
        <div class="portfolio-image-container">
          <img src="$portfolioImageUrl" alt="$portfolioTitle" class="portfolio-image">
        </div>
        ''' : '''
        <div class="portfolio-placeholder">🎨</div>
        '''}
        <div class="portfolio-content">
          <span class="portfolio-category">$portfolioCategory</span>
          <h3 class="portfolio-project-title">$portfolioTitle</h3>
          <p class="portfolio-description">$portfolioDescription</p>
        </div>
      </div>
      
      <!-- Why Choose Us Section -->
      <div class="features-section">
        <h3 class="features-title">🌟 Why Choose Impact Graphics ZA?</h3>
        <div class="features-grid">
          <div class="feature-item">
            <span class="feature-icon">🎯</span>
            <div class="feature-title">Premium Quality</div>
            <div class="feature-description">Professional designs that exceed expectations</div>
          </div>
          <div class="feature-item">
            <span class="feature-icon">⚡</span>
            <div class="feature-title">Fast Turnaround</div>
            <div class="feature-description">Quick delivery without compromising quality</div>
          </div>
          <div class="feature-item">
            <span class="feature-icon">💎</span>
            <div class="feature-title">Affordable Pricing</div>
            <div class="feature-description">Competitive rates for premium services</div>
          </div>
          <div class="feature-item">
            <span class="feature-icon">🤝</span>
            <div class="feature-title">Client Focused</div>
            <div class="feature-description">Your vision, our expertise, perfect results</div>
          </div>
        </div>
      </div>
      
      <!-- Testimonial -->
      <div class="testimonial-box">
        <p class="testimonial-text">
          "Impact Graphics ZA transformed our brand identity! Their creativity, professionalism, and attention to detail are unmatched. Highly recommended for anyone looking for top-quality design work."
        </p>
        <p class="testimonial-author">— Satisfied Client</p>
      </div>
      
      <!-- Call to Action -->
      <div class="cta-section">
        <h3 class="cta-heading">Ready to Bring Your Vision to Life?</h3>
        <p class="cta-text">
          Join our growing list of satisfied clients! Whether you need a logo, marketing materials, or a complete brand identity, we're here to make your vision a reality.
        </p>
        <div class="cta-buttons">
          <a href="https://impactgraphicsza.co.za" class="cta-button">View Portfolio</a>
          <a href="mailto:info@impactgraphicsza.co.za" class="cta-button cta-button-secondary">Get Started</a>
        </div>
      </div>
      
      <p style="color: #555; margin-top: 30px; text-align: center; font-size: 14px;">
        <strong>🎁 Special Offer for You!</strong><br>
        Book your project this month and enjoy our professional design services at competitive rates.
      </p>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <div class="footer-content">
        <div class="footer-brand">IMPACT GRAPHICS ZA</div>
        <p class="footer-tagline">Where Creativity Meets Excellence</p>
        
        <div class="footer-links">
          <a href="mailto:info@impactgraphicsza.co.za">📧 Email Us</a>
          <a href="tel:+27683675755">📱 +27 68 367 5755</a>
          <a href="https://impactgraphicsza.co.za">🌐 Visit Website</a>
        </div>
        
        <hr class="footer-divider">
        
        <p class="footer-note">
          You're receiving this email because you're a valued member of Impact Graphics ZA.<br>
          Stay updated with our latest projects and creative work!<br><br>
          © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text version for portfolio update email
  static String _generatePortfolioUpdateText(
    String clientName,
    String portfolioTitle,
    String portfolioDescription,
    String portfolioCategory,
  ) {
    return '''
IMPACT GRAPHICS ZA - New Portfolio Addition! 🎨

Hello $clientName,

We're excited to share our latest project with you! Our team has just completed an amazing $portfolioCategory project, and we couldn't wait to showcase it.

═══════════════════════════════════════════════════════════════

PROJECT SHOWCASE:
Category: $portfolioCategory
Title: $portfolioTitle

Description:
$portfolioDescription

═══════════════════════════════════════════════════════════════

🌟 WHY CHOOSE IMPACT GRAPHICS ZA?

🎯 Premium Quality - Professional designs that exceed expectations
⚡ Fast Turnaround - Quick delivery without compromising quality
💎 Affordable Pricing - Competitive rates for premium services
🤝 Client Focused - Your vision, our expertise, perfect results

═══════════════════════════════════════════════════════════════

READY TO BRING YOUR VISION TO LIFE?

Join our growing list of satisfied clients! Whether you need a logo, marketing materials, or a complete brand identity, we're here to make your vision a reality.

🎁 SPECIAL OFFER: Book your project this month and enjoy our professional design services at competitive rates.

═══════════════════════════════════════════════════════════════

CONTACT US:
📧 Email: info@impactgraphicsza.co.za
📱 Phone: +27 68 367 5755
🌐 Website: https://impactgraphicsza.co.za

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Where Creativity Meets Excellence
You're receiving this email because you're a valued member of Impact Graphics ZA.
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for appointment reminder
  static String _generateAppointmentReminderHtml(
    String clientName,
    String appointmentDate,
    String appointmentTime,
    String appointmentType,
    String meetingType,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Appointment Reminder - Impact Graphics ZA</title>
  <style>
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 0; 
      padding: 0; 
      background-color: #f8f9fa; 
      line-height: 1.6;
    }
    .container { 
      max-width: 600px; 
      margin: 0 auto; 
      background-color: #ffffff; 
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .header { 
      background: linear-gradient(135deg, #8B0000 0%, #DC143C 100%); 
      color: white; 
      padding: 40px 20px; 
      text-align: center; 
      position: relative;
    }
    .logo-container {
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 20px;
    }
    .logo {
      width: 80px;
      height: 80px;
      margin-right: 15px;
      border-radius: 8px;
      box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }
    .company-info h1 { 
      margin: 0; 
      font-size: 28px; 
      font-weight: bold; 
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    .company-tagline { 
      margin: 8px 0 0 0; 
      font-size: 16px; 
      opacity: 0.9; 
      font-weight: 300;
    }
    .content { 
      padding: 40px 30px; 
    }
    .greeting {
      font-size: 18px;
      color: #333;
      margin-bottom: 20px;
      font-weight: 500;
    }
    .reminder-title {
      font-size: 24px;
      color: #8B0000;
      text-align: center;
      margin: 30px 0;
      font-weight: bold;
    }
    .reminder-details { 
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      padding: 30px; 
      border-radius: 12px; 
      margin: 30px 0; 
      text-align: center;
      border: 2px solid #8B0000;
      box-shadow: 0 4px 8px rgba(139, 0, 0, 0.1);
    }
    .appointment-type { 
      color: #28a745; 
      font-size: 18px; 
      margin: 0 0 15px 0; 
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .appointment-time { 
      color: #8B0000; 
      font-size: 24px; 
      font-weight: bold; 
      margin: 15px 0; 
      text-shadow: 1px 1px 2px rgba(0,0,0,0.1);
    }
    .appointment-date {
      color: #666;
      font-size: 16px;
      margin: 10px 0;
    }
    .message-content {
      font-size: 16px;
      color: #555;
      margin: 25px 0;
      line-height: 1.8;
    }
    .cta-section {
      background: linear-gradient(135deg, #fff1f2 0%, #ffe4e6 100%);
      padding: 25px;
      border-radius: 10px;
      margin: 30px 0;
      text-align: center;
      border: 2px dashed #8B0000;
    }
    .cta-text {
      color: #8B0000;
      font-weight: 600;
      margin-bottom: 15px;
    }
    .contact-info {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      margin: 25px 0;
      text-align: center;
    }
    .contact-item {
      margin: 8px 0;
      font-size: 14px;
      color: #666;
    }
    .contact-item strong {
      color: #8B0000;
    }
    .footer { 
      background: linear-gradient(135deg, #8B0000 0%, #DC143C 100%); 
      color: white; 
      padding: 30px 20px; 
      text-align: center; 
    }
    .footer-content {
      max-width: 500px;
      margin: 0 auto;
    }
    .footer-brand {
      font-size: 20px;
      font-weight: bold;
      margin-bottom: 10px;
    }
    .footer-tagline {
      font-size: 14px;
      opacity: 0.9;
      margin-bottom: 20px;
    }
    .footer-contact {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 20px;
      margin: 15px 0;
      flex-wrap: wrap;
    }
    .contact-link {
      color: white;
      text-decoration: none;
      font-size: 14px;
      display: flex;
      align-items: center;
      gap: 5px;
    }
    .contact-link:hover {
      text-decoration: underline;
    }
    .divider {
      height: 1px;
      background: linear-gradient(90deg, transparent, #8B0000, transparent);
      margin: 30px 0;
    }
    .social-links {
      margin: 20px 0;
    }
    .social-links a {
      color: white;
      text-decoration: none;
      margin: 0 10px;
      font-size: 14px;
    }
    .copyright {
      font-size: 12px;
      opacity: 0.8;
      margin-top: 20px;
    }
    @media (max-width: 600px) {
      .container { margin: 0; }
      .content { padding: 20px 15px; }
      .header { padding: 30px 15px; }
      .footer-contact { flex-direction: column; gap: 10px; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-container">
        <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA Logo" class="logo" />
        <div class="company-info">
          <h1>IMPACT GRAPHICS ZA</h1>
          <p class="company-tagline">Creative Solutions • Professional Results</p>
        </div>
      </div>
    </div>
    
    <div class="content">
      <div class="greeting">Hello $clientName,</div>
      
      <div class="reminder-title">📅 Appointment Reminder</div>
      
      <div class="message-content">
        This is a friendly reminder about your upcoming appointment with Impact Graphics ZA. We're excited to meet with you and discuss your project needs.
      </div>
      
      <div class="reminder-details">
        <div class="appointment-type">$appointmentType</div>
        <div class="appointment-time">$appointmentDate</div>
        <div class="appointment-date">at $appointmentTime</div>
        <div class="meeting-type" style="margin-top: 15px; padding: 8px 16px; background: rgba(139, 0, 0, 0.1); border-radius: 20px; display: inline-block; font-size: 14px; color: #8B0000; font-weight: 600;">
          ${meetingType == 'Call' ? '📞 Video/Call Meeting' : '🏢 In-Person Meeting'}
        </div>
      </div>
      
      <div class="cta-section">
        <div class="cta-text">⏰ Please ensure you're available at the scheduled time</div>
        <p style="margin: 10px 0; color: #666; font-size: 14px;">
          ${meetingType == 'Call' ? 'We will send you the meeting link shortly before the appointment time. Please ensure you have a stable internet connection and a quiet environment for our call.' : 'Please arrive on time for our in-person meeting. If you need directions to our office, please don\'t hesitate to contact us.'}
        </p>
        <p style="margin: 10px 0; color: #666; font-size: 14px;">
          If you need to reschedule, please contact us as soon as possible so we can find a suitable alternative time.
        </p>
      </div>
      
      <div class="message-content">
        We look forward to meeting with you and helping you achieve your creative goals!
      </div>
      
      <div class="divider"></div>
      
      <div class="contact-info">
        <h3 style="color: #8B0000; margin: 0 0 15px 0; text-align: center;">Need to Contact Us?</h3>
        <div class="contact-item">
          <strong>📧 Email:</strong> info@impactgraphicsza.co.za
        </div>
        <div class="contact-item">
          <strong>📱 Phone:</strong> +27 68 367 5755
        </div>
        <div class="contact-item">
          <strong>🌐 Website:</strong> www.impactgraphicsza.co.za
        </div>
      </div>
      
      <p style="text-align: center; margin: 30px 0; font-size: 16px; color: #555;">
        Best regards,<br>
        <strong style="color: #8B0000;">The Impact Graphics ZA Team</strong>
      </p>
    </div>
    
    <div class="footer">
      <div class="footer-content">
        <div class="footer-brand">Impact Graphics ZA</div>
        <div class="footer-tagline">Creative Solutions • Professional Results</div>
        
        <div class="footer-contact">
          <a href="mailto:info@impactgraphicsza.co.za" class="contact-link">
            📧 info@impactgraphicsza.co.za
          </a>
          <a href="tel:+27683675755" class="contact-link">
            📱 +27 68 367 5755
          </a>
        </div>
        
        <div class="social-links">
          <a href="https://www.impactgraphicsza.co.za">Website</a>
          <a href="mailto:info@impactgraphicsza.co.za">Contact</a>
        </div>
        
        <div class="copyright">
          © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
        </div>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text version for appointment reminder
  static String _generateAppointmentReminderText(
    String clientName,
    String appointmentDate,
    String appointmentTime,
    String appointmentType,
    String meetingType,
  ) {
    return '''
═══════════════════════════════════════════════════════════════
                    IMPACT GRAPHICS ZA
              Creative Solutions • Professional Results
═══════════════════════════════════════════════════════════════

📅 APPOINTMENT REMINDER

Hello $clientName,

This is a friendly reminder about your upcoming appointment with Impact Graphics ZA. We're excited to meet with you and discuss your project needs.

┌─────────────────────────────────────────────────────────────┐
│                    APPOINTMENT DETAILS                     │
├─────────────────────────────────────────────────────────────┤
│ Type: $appointmentType                                      │
│ Date: $appointmentDate                                      │
│ Time: $appointmentTime                                      │
│ Meeting: ${meetingType == 'Call' ? '📞 Video/Call Meeting' : '🏢 In-Person Meeting'} │
└─────────────────────────────────────────────────────────────┘

⏰ IMPORTANT REMINDER:
Please ensure you're available at the scheduled time.

${meetingType == 'Call' ? '📞 CALL MEETING: We will send you the meeting link shortly before the appointment time. Please ensure you have a stable internet connection and a quiet environment for our call.' : '🏢 IN-PERSON MEETING: Please arrive on time for our in-person meeting. If you need directions to our office, please don\'t hesitate to contact us.'}

If you need to reschedule, please contact us as soon as possible so we can find a suitable alternative time.

We look forward to meeting with you and helping you achieve your creative goals!

Best regards,
The Impact Graphics ZA Team

📞 CONTACT INFORMATION:
📧 Email: info@impactgraphicsza.co.za
📱 Phone: +27 68 367 5755
🌐 Website: www.impactgraphicsza.co.za

═══════════════════════════════════════════════════════════════
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  static String _generateProjectCompletionHtml(
    String clientName,
    String projectName,
    String orderNumber,
    String completionDate,
  ) {
    return '''
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Project Completed - Impact Graphics ZA</title>
  <style>
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      background-color: #f4f4f4; 
      margin: 0; 
      padding: 0; 
      line-height: 1.6;
    }
    .email-container { 
      max-width: 650px; 
      margin: 20px auto; 
      background-color: #ffffff; 
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.1);
      overflow: hidden;
    }
    .header { 
      background: linear-gradient(135deg, #28a745 0%, #20c997 100%); 
      color: white; 
      padding: 40px 30px; 
      text-align: center;
      position: relative;
    }
    .success-icon {
      width: 100px;
      height: 100px;
      background: white;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 50px;
      margin-bottom: 20px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }
    .company-name {
      font-size: 28px;
      font-weight: bold;
      margin: 15px 0 5px 0;
      text-shadow: 0 2px 4px rgba(0,0,0,0.3);
      letter-spacing: 1px;
    }
    .header-subtitle {
      font-size: 16px;
      margin: 0;
      opacity: 0.95;
      font-weight: 300;
    }
    .content { 
      padding: 40px 30px; 
      color: #333333;
      background: #ffffff;
    }
    .greeting {
      font-size: 20px;
      margin-bottom: 20px;
      color: #28a745;
      font-weight: 600;
    }
    .completion-card {
      background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
      padding: 35px;
      border-radius: 12px;
      margin: 25px 0;
      border-left: 5px solid #28a745;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
      text-align: center;
    }
    .completion-title {
      color: #28a745;
      font-size: 28px;
      font-weight: bold;
      margin: 0 0 15px 0;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .completion-subtitle {
      color: #2e7d32;
      font-size: 18px;
      margin: 0 0 20px 0;
      font-weight: 500;
    }
    .project-details {
      background: white;
      padding: 25px;
      border-radius: 8px;
      margin: 20px 0;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .detail-row {
      display: flex;
      justify-content: space-between;
      padding: 12px 0;
      border-bottom: 1px solid #e9ecef;
    }
    .detail-row:last-child {
      border-bottom: none;
    }
    .detail-label {
      font-weight: 600;
      color: #666;
      font-size: 14px;
    }
    .detail-value {
      color: #28a745;
      font-weight: 700;
      font-size: 14px;
    }
    .thank-you-message {
      text-align: center;
      margin: 30px 0;
      padding: 25px;
      background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%);
      border-radius: 12px;
      border-left: 5px solid #ff9800;
    }
    .thank-you-title {
      color: #f57c00;
      font-size: 22px;
      font-weight: bold;
      margin: 0 0 10px 0;
    }
    .thank-you-text {
      color: #e65100;
      font-size: 16px;
      margin: 0;
      line-height: 1.6;
    }
    .features-grid {
      display: flex;
      justify-content: space-around;
      flex-wrap: wrap;
      gap: 20px;
      margin: 30px 0;
    }
    .feature-item {
      flex: 1;
      min-width: 140px;
      text-align: center;
      padding: 20px;
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }
    .feature-icon {
      font-size: 32px;
      margin-bottom: 10px;
    }
    .feature-name {
      font-weight: bold;
      color: #28a745;
      font-size: 13px;
    }
    .cta-section {
      text-align: center;
      margin: 35px 0;
    }
    .cta-button {
      display: inline-block;
      background: linear-gradient(135deg, #8B0000 0%, #A52A2A 100%);
      color: white;
      padding: 15px 35px;
      text-decoration: none;
      border-radius: 25px;
      font-weight: bold;
      font-size: 16px;
      box-shadow: 0 4px 12px rgba(139, 0, 0, 0.3);
      transition: all 0.3s ease;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin: 0 10px;
    }
    .divider {
      height: 2px;
      background: linear-gradient(90deg, transparent, #28a745, transparent);
      margin: 30px 0;
    }
    .footer { 
      background: #2c2c2c;
      color: #ffffff;
      text-align: center; 
      padding: 30px;
      font-size: 14px;
    }
    .footer-content {
      max-width: 500px;
      margin: 0 auto;
    }
    .footer-logo {
      font-size: 24px;
      font-weight: bold;
      color: #28a745;
      margin-bottom: 15px;
    }
    .contact-info {
      margin: 20px 0;
      line-height: 1.8;
    }
    .contact-item {
      margin: 8px 0;
    }
    .social-links {
      margin-top: 25px;
    }
    .social-link {
      display: inline-block;
      margin: 0 15px;
      color: #28a745;
      text-decoration: none;
      font-weight: bold;
      font-size: 16px;
    }
    .testimonial {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      margin: 25px 0;
      border-left: 4px solid #28a745;
      font-style: italic;
      color: #495057;
    }
    @media (max-width: 600px) {
      .email-container { margin: 10px; border-radius: 8px; }
      .header, .content, .footer { padding: 20px; }
      .features-grid, .detail-row { flex-direction: column; }
      .company-name { font-size: 24px; }
      .success-icon { width: 80px; height: 80px; font-size: 40px; }
      .completion-card { padding: 20px; }
      .cta-button { display: block; margin: 10px 0; }
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="header">
      <div class="success-icon">✓</div>
      <h1 class="company-name">IMPACT GRAPHICS ZA</h1>
      <p class="header-subtitle">Professional Design & Marketing Solutions</p>
    </div>
    
    <div class="content">
      <div class="greeting">Hello $clientName! 🎉</div>
      
      <div class="completion-card">
        <h2 class="completion-title">Project Completed!</h2>
        <p class="completion-subtitle">Your project has been successfully delivered</p>
      </div>
      
      <p style="font-size: 16px; color: #495057; line-height: 1.8;">
        We're excited to inform you that your project <strong style="color: #28a745;">$projectName</strong> has been successfully completed and is now ready for you!
      </p>

      <div class="project-details">
        <div class="detail-row">
          <span class="detail-label">Project Name</span>
          <span class="detail-value">$projectName</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Order Number</span>
          <span class="detail-value">$orderNumber</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Completion Date</span>
          <span class="detail-value">$completionDate</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Status</span>
          <span class="detail-value">✓ COMPLETED</span>
        </div>
      </div>

      <div class="thank-you-message">
        <h3 class="thank-you-title">Thank You for Trusting Us! 🙏</h3>
        <p class="thank-you-text">
          We truly appreciate your trust in Impact Graphics ZA. It was a pleasure working on your project, 
          and we hope the final result exceeds your expectations. Your satisfaction is our top priority!
        </p>
      </div>

      <div class="testimonial">
        "We strive to deliver exceptional quality in every project. Your success is our success, 
        and we're honored to have been part of your journey."
        <br><br>
        <strong>- The Impact Graphics ZA Team</strong>
      </div>

      <div class="features-grid">
        <div class="feature-item">
          <div class="feature-icon">🎨</div>
          <div class="feature-name">Quality Work</div>
        </div>
        <div class="feature-item">
          <div class="feature-icon">⚡</div>
          <div class="feature-name">Fast Delivery</div>
        </div>
        <div class="feature-item">
          <div class="feature-icon">💯</div>
          <div class="feature-name">100% Satisfaction</div>
        </div>
        <div class="feature-item">
          <div class="feature-icon">🤝</div>
          <div class="feature-name">Trusted Partner</div>
        </div>
      </div>

      <p style="font-size: 15px; color: #495057; line-height: 1.8; text-align: center; margin: 25px 0;">
        If you have any questions or need any revisions, please don't hesitate to reach out. 
        We're here to ensure you're completely satisfied with the final product.
      </p>
      
      <div class="cta-section">
        <a href="mailto:admin@impactgraphicsza.co.za" class="cta-button">
          Contact Us
        </a>
      </div>
      
      <div class="divider"></div>

      <p style="font-size: 14px; color: #6c757d; text-align: center; margin-top: 30px;">
        We look forward to working with you again on future projects. 
        Feel free to explore our other services or refer us to friends and colleagues!
      </p>
    </div>
    
    <div class="footer">
      <div class="footer-content">
        <div class="footer-logo">IMPACT GRAPHICS ZA</div>
        <div class="contact-info">
          <div class="contact-item"><strong>Email:</strong> admin@impactgraphicsza.co.za</div>
          <div class="contact-item"><strong>Website:</strong> www.impactgraphicsza.co.za</div>
          <div class="contact-item"><strong>Phone:</strong> +27 68 367 5755</div>
        </div>
        <div class="social-links">
          <a href="#" class="social-link">LinkedIn</a>
          <a href="#" class="social-link">Instagram</a>
          <a href="#" class="social-link">Facebook</a>
        </div>
        <div style="margin-top: 20px; font-size: 12px; opacity: 0.7;">
          <p>This email was sent from Impact Graphics ZA regarding your completed project.</p>
        </div>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text version for project completion email
  static String _generateProjectCompletionText(
    String clientName,
    String projectName,
    String orderNumber,
    String completionDate,
  ) {
    return '''
═══════════════════════════════════════════════════════════════
IMPACT GRAPHICS ZA - PROJECT COMPLETED! 🎉
Professional Design & Marketing Solutions
═══════════════════════════════════════════════════════════════

Hello $clientName!

PROJECT SUCCESSFULLY COMPLETED ✓

We're excited to inform you that your project "$projectName" has been successfully completed and is now ready for you!

═══════════════════════════════════════════════════════════════

PROJECT DETAILS:

Project Name: $projectName
Order Number: $orderNumber
Completion Date: $completionDate
Status: ✓ COMPLETED

═══════════════════════════════════════════════════════════════

THANK YOU FOR TRUSTING US! 🙏

We truly appreciate your trust in Impact Graphics ZA. It was a pleasure working on your project, and we hope the final result exceeds your expectations. Your satisfaction is our top priority!

"We strive to deliver exceptional quality in every project. Your success is our success, and we're honored to have been part of your journey."
- The Impact Graphics ZA Team

═══════════════════════════════════════════════════════════════

WHAT MAKES US DIFFERENT:

🎨 Quality Work - Professional results every time
⚡ Fast Delivery - On-time project completion
💯 100% Satisfaction - Your happiness guaranteed
🤝 Trusted Partner - Building lasting relationships

═══════════════════════════════════════════════════════════════

NEED SUPPORT?

If you have any questions or need any revisions, please don't hesitate to reach out. We're here to ensure you're completely satisfied with the final product.

Contact us at: admin@impactgraphicsza.co.za

═══════════════════════════════════════════════════════════════

We look forward to working with you again on future projects. Feel free to explore our other services or refer us to friends and colleagues!

═══════════════════════════════════════════════════════════════

CONTACT INFORMATION:
📧 Email: admin@impactgraphicsza.co.za
🌐 Website: www.impactgraphicsza.co.za
📱 Phone: +27 68 367 5755

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Where Creativity Meets Excellence
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for Gold Tier activation email
  static String _generateGoldTierActivationHtml(
    String clientName,
    String activationDate,
    String nextBillingDate,
    String monthlyAmount,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body{font-family:'Segoe UI',sans-serif;background:#f4f4f4;margin:0;padding:20px;line-height:1.6}
    .container{max-width:650px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.1)}
    .header{background:linear-gradient(135deg,#FFD700,#FFA500);color:#2c2c2c;padding:40px;text-align:center}
    .icon{width:100px;height:100px;background:#fff;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:50px;margin-bottom:15px}
    .content{padding:40px 30px;color:#333}
    .highlight{background:linear-gradient(135deg,#FFF8DC,#FFE4B5);padding:30px;border-radius:12px;margin:20px 0;border-left:5px solid #FFD700;text-align:center}
    .benefit{background:#f8f9fa;padding:15px;margin:10px 0;border-radius:8px}
    h1{font-size:24px;margin:10px 0}
    h2{color:#FF8C00;font-size:28px;margin:0}
    .footer{background:#2c2c2c;color:#fff;padding:30px;text-align:center;font-size:14px}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="icon">👑</div>
      <h1>IMPACT GRAPHICS ZA</h1>
      <p>Professional Design & Marketing Solutions</p>
    </div>
    <div class="content">
      <p style="font-size:20px;color:#FFA500;font-weight:600">Hello $clientName! 🎉</p>
      <div class="highlight">
        <h2>Gold Tier Activated!</h2>
        <p style="color:#CD853F;font-size:18px">Welcome to Premium Membership</p>
      </div>
      <p>Congratulations! Your <strong style="color:#FFD700">Gold Tier</strong> subscription has been successfully activated.</p>
      <div style="background:#fff;padding:20px;border-radius:8px;margin:20px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1)">
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Plan:</strong> <span style="color:#FFA500;float:right">Gold Tier</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Activated:</strong> <span style="color:#FFA500;float:right">$activationDate</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Next Billing:</strong> <span style="color:#FFA500;float:right">$nextBillingDate</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Monthly:</strong> <span style="color:#FFA500;float:right">R$monthlyAmount</span></div>
        <div style="padding:10px 0"><strong>Status:</strong> <span style="color:#28a745;float:right">✓ ACTIVE</span></div>
      </div>
      <h3 style="color:#FF8C00;text-align:center">Your Gold Tier Benefits</h3>
      <div class="benefit">🎨 <strong>Priority Service</strong> - Faster turnaround times</div>
      <div class="benefit">💎 <strong>Premium Support</strong> - Dedicated account management</div>
      <div class="benefit">🎁 <strong>Exclusive Discounts</strong> - Member-only pricing</div>
      <div class="benefit">⚡ <strong>Unlimited Revisions</strong> - Until you're 100% satisfied</div>
      <div class="benefit">📱 <strong>Monthly Credits</strong> - Design credits every month</div>
      <p style="text-align:center;margin:30px 0"><strong>Thank you for choosing our premium membership!</strong></p>
    </div>
    <div class="footer">
      <p style="font-size:24px;color:#FFD700;margin:0 0 15px 0"><strong>IMPACT GRAPHICS ZA</strong></p>
      <p><strong>Email:</strong> admin@impactgraphicsza.co.za</p>
      <p><strong>Phone:</strong> +27 68 367 5755</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text for Gold Tier activation email
  static String _generateGoldTierActivationText(
    String clientName,
    String activationDate,
    String nextBillingDate,
    String monthlyAmount,
  ) {
    return '''
═══════════════════════════════════════════════════════════════
IMPACT GRAPHICS ZA - GOLD TIER ACTIVATED! 👑
Professional Design & Marketing Solutions
═══════════════════════════════════════════════════════════════

Hello $clientName! 🎉

GOLD TIER SUCCESSFULLY ACTIVATED!

Congratulations! Your Gold Tier subscription has been successfully activated. You now have access to exclusive premium benefits and priority service.

═══════════════════════════════════════════════════════════════

SUBSCRIPTION DETAILS:

Subscription Plan: Gold Tier
Activation Date: $activationDate
Next Billing Date: $nextBillingDate
Monthly Amount: R$monthlyAmount
Status: ✓ ACTIVE

═══════════════════════════════════════════════════════════════

YOUR GOLD TIER BENEFITS:

🎨 Priority Service - Your projects get moved to the front of the queue with faster turnaround times
💎 Premium Support - Direct access to senior designers and dedicated account management
🎁 Exclusive Discounts - Save on all services with member-only pricing and special offers
⚡ Unlimited Revisions - Make changes until you're 100% satisfied with your projects
📱 Monthly Design Credits - Get credits every month to use on any service you need

═══════════════════════════════════════════════════════════════

WELCOME TO THE GOLD TIER FAMILY! 🌟

Thank you for choosing our premium membership. We're committed to providing you with exceptional service and results that exceed your expectations every time.

Your subscription will automatically renew on $nextBillingDate for R$monthlyAmount. You can manage your subscription anytime in the app.

═══════════════════════════════════════════════════════════════

CONTACT INFORMATION:
📧 Email: admin@impactgraphicsza.co.za
🌐 Website: www.impactgraphicsza.co.za
📱 Phone: +27 68 367 5755

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Where Creativity Meets Excellence
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for Gold Tier cancellation email
  static String _generateGoldTierCancellationHtml(
    String clientName,
    String cancellationDate,
    String accessUntilDate,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body{font-family:'Segoe UI',sans-serif;background:#f4f4f4;margin:0;padding:20px;line-height:1.6}
    .container{max-width:650px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.1)}
    .header{background:linear-gradient(135deg,#6c757d,#495057);color:#fff;padding:40px;text-align:center}
    .icon{width:100px;height:100px;background:#fff;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:50px;margin-bottom:15px}
    .content{padding:40px 30px;color:#333}
    .highlight{background:linear-gradient(135deg,#f8f9fa,#e9ecef);padding:30px;border-radius:12px;margin:20px 0;border-left:5px solid #6c757d;text-align:center}
    h1{font-size:24px;margin:10px 0}
    h2{color:#495057;font-size:28px;margin:0}
    .notice{background:#fff3e0;padding:20px;border-radius:8px;margin:20px 0;border-left:5px solid #ff9800}
    .footer{background:#2c2c2c;color:#fff;padding:30px;text-align:center;font-size:14px}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="icon">😢</div>
      <h1>IMPACT GRAPHICS ZA</h1>
      <p>Professional Design & Marketing Solutions</p>
    </div>
    <div class="content">
      <p style="font-size:20px;color:#6c757d;font-weight:600">Hello $clientName,</p>
      <div class="highlight">
        <h2>Gold Tier Cancelled</h2>
        <p style="color:#6c757d;font-size:18px">We're sorry to see you go</p>
      </div>
      <p>Your Gold Tier subscription has been successfully cancelled as requested. We're sad to see you go, but we understand that circumstances change.</p>
      <div style="background:#fff;padding:20px;border-radius:8px;margin:20px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1)">
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Plan:</strong> <span style="color:#6c757d;float:right">Gold Tier (Cancelled)</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Cancelled:</strong> <span style="color:#6c757d;float:right">$cancellationDate</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Access Until:</strong> <span style="color:#6c757d;float:right">$accessUntilDate</span></div>
        <div style="padding:10px 0"><strong>Status:</strong> <span style="color:#dc3545;float:right">✗ CANCELLED</span></div>
      </div>
      <div class="notice">
        <strong>Note:</strong> You'll continue to have access to your Gold Tier benefits until <strong>$accessUntilDate</strong>. After this date, your account will revert to the standard free tier.
      </div>
      <div style="background:linear-gradient(135deg,#e8f5e9,#c8e6c9);padding:25px;border-radius:12px;margin:30px 0;text-align:center;border-left:5px solid #28a745">
        <h3 style="color:#28a745;margin:0 0 10px 0">Changed Your Mind?</h3>
        <p style="color:#2e7d32;margin:0 0 20px 0">You can reactivate your Gold Tier subscription anytime! All your previous benefits will be restored immediately upon reactivation.</p>
      </div>
      <p style="text-align:center;margin:30px 0">Thank you for being a Gold Tier member. We hope to see you again soon!</p>
    </div>
    <div class="footer">
      <p style="font-size:24px;color:#6c757d;margin:0 0 15px 0"><strong>IMPACT GRAPHICS ZA</strong></p>
      <p><strong>Email:</strong> admin@impactgraphicsza.co.za</p>
      <p><strong>Phone:</strong> +27 68 367 5755</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text for Gold Tier cancellation email
  static String _generateGoldTierCancellationText(
    String clientName,
    String cancellationDate,
    String accessUntilDate,
  ) {
    return '''
═══════════════════════════════════════════════════════════════
IMPACT GRAPHICS ZA - GOLD TIER CANCELLED
Professional Design & Marketing Solutions
═══════════════════════════════════════════════════════════════

Hello $clientName,

GOLD TIER SUBSCRIPTION CANCELLED

Your Gold Tier subscription has been successfully cancelled as requested. We're sad to see you go, but we understand that circumstances change.

═══════════════════════════════════════════════════════════════

CANCELLATION DETAILS:

Subscription Plan: Gold Tier (Cancelled)
Cancellation Date: $cancellationDate
Access Until: $accessUntilDate
Status: ✗ CANCELLED

═══════════════════════════════════════════════════════════════

IMPORTANT NOTE:

You'll continue to have access to your Gold Tier benefits until $accessUntilDate. After this date, your account will revert to the standard free tier.

═══════════════════════════════════════════════════════════════

CHANGED YOUR MIND?

You can reactivate your Gold Tier subscription anytime! All your previous benefits will be restored immediately upon reactivation.

═══════════════════════════════════════════════════════════════

Thank you for being a Gold Tier member. We hope to see you again soon, and you're always welcome to use our standard services anytime.

If you cancelled by mistake or have any questions, please contact us immediately.

═══════════════════════════════════════════════════════════════

CONTACT INFORMATION:
📧 Email: admin@impactgraphicsza.co.za
🌐 Website: www.impactgraphicsza.co.za
📱 Phone: +27 68 367 5755

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Where Creativity Meets Excellence
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for Gold Tier payment reminder email
  static String _generateGoldTierPaymentReminderHtml(
    String clientName,
    String monthlyAmount,
    String billingDate,
    String paymentMethod,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body{font-family:'Segoe UI',sans-serif;background:#f4f4f4;margin:0;padding:20px;line-height:1.6}
    .container{max-width:650px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.1)}
    .header{background:linear-gradient(135deg,#007bff,#0056b3);color:#fff;padding:40px;text-align:center}
    .icon{width:100px;height:100px;background:#fff;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:50px;margin-bottom:15px}
    .content{padding:40px 30px;color:#333}
    .highlight{background:linear-gradient(135deg,#e3f2fd,#bbdefb);padding:30px;border-radius:12px;margin:20px 0;border-left:5px solid #007bff;text-align:center}
    .amount{background:linear-gradient(135deg,#fff3e0,#ffe0b2);padding:30px;border-radius:12px;margin:20px 0;text-align:center;border-left:5px solid #ff9800}
    .benefit{background:#f8f9fa;padding:10px 10px 10px 35px;margin:10px 0;border-radius:8px;position:relative}
    .benefit:before{content:"✓";position:absolute;left:10px;color:#FFD700;font-weight:bold;font-size:18px}
    h1{font-size:24px;margin:10px 0}
    h2{color:#0056b3;font-size:28px;margin:0}
    .urgent{background:#ffebee;padding:20px;border-radius:8px;margin:20px 0;border-left:5px solid #f44336;text-align:center}
    .footer{background:#2c2c2c;color:#fff;padding:30px;text-align:center;font-size:14px}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="icon">🔔</div>
      <h1>IMPACT GRAPHICS ZA</h1>
      <p>Professional Design & Marketing Solutions</p>
    </div>
    <div class="content">
      <p style="font-size:20px;color:#007bff;font-weight:600">Hello $clientName! 👋</p>
      <div class="highlight">
        <h2>Payment Reminder</h2>
        <p style="color:#1976d2;font-size:18px">Your Gold Tier subscription renewal is coming up</p>
      </div>
      <p>This is a friendly reminder that your <strong style="color:#FFD700">Gold Tier</strong> subscription will automatically renew on <strong>$billingDate</strong>.</p>
      <div class="amount">
        <div style="color:#f57c00;font-size:16px;font-weight:600;margin-bottom:10px">Payment Amount</div>
        <div style="color:#e65100;font-size:48px;font-weight:bold;margin:10px 0">R$monthlyAmount</div>
        <div style="color:#f57c00;font-size:14px">Per Month</div>
      </div>
      <div style="background:#fff;padding:20px;border-radius:8px;margin:20px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1)">
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Plan:</strong> <span style="color:#007bff;float:right">Gold Tier</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Billing Date:</strong> <span style="color:#007bff;float:right">$billingDate</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Payment Method:</strong> <span style="color:#007bff;float:right">$paymentMethod</span></div>
        <div style="padding:10px 0;border-bottom:1px solid #e9ecef"><strong>Amount Due:</strong> <span style="color:#007bff;float:right">R$monthlyAmount</span></div>
        <div style="padding:10px 0"><strong>Status:</strong> <span style="color:#28a745;float:right">✓ ACTIVE</span></div>
      </div>
      <div class="urgent">
        <p style="color:#c62828;font-weight:600;margin:0">⚠️ Please ensure you have sufficient funds in your account to avoid service interruption</p>
      </div>
      <h3 style="color:#FF8C00;text-align:center;margin:30px 0 15px 0">You're Getting All These Benefits 👑</h3>
      <div class="benefit">Priority service with faster turnaround times</div>
      <div class="benefit">Premium support from senior designers</div>
      <div class="benefit">Exclusive member-only discounts</div>
      <div class="benefit">Unlimited revisions on all projects</div>
      <div class="benefit">Monthly design credits to use anytime</div>
      <p style="text-align:center;margin:30px 0">Thank you for being a valued Gold Tier member!</p>
    </div>
    <div class="footer">
      <p style="font-size:24px;color:#007bff;margin:0 0 15px 0"><strong>IMPACT GRAPHICS ZA</strong></p>
      <p><strong>Email:</strong> admin@impactgraphicsza.co.za</p>
      <p><strong>Phone:</strong> +27 68 367 5755</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generate text for Gold Tier payment reminder email
  static String _generateGoldTierPaymentReminderText(
    String clientName,
    String monthlyAmount,
    String billingDate,
    String paymentMethod,
  ) {
    return '''
═══════════════════════════════════════════════════════════════
IMPACT GRAPHICS ZA - PAYMENT REMINDER 🔔
Professional Design & Marketing Solutions
═══════════════════════════════════════════════════════════════

Hello $clientName! 👋

GOLD TIER PAYMENT REMINDER

This is a friendly reminder that your Gold Tier subscription will automatically renew on $billingDate.

═══════════════════════════════════════════════════════════════

PAYMENT AMOUNT: R$monthlyAmount
Per Month

═══════════════════════════════════════════════════════════════

PAYMENT DETAILS:

Subscription Plan: Gold Tier
Billing Date: $billingDate
Payment Method: $paymentMethod
Amount Due: R$monthlyAmount
Status: ✓ ACTIVE

═══════════════════════════════════════════════════════════════

⚠️ IMPORTANT:
Please ensure you have sufficient funds in your account to avoid service interruption

═══════════════════════════════════════════════════════════════

YOUR GOLD TIER BENEFITS 👑:

✓ Priority service with faster turnaround times
✓ Premium support from senior designers
✓ Exclusive member-only discounts
✓ Unlimited revisions on all projects
✓ Monthly design credits to use anytime
✓ Direct access to account management

═══════════════════════════════════════════════════════════════

AUTOMATIC RENEWAL:
Your subscription will automatically renew on $billingDate and your card will be charged R$monthlyAmount. No action needed from you!

═══════════════════════════════════════════════════════════════

Thank you for being a valued Gold Tier member. We appreciate your continued support!

If you wish to cancel your subscription, please do so at least 24 hours before the billing date.

═══════════════════════════════════════════════════════════════

CONTACT INFORMATION:
📧 Email: admin@impactgraphicsza.co.za
🌐 Website: www.impactgraphicsza.co.za
📱 Phone: +27 68 367 5755

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Where Creativity Meets Excellence
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Generate HTML for promo emails
  static String _generatePromoHtml({
    required String subject,
    required String templateId,
    required String customMessage,
    required String clientName,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$subject - Impact Graphics ZA</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap');
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: 'Poppins', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 30px 0;">
    <tr>
      <td align="center">
        <table width="650" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.15);">
          
          <!-- Header with Logo -->
          <tr>
            <td style="background: linear-gradient(135deg, #8B0000 0%, #6B0000 50%, #4B0000 100%); padding: 50px 40px; text-align: center; position: relative;">
              <!-- Logo -->
              <div style="margin-bottom: 20px;">
                <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                     alt="Impact Graphics ZA Logo" 
                     style="max-width: 180px; height: auto; filter: brightness(0) invert(1);" 
                     onerror="this.style.display='none'">
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; letter-spacing: 1px; text-transform: uppercase;">IMPACT GRAPHICS ZA</h1>
              <div style="width: 60px; height: 3px; background-color: #ffffff; margin: 15px auto;"></div>
              <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px; opacity: 0.95; font-weight: 600;">EXCITING NEWS</p>
            </td>
          </tr>

          <!-- Greeting Section -->
          <tr>
            <td style="padding: 40px 40px 20px 40px;">
              <h2 style="color: #333; margin: 0 0 15px 0; font-size: 24px; font-weight: 600;">Hello $clientName,</h2>
              <p style="color: #666; margin: 0; font-size: 15px; line-height: 1.6;">We have some amazing news to share with you!</p>
            </td>
          </tr>

          <!-- Promo Content -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f8f8 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e0e0e0; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #8B0000 0%, #6B0000 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 18px; font-weight: 600; letter-spacing: 0.5px;">🎉 SPECIAL ANNOUNCEMENT</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <div style="color: #333; font-size: 15px; line-height: 1.8;">
                        ${_getPromoContent(templateId)}
                      </div>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Custom Message Section -->
          ${customMessage.isNotEmpty ? '''
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e9ecef; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #28a745 0%, #20c997 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">💬 PERSONAL MESSAGE</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <div style="color: #333; font-size: 15px; line-height: 1.8;">
                        $customMessage
                      </div>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>
          ''' : ''}

          <!-- Call to Action -->
          <tr>
            <td style="padding: 20px 40px 30px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #f0f0f0 0%, #ffffff 100%); border-radius: 12px; padding: 30px; text-align: center;">
                <tr>
                  <td>
                    <p style="margin: 0 0 20px 0; color: #333; font-size: 16px; font-weight: 600;">Ready to get started?</p>
                    <a href="https://impact-graphics-za-266ef.web.app" 
                       style="display: inline-block; 
                              background: linear-gradient(135deg, #8B0000 0%, #6B0000 100%); 
                              color: #ffffff; 
                              text-decoration: none; 
                              padding: 18px 60px; 
                              border-radius: 50px; 
                              font-size: 18px; 
                              font-weight: 700; 
                              letter-spacing: 1px;
                              text-transform: uppercase;
                              box-shadow: 0 6px 20px rgba(139,0,0,0.4);
                              transition: all 0.3s ease;">
                      🚀 EXPLORE NOW
                    </a>
                    <p style="margin: 20px 0 0 0; color: #999; font-size: 13px; line-height: 1.6;">
                      Click the button above to visit our platform<br>
                      or contact us using the information below
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Contact Information -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #fff8e1 0%, #fffbf0 100%); border-radius: 12px; border: 2px solid #ffd54f; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #ff9800 0%, #ff5722 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">📞 GET IN TOUCH</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">📧 Email</span><br>
                            <a href="mailto:info@impactgraphicsza.co.za" style="color: #8B0000; font-size: 15px; font-weight: 600; text-decoration: none;">info@impactgraphicsza.co.za</a>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">📱 WhatsApp</span><br>
                            <a href="https://wa.me/27683675755" style="color: #8B0000; font-size: 18px; font-weight: 700; letter-spacing: 1px; text-decoration: none;">+27 68 367 5755</a>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">🌐 Website</span><br>
                            <a href="https://impact-graphics-za-266ef.web.app" style="color: #8B0000; font-size: 15px; font-weight: 600; text-decoration: none;">impactgraphicsza.co.za</a>
                          </td>
                        </tr>
                      </table>
                      <p style="margin: 15px 0 0 0; color: #e65100; font-size: 13px; line-height: 1.6;">
                        💡 <strong>Tip:</strong> Save our number to reach us quickly via WhatsApp for any questions!
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background: linear-gradient(135deg, #2a2a2a 0%, #1a1a1a 100%); padding: 30px; text-align: center;">
              <div style="margin-bottom: 15px;">
                <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                     alt="Impact Graphics ZA" 
                     style="max-width: 120px; height: auto; opacity: 0.6; filter: brightness(0) invert(1);" 
                     onerror="this.style.display='none'">
              </div>
              <p style="margin: 0 0 10px 0; color: #ffffff; font-size: 16px; font-weight: 600;">IMPACT GRAPHICS ZA</p>
              <p style="margin: 0 0 15px 0; color: #999; font-size: 12px; line-height: 1.6;">
                Professional Graphic Design & Marketing Solutions<br>
                Making Your Brand Stand Out
              </p>
              <div style="border-top: 1px solid #444; margin: 20px 0; padding-top: 20px;">
                <p style="margin: 0; color: #888; font-size: 11px; line-height: 1.6;">
                  © ${DateTime.now().year} Impact Graphics ZA. All rights reserved.<br>
                  This email was sent to you because you are a valued client of Impact Graphics ZA.<br>
                  For support, contact us at info@impactgraphicsza.co.za
                </p>
              </div>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  /// Generate plain text for promo emails
  static String _generatePromoText({
    required String subject,
    required String templateId,
    required String customMessage,
    required String clientName,
  }) {
    return '''
IMPACT GRAPHICS ZA - $subject
═══════════════════════════════════════════════════════════════

Hello $clientName,

We have some amazing news to share with you!

═══════════════════════════════════════════════════════════════
🎉 SPECIAL ANNOUNCEMENT
═══════════════════════════════════════════════════════════════

${_getPromoContent(templateId)}

${customMessage.isNotEmpty ? '''
═══════════════════════════════════════════════════════════════
💬 PERSONAL MESSAGE
═══════════════════════════════════════════════════════════════

$customMessage
''' : ''}

═══════════════════════════════════════════════════════════════
🚀 READY TO GET STARTED?
═══════════════════════════════════════════════════════════════

Visit our platform: https://impact-graphics-za-266ef.web.app

═══════════════════════════════════════════════════════════════
📞 CONTACT INFORMATION
═══════════════════════════════════════════════════════════════

📧 Email: info@impactgraphicsza.co.za
📱 WhatsApp: +27 68 367 5755
🌐 Website: impactgraphicsza.co.za

💡 Tip: Save our number to reach us quickly via WhatsApp!

═══════════════════════════════════════════════════════════════

Best regards,
The Impact Graphics ZA Team

IMPACT GRAPHICS ZA | Where Creativity Meets Excellence
© ${DateTime.now().year} Impact Graphics ZA. All rights reserved.
═══════════════════════════════════════════════════════════════
''';
  }

  /// Get promo content based on template ID
  static String _getPromoContent(String templateId) {
    switch (templateId) {
      case 'feature_launch':
        return '''
🎉 EXCITING NEW FEATURES LAUNCHED! 🎉

We're thrilled to announce some amazing new features that will revolutionize your experience with Impact Graphics ZA!

✨ NEW FEATURES:
• Enhanced Portfolio Management
• Real-time Collaboration Tools
• Advanced Analytics Dashboard
• Mobile App Improvements

🚀 WHAT'S NEW:
Our team has been working tirelessly to bring you cutting-edge tools that will help your business grow and succeed.

💡 SPECIAL OFFER:
As a valued client, you get 30% OFF on all new services for the next 30 days!

Ready to explore? Visit our platform now!
        ''';
      case 'gold_tier_promo':
        return '''
💎 UNLOCK PREMIUM BENEFITS WITH GOLD TIER! 💎

Ready to take your business to the next level? Our Gold Tier subscription offers exclusive benefits that will transform your experience!

🌟 GOLD TIER BENEFITS:
• Priority Support (24/7)
• Exclusive Design Templates
• Advanced Analytics
• Custom Branding Solutions
• 50% Discount on All Services

🎯 LIMITED TIME OFFER:
Get your first month FREE when you upgrade to Gold Tier!

Don't miss out on this incredible opportunity!
        ''';
      case 'design_special':
        return '''
🎨 DESIGN SPECIAL - 50% OFF! 🎨

We're celebrating our success with YOU! Get 50% OFF on all design services for the next 7 days!

🎯 SPECIAL OFFERS:
• Logo Design: R500 (was R1000)
• Website Design: R2500 (was R5000)
• Brand Package: R1500 (was R3000)
• Social Media Kit: R300 (was R600)

⏰ HURRY! This offer expires in 7 days!

Book your project now and save big!
        ''';
      case 'mobile_update':
        return '''
📱 MOBILE APP UPDATE - NEW FEATURES! 📱

We've just released a major update to our mobile app with incredible new features!

🆕 NEW MOBILE FEATURES:
• Offline Mode
• Push Notifications
• Quick Project Sharing
• Enhanced Security
• Dark Mode

📲 DOWNLOAD NOW:
Update your app to get the latest features and improvements!

Thank you for being part of our mobile community!
        ''';
      case 'marketing_deal':
        return '''
🎯 MARKETING PACKAGE DEAL - LIMITED TIME! 🎯

Boost your business with our comprehensive marketing packages at unbeatable prices!

📦 PACKAGE DEALS:
• Starter Package: R2000 (was R4000)
• Professional Package: R5000 (was R10000)
• Enterprise Package: R10000 (was R20000)

🎁 BONUS:
Free consultation worth R500 with any package!

⏰ OFFER VALID FOR 14 DAYS ONLY!

Secure your package today!
        ''';
      default:
        return 'Special announcement content not available.';
    }
  }

  /// Generate HTML for promo email with custom content
  static String _generatePromoHtmlWithContent({
    required String subject,
    required String templateId,
    required String content,
    required String customMessage,
    required String clientName,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$subject</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #8B0000;
        }
        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #8B0000;
            margin-bottom: 10px;
        }
        .content {
            margin-bottom: 30px;
            white-space: pre-line;
            font-size: 16px;
        }
        .custom-message {
            background-color: #f8f9fa;
            padding: 20px;
            border-left: 4px solid #8B0000;
            margin: 20px 0;
            border-radius: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 14px;
            color: #666;
        }
        .contact-info {
            margin-top: 15px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">IMPACT GRAPHICS ZA</div>
            <div style="font-size: 14px; color: #666;">Professional Design Solutions</div>
        </div>
        
        <div class="content">${content.replaceAll('\n', '<br>')}</div>
        
        ${customMessage.isNotEmpty ? '''
        <div class="custom-message">
            <strong>Personal Message:</strong><br>
            ${customMessage.replaceAll('\n', '<br>')}
        </div>
        ''' : ''}
        
        <div class="footer">
            <p>Thank you for choosing Impact Graphics ZA!</p>
            <div class="contact-info">
                <strong>Contact Us:</strong><br>
                📞 +27 68 367 5755<br>
                📧 info@impactgraphicsza.co.za<br>
                🌐 www.impactgraphicsza.co.za
            </div>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Generate plain text for promo email with custom content
  static String _generatePromoTextWithContent({
    required String subject,
    required String templateId,
    required String content,
    required String customMessage,
    required String clientName,
  }) {
    return '''
IMPACT GRAPHICS ZA
Professional Design Solutions

$content

${customMessage.isNotEmpty ? '''
Personal Message:
$customMessage

''' : ''}
Thank you for choosing Impact Graphics ZA!

Contact Us:
📞 +27 68 367 5755
📧 info@impactgraphicsza.co.za
🌐 www.impactgraphicsza.co.za
    ''';
  }
}

/// Email result class
class EmailResult {
  final bool success;
  final String? messageId;
  final String message;
  final int? errorCode;

  EmailResult({
    required this.success,
    this.messageId,
    required this.message,
    this.errorCode,
  });

  static EmailResult successResult(String message) {
    return EmailResult(success: true, message: message);
  }

  static EmailResult errorResult(String message, {int? errorCode}) {
    return EmailResult(success: false, message: message, errorCode: errorCode);
  }
}
