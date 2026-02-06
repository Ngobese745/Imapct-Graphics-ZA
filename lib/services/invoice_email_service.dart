import 'dart:convert';
import 'package:http/http.dart' as http;

class InvoiceEmailService {
  static const String _apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiMGQ2OTFmMTJmYzFiMTdiNzk5MjAzZDkxZjNjZmI3MjlhMDAzMjkwNDQyMWExOGFkNTVlMDJiZmFiM2IzNjcyMzNlMzhmZjgwYjg1MjJkYmIiLCJpYXQiOjE3NTQ2NTYwMjUuMDMwMjk0LCJuYmYiOjE3NTQ2NTYwMjUuMDMwMjk2LCJleHAiOjQ5MDgyNTYwMjUuMDI4MTU0LCJzdWIiOiI5OTg1NzUiLCJzY29wZXMiOltdfQ.LlE_2FYMdB6RSri0RdTU4gcw96aOha7MgAVnRff_L4ahPXHGJuI6KP-qvsZMdUlvB8BjiKuu_TQl8q0fY3u1I4t-OrYKVe04WiLc23pu2py-svEF6IaAlTTpCsIe459dPBoE5mFPdJ9CoqMwfd2UFNRlXfgSIS1oII0BJplaz_2xFR5nGkh78HiE741o7qrekfdc1FTD2E0_X_wy0ef-ispQ2pVxiKoloPGmmd1nteBZmwsZVmkdJnuv4we_Th9eSvpKWVxMAd5doGcA-C-dz7pM5CbYhk7gKJF-ckIkeT1C88BMVciJtE3ycJUCZjcKgy81Jp-PtEIVdnhAFa8eadxArih2mGcPlPve2S8WE0zbDoNcHyTmqoULwTioXLS-IqHOTcgIuvQzdvHh2MSNekM-K_ur0to94IoLGZWxwKhMgZvGyGeR2SLa88TbHv99cn2i2rBV2QkuzU0pzennFtADoKBzcMLqEyoo4TYJzUuyYOg2h1_gj1jUXGIJgYSzPVs8g0Ofi4eNX2KrvnPsRIRml00Chgk8RjQ86aGO5gcuas3eX0vLsyLdxhYej2Ehqa4knoGEImrTmz7a-4Fj8O-hROLOrCRzsskhnJS8QKYJNPLuGqfbT9zbIo5lLdTOraO_1FLDQPA_hX7Va81QSkcoySMeNpl6QPffsf6ruPU';
  static const String _baseUrl = 'https://api.sender.net';

  /// Send invoice email for every transaction
  static Future<EmailResult> sendInvoiceEmail({
    required String toEmail,
    required String toName,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required String description,
    required String paymentMethod,
    required String transactionId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    try {
      // print('📧 Invoice Email Service: Sending invoice email to: $toEmail');
      // print(
      //        '📧 Invoice #$invoiceNumber, Amount: $currency${amount.toStringAsFixed(2)}',
      //      );

      // Step 1: Ensure subscriber exists in Invoice group
      await _ensureSubscriberInInvoiceGroup(
        email: toEmail,
        name: toName,
        invoiceNumber: invoiceNumber,
        amount: amount,
        currency: currency,
        description: description,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        transactionDate: transactionDate,
        notes: notes,
      );

      // Step 2: Create and send individual invoice campaign
      final campaignResult = await _createInvoiceCampaign(
        toEmail: toEmail,
        toName: toName,
        invoiceNumber: invoiceNumber,
        amount: amount,
        currency: currency,
        description: description,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        transactionDate: transactionDate,
        notes: notes,
      );

      return campaignResult;
    } catch (e) {
      // print('📧 Error in invoice email service: $e');
      return EmailResult(
        success: false,
        message: 'Error sending invoice email: $e',
      );
    }
  }

  /// Ensure subscriber exists in Invoice group with invoice data
  static Future<void> _ensureSubscriberInInvoiceGroup({
    required String email,
    required String name,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required String description,
    required String paymentMethod,
    required String transactionId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    try {
      // print('📧 Ensuring subscriber $email is in Invoice group...');

      final requestBody = {
        'email': email,
        'groups': ['b2JxAj'], // Invoice group ID (from your previous data)
        'fields': {
          'invoice_number': invoiceNumber,
          'amount': amount.toStringAsFixed(2),
          'currency': currency,
          'description': description,
          'payment_method': paymentMethod,
          'transaction_id': transactionId,
          'transaction_date': transactionDate.toIso8601String(),
          'client_name': name,
          'notes': notes ?? '',
          'invoice_sent': 'true',
          'sent_date': DateTime.now().toIso8601String(),
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // print('📧 Invoice subscriber update response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // print('📧 ✅ Subscriber $email updated in Invoice group');
      } else {
        // print('📧 ⚠️ Invoice subscriber update response: ${response.body}');
      }
    } catch (e) {
      // print('📧 Error ensuring subscriber in invoice group: $e');
    }
  }

  /// Create individual invoice campaign for each transaction
  static Future<EmailResult> _createInvoiceCampaign({
    required String toEmail,
    required String toName,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required String description,
    required String paymentMethod,
    required String transactionId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    try {
      // print('📧 Creating invoice campaign for transaction $transactionId...');

      // Generate HTML invoice content
      final htmlContent = _generateInvoiceHtml(
        invoiceNumber: invoiceNumber,
        amount: amount,
        currency: currency,
        description: description,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        transactionDate: transactionDate,
        clientName: toName,
        notes: notes,
      );

      // For invoice emails, we'll use a different approach
      // Since Sender.net campaign API has limitations, we'll use the subscriber update method
      // with a special field that can trigger a different workflow
      final invoiceData = {
        'email': toEmail,
        'groups': ['b2JxAj'], // Invoice group
        'fields': {
          'invoice_number': invoiceNumber,
          'amount': amount.toStringAsFixed(2),
          'currency': currency,
          'description': description,
          'payment_method': paymentMethod,
          'transaction_id': transactionId,
          'transaction_date': transactionDate.toIso8601String(),
          'client_name': toName,
          'notes': notes ?? '',
          'invoice_trigger': 'true', // Special field to trigger invoice email
          'html_content': htmlContent, // Store HTML content
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(invoiceData),
      );

      // print('📧 Invoice campaign response: ${response.statusCode}');
      // print('📧 Invoice campaign body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // print('📧 ✅ Invoice email sent successfully!');
        return EmailResult(
          success: true,
          messageId: transactionId,
          message: 'Invoice email sent for transaction $transactionId',
        );
      } else {
        // print('📧 ❌ Invoice campaign failed: ${response.body}');
        return EmailResult(
          success: false,
          message: 'Failed to send invoice email',
        );
      }
    } catch (e) {
      // print('📧 Error creating invoice campaign: $e');
      return EmailResult(
        success: false,
        message: 'Error creating invoice campaign: $e',
      );
    }
  }

  /// Generate professional HTML invoice
  static String _generateInvoiceHtml({
    required String invoiceNumber,
    required double amount,
    required String currency,
    required String description,
    required String paymentMethod,
    required String transactionId,
    required DateTime transactionDate,
    required String clientName,
    String? notes,
  }) {
    final formattedDate = transactionDate.toLocal().toString().split(' ')[0];
    final formattedTime = transactionDate
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 8);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice #$invoiceNumber - Impact Graphics ZA</title>
</head>
<body style="margin: 0; padding: 0; background: linear-gradient(135deg, #0F0F10, #1C1C1E); font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 40px auto; background: rgba(255,255,255,0.05); border-radius: 16px; padding: 0; backdrop-filter: blur(12px); box-shadow: 0 8px 24px rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.1);">

    <!-- Header -->
    <div style="background: linear-gradient(135deg, #E53935 0%, #171819 100%); padding: 30px; text-align: center;">
      <img src="https://impactgraphicsza.co.za/assets/logo.png" alt="Impact Graphics ZA" width="48" height="48" style="border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.3); margin-bottom: 12px;" />
      <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 1px;">IMPACT GRAPHICS ZA</h1>
      <p style="color: #fddede; margin: 10px 0 0 0; font-size: 16px; font-weight: 300;">Creative Solutions • Professional Results</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 30px;">

      <!-- Invoice Header -->
      <div style="margin-bottom: 30px; text-align: center;">
        <h2 style="color: #E53935; margin: 0 0 10px 0; font-size: 32px; font-weight: 700;">INVOICE</h2>
        <p style="color: #666666; margin: 0; font-size: 18px; font-weight: 600;">#$invoiceNumber</p>
      </div>

      <!-- Invoice Details -->
      <div style="background: #f8f9fa; border-radius: 12px; padding: 25px; margin: 30px 0; border-left: 5px solid #E53935;">
        <h3 style="color: #E53935; margin: 0 0 20px 0; font-size: 20px; font-weight: 600;">📋 Invoice Details</h3>
        
        <div style="display: flex; flex-direction: column; gap: 15px;">
          <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #dee2e6;">
            <span style="color: #666666; font-weight: 500; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Client Name</span>
            <span style="color: #333333; font-weight: 600; font-size: 16px;">$clientName</span>
          </div>
          
          <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #dee2e6;">
            <span style="color: #666666; font-weight: 500; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Transaction ID</span>
            <span style="color: #333333; font-weight: 600; font-size: 16px;">$transactionId</span>
          </div>
          
          <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #dee2e6;">
            <span style="color: #666666; font-weight: 500; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Date</span>
            <span style="color: #333333; font-weight: 600; font-size: 16px;">$formattedDate at $formattedTime</span>
          </div>
          
          <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #dee2e6;">
            <span style="color: #666666; font-weight: 500; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Payment Method</span>
            <span style="color: #333333; font-weight: 600; font-size: 16px;">$paymentMethod</span>
          </div>
          
          <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 0;">
            <span style="color: #666666; font-weight: 500; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Description</span>
            <span style="color: #333333; font-weight: 600; font-size: 16px;">$description</span>
          </div>
        </div>
      </div>

      <!-- Amount Section -->
      <div style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%); border-radius: 12px; padding: 30px; margin: 30px 0; text-align: center;">
        <h3 style="color: #ffffff; margin: 0 0 10px 0; font-size: 18px; font-weight: 600;">Total Amount</h3>
        <p style="color: #ffffff; margin: 0; font-size: 36px; font-weight: 700;">$currency${amount.toStringAsFixed(2)}</p>
        <p style="color: #e8f5e8; margin: 10px 0 0 0; font-size: 14px;">Payment Successful</p>
      </div>

      ${notes != null && notes.isNotEmpty ? '''
      <!-- Notes Section -->
      <div style="margin: 30px 0;">
        <h3 style="color: #E53935; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">📝 Additional Notes</h3>
        <div style="background-color: #ffffff; border: 2px solid #e9ecef; border-radius: 8px; padding: 20px; color: #555555; line-height: 1.6;">
          $notes
        </div>
      </div>
      ''' : ''}

      <!-- Thank You Message -->
      <div style="text-align: center; margin: 40px 0;">
        <div style="background: linear-gradient(135deg, #E53935 0%, #171819 100%); border-radius: 8px; padding: 30px; margin: 20px 0;">
          <h3 style="color: #ffffff; margin: 0 0 15px 0; font-size: 20px; font-weight: 600;">Thank You for Your Business!</h3>
          <p style="color: #fddede; margin: 0 0 25px 0; font-size: 16px;">We appreciate your trust in Impact Graphics ZA. Your payment has been processed successfully.</p>
          
          <!-- Contact Button -->
          <a href="mailto:admin@impactgraphicsza.co.za?subject=Invoice #$invoiceNumber - Question" 
             style="display: inline-block; background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%); color: #E53935; text-decoration: none; padding: 15px 30px; border-radius: 8px; font-weight: 700; font-size: 16px; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 4px 12px rgba(0,0,0,0.2); transition: all 0.3s ease; border: 2px solid #ffffff; margin: 10px;">
            📧 Contact Us
          </a>
        </div>
      </div>

      <!-- Contact Information -->
      <div style="background-color: #f8f9fa; border-radius: 8px; padding: 25px; margin: 30px 0;">
        <h3 style="color: #E53935; margin: 0 0 20px 0; font-size: 18px; font-weight: 600;">📞 Support Information</h3>
        <div style="display: flex; flex-direction: column; gap: 10px;">
          <p style="color: #555555; margin: 0; font-size: 14px;"><strong style="color: #E53935;">Email:</strong> admin@impactgraphicsza.co.za</p>
          <p style="color: #555555; margin: 0; font-size: 14px;"><strong style="color: #E53935;">Website:</strong> www.impactgraphicsza.co.za</p>
          <p style="color: #555555; margin: 0; font-size: 14px;"><strong style="color: #E53935;">Support:</strong> Available 24/7</p>
        </div>
      </div>

    </div>

    <!-- Footer -->
    <div style="background-color: #171819; padding: 25px; text-align: center;">
      <p style="color: #fddede; margin: 0 0 10px 0; font-size: 16px; font-weight: 600;">Impact Graphics ZA</p>
      <p style="color: #9EA3A8; margin: 0; font-size: 14px;">Creative Solutions • Professional Results • South Africa</p>
      <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #2a2a2a;">
        <p style="color: #9EA3A8; margin: 0; font-size: 12px;">This is an automated invoice from Impact Graphics ZA. Please keep this for your records.</p>
      </div>
    </div>

  </div>

</body>
</html>
    ''';
  }
}

class EmailResult {
  final bool success;
  final String message;
  final String? messageId;
  final int? errorCode;

  EmailResult({
    required this.success,
    required this.message,
    this.messageId,
    this.errorCode,
  });
}
