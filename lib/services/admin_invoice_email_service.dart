import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/mailersend_service.dart';

/// Admin Invoice Email Service
/// Handles sending invoice emails when admin creates invoices
class AdminInvoiceEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send invoice email for admin-created invoice
  static Future<EmailResult> sendInvoiceEmail({
    required String customerName,
    required String customerEmail,
    required String serviceName,
    required double amount,
    required String invoiceNumber,
    required String description,
    required String invoiceId,
  }) async {
    try {
      print('📧 Preparing admin invoice email...');

      // Generate Paystack payment link
      final paymentLink = _generatePaystackPaymentLink(
        customerEmail: customerEmail,
        amount: amount,
        serviceName: serviceName,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
      );

      // Build email template
      final emailBody = _buildInvoiceEmailTemplate(
        customerName: customerName,
        serviceName: serviceName,
        amount: amount,
        invoiceNumber: invoiceNumber,
        description: description,
        paymentLink: paymentLink,
      );

      // Create email document for MailerSend extension
      final emailData = {
        'to': [
          {'email': customerEmail, 'name': customerName},
        ],
        'subject': 'Invoice $invoiceNumber - Impact Graphics ZA',
        'html': emailBody,
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
            'email': customerEmail,
            'substitutions': [
              {'var': 'customer_name', 'value': customerName},
              {'var': 'service_name', 'value': serviceName},
              {'var': 'amount', 'value': 'R ${amount.toStringAsFixed(2)}'},
              {'var': 'invoice_number', 'value': invoiceNumber},
              {'var': 'description', 'value': description},
              {'var': 'payment_link', 'value': paymentLink},
            ],
          },
        ],
        'tags': ['invoice', 'admin-created', 'payment'],
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
        'source': 'admin-invoice',
        'invoice_id': invoiceId,
      };

      print('📧 Adding admin invoice email to Firestore...');

      // Write to Firestore emails collection to trigger MailerSend extension
      final docRef = await _firestore.collection('emails').add(emailData);

      print('✅ Admin invoice email queued with ID: ${docRef.id}');

      return EmailResult(
        success: true,
        message: 'Invoice email queued successfully',
        messageId: docRef.id,
      );
    } catch (error) {
      print('❌ Error sending admin invoice email: $error');
      return EmailResult(
        success: false,
        message: 'Error sending invoice email: $error',
      );
    }
  }

  /// Generate Paystack payment link for invoice
  static String _generatePaystackPaymentLink({
    required String customerEmail,
    required double amount,
    required String serviceName,
    required String invoiceNumber,
    required String customerName,
  }) {
    // Use company's Paystack payment page with parameters
    final amountInRand = amount.round(); // Convert R1500.00 to 1500
    final baseUrl = 'https://paystack.shop/pay/n6c6hp792r';

    // Build URL with multiple parameters
    final paymentLink =
        '$baseUrl?amount=$amountInRand&email=${Uri.encodeComponent(customerEmail)}&name=${Uri.encodeComponent(customerName)}';

    print('📧 Generated payment link: $paymentLink');
    print('📧 Original amount: R${amount.toStringAsFixed(2)}');
    print('📧 Amount in Rand: $amountInRand');
    print('📧 Customer email: $customerEmail');
    print('📧 Customer name: $customerName');
    return paymentLink;
  }

  /// Build professional invoice email template
  static String _buildInvoiceEmailTemplate({
    required String customerName,
    required String serviceName,
    required double amount,
    required String invoiceNumber,
    required String description,
    required String paymentLink,
  }) {
    final formattedAmount = 'R ${amount.toStringAsFixed(2)}';
    final formattedDate = DateTime.now().toLocal().toString().split(' ')[0];

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice - Impact Graphics ZA</title>
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
              <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px; opacity: 0.95; font-weight: 600;">INVOICE</p>
            </td>
          </tr>

          <!-- Greeting Section -->
          <tr>
            <td style="padding: 40px 40px 20px 40px;">
              <h2 style="color: #333; margin: 0 0 15px 0; font-size: 24px; font-weight: 600;">Hello $customerName,</h2>
              <p style="color: #666; margin: 0; font-size: 15px; line-height: 1.6;">Thank you for choosing Impact Graphics ZA. Please find your invoice details below.</p>
            </td>
          </tr>

          <!-- Invoice Info -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8f8f8; border-radius: 8px; padding: 20px; border-left: 4px solid #8B0000;">
                <tr>
                  <td>
                    <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Invoice To</p>
                    <p style="margin: 8px 0 0 0; color: #333; font-size: 18px; font-weight: 600;">$customerName</p>
                  </td>
                  <td align="right">
                    <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Invoice #</p>
                    <p style="margin: 8px 0 0 0; color: #8B0000; font-size: 18px; font-weight: 700;">$invoiceNumber</p>
                  </td>
                </tr>
                <tr>
                  <td colspan="2" style="padding-top: 15px;">
                    <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Date</p>
                    <p style="margin: 8px 0 0 0; color: #333; font-size: 15px; font-weight: 600;">$formattedDate</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Service Details -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f8f8 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e0e0e0; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #8B0000 0%, #6B0000 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 18px; font-weight: 600; letter-spacing: 0.5px;">📋 SERVICE DETAILS</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 20px;">
                  <tr>
                    <td style="padding: 12px 0; border-bottom: 1px solid #e0e0e0;">
                      <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Service</p>
                      <p style="margin: 6px 0 0 0; color: #333; font-size: 16px; font-weight: 600;">$serviceName</p>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 12px 0; border-bottom: 1px solid #e0e0e0;">
                      <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Description</p>
                      <p style="margin: 6px 0 0 0; color: #333; font-size: 15px; font-weight: 500;">$description</p>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 20px 0 0 0;">
                      <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #8B0000 0%, #6B0000 100%); border-radius: 8px; padding: 20px;">
                        <tr>
                          <td>
                            <p style="margin: 0; color: #ffffff; font-size: 14px; opacity: 0.9; text-transform: uppercase; letter-spacing: 1px;">Total Amount Due</p>
                          </td>
                          <td align="right">
                            <p style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 700; letter-spacing: 1px;">$formattedAmount</p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Payment Button -->
          <tr>
            <td style="padding: 20px 40px 30px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #f0f0f0 0%, #ffffff 100%); border-radius: 12px; padding: 30px; text-align: center;">
                <tr>
                  <td>
                    <p style="margin: 0 0 20px 0; color: #333; font-size: 16px; font-weight: 600;">Ready to complete your payment?</p>
                    <a href="$paymentLink" 
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
                      💳 PAY NOW
                    </a>
                    <p style="margin: 20px 0 0 0; color: #999; font-size: 13px; line-height: 1.6;">
                      Click the button above to make your payment securely via Paystack<br>
                      <span style="color: #8B0000; font-weight: 600;">🔒 Secured by Paystack</span>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Alternative Payment Methods -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e9ecef; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #28a745 0%, #20c997 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">🏦 ALTERNATIVE PAYMENT METHODS</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <p style="margin: 0 0 15px 0; color: #333; font-size: 14px; font-weight: 600;">Prefer Bank Transfer?</p>
                      <div style="background-color: #ffffff; border-radius: 8px; padding: 20px; border-left: 4px solid #28a745;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Bank Name</span><br>
                              <span style="color: #333; font-size: 15px; font-weight: 600;">Capitec Business</span>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Account Number</span><br>
                              <span style="color: #333; font-size: 18px; font-weight: 700; letter-spacing: 2px;">1053262485</span>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Account Holder</span><br>
                              <span style="color: #333; font-size: 15px; font-weight: 600;">Impact Graphics ZA</span>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Reference</span><br>
                              <span style="color: #8B0000; font-size: 15px; font-weight: 700;">$invoiceNumber</span>
                            </td>
                          </tr>
                        </table>
                      </div>
                      <p style="margin: 15px 0 0 0; color: #666; font-size: 12px; line-height: 1.6;">
                        💡 <strong>Important:</strong> Please use the invoice number as your payment reference when making a bank transfer.
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Important Notice -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #fff8e1 0%, #fffbf0 100%); border-radius: 12px; border: 2px solid #ffd54f; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #ff9800 0%, #ff5722 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">💡 IMPORTANT NOTICE</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <p style="margin: 0 0 15px 0; color: #e65100; font-size: 14px; line-height: 1.8; font-weight: 600;">
                        If you have <strong>already paid</strong> for this service through other means, you can safely <strong>ignore this email</strong>.
                      </p>
                      <p style="margin: 0; color: #e65100; font-size: 14px; line-height: 1.8;">
                        Our records will be updated automatically upon payment confirmation. For bank transfers, please ensure you use the invoice number as your payment reference.
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Contact Section -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e9ecef; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #007bff 0%, #0056b3 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">📞 NEED HELP?</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <p style="margin: 0 0 15px 0; color: #333; font-size: 14px; font-weight: 600;">Contact our support team:</p>
                      <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Email</span><br>
                            <span style="color: #007bff; font-size: 15px; font-weight: 600;">info@impactgraphicsza.co.za</span>
                          </td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0;">
                            <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">WhatsApp</span><br>
                            <span style="color: #007bff; font-size: 15px; font-weight: 600;">+27 68 367 5755</span>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #1a1a1a; padding: 30px 40px; text-align: center;">
              <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                   alt="Impact Graphics ZA" 
                   style="max-width: 120px; height: auto; opacity: 0.6; filter: brightness(0) invert(1);" 
                   onerror="this.style.display='none'">
              <p style="color: #ffffff; margin: 15px 0 0 0; font-size: 14px; opacity: 0.8; font-weight: 600;">
                Creating Impact Through Design
              </p>
              <div style="margin-top: 20px;">
                <a href="https://impactgraphicsza.co.za" style="color: #8B0000; text-decoration: none; font-size: 12px; margin: 0 10px;">Website</a>
                <span style="color: #666;">|</span>
                <a href="mailto:info@impactgraphicsza.co.za" style="color: #8B0000; text-decoration: none; font-size: 12px; margin: 0 10px;">Support</a>
                <span style="color: #666;">|</span>
                <a href="https://wa.me/27683675755" style="color: #8B0000; text-decoration: none; font-size: 12px; margin: 0 10px;">WhatsApp</a>
              </div>
              <p style="color: #666; margin: 20px 0 0 0; font-size: 11px; line-height: 1.5;">
                This email was sent from Impact Graphics ZA. If you have any questions about this invoice, please contact our support team.
              </p>
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
}



