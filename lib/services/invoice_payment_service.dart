import 'dart:convert';

import 'package:http/http.dart' as http;

class InvoicePaymentService {
  static const String _secretKey = 'sk_live_PLACEHOLDER';
  static const String _baseUrl = 'https://api.paystack.co';

  /// Generate a Paystack payment link for an invoice
  static Future<Map<String, dynamic>> generatePaymentLink({
    required String email,
    required double amount,
    required String reference,
    required String customerName,
    String? phoneNumber,
    String? serviceName,
  }) async {
    try {
      // Generate a unique payment reference to avoid duplicates
      final uniqueReference =
          'INV_${DateTime.now().millisecondsSinceEpoch}_${reference.substring(0, 8)}';

      print('=== GENERATING INVOICE PAYMENT LINK ===');
      print('Email: $email');
      print('Amount: R$amount');
      print('Original Reference: $reference');
      print('Unique Reference: $uniqueReference');
      print('Customer: $customerName');

      final url = Uri.parse('$_baseUrl/transaction/initialize');
      final headers = {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'email': email,
        'amount': (amount * 100).round(), // Convert to kobo
        'reference': uniqueReference, // Use unique reference
        'currency': 'ZAR',
        'callback_url':
            'https://impact-graphics-za-266ef.web.app/payment-success',
        'metadata': {
          'customer_name': customerName,
          'phone_number': phoneNumber ?? '',
          'service_name': serviceName ?? 'Invoice Payment',
          'payment_source': 'invoice_pdf',
          'original_reference':
              reference, // Keep original reference in metadata
          'custom_fields': [
            {
              'display_name': 'Payment Source',
              'variable_name': 'payment_source',
              'value': 'invoice_pdf',
            },
          ],
        },
      };

      print('=== PAYSTACK API REQUEST ===');
      print('URL: $url');
      print('Body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('=== PAYSTACK API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['status'] == true && result['data'] != null) {
          final authorizationUrl =
              result['data']['authorization_url'] as String;

          // Add cache-busting parameter
          final cacheBuster = DateTime.now().millisecondsSinceEpoch;
          final finalUrl = authorizationUrl.contains('?')
              ? '$authorizationUrl&cb=$cacheBuster'
              : '$authorizationUrl?cb=$cacheBuster';

          print('✅ Payment link generated successfully');
          print('Payment URL: $finalUrl');

          return {
            'success': true,
            'paymentUrl': finalUrl,
            'reference': uniqueReference,
            'originalReference': reference,
            'message': 'Payment link generated successfully',
          };
        } else {
          print('❌ Paystack returned error: ${result['message']}');
          return {
            'success': false,
            'message': 'Paystack error: ${result['message']}',
          };
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error generating payment link: $e');
      return {'success': false, 'message': 'Error generating payment link: $e'};
    }
  }

  /// Generate a QR code data URL for the payment link
  static String generateQRCodeData(String paymentUrl) {
    // For now, return the payment URL as QR code data
    // In a real implementation, you might want to use a QR code library
    return paymentUrl;
  }
}
