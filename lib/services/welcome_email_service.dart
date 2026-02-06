import 'dart:convert';
import 'package:http/http.dart' as http;

class WelcomeEmailService {
  static const String _apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiMGQ2OTFmMTJmYzFiMTdiNzk5MjAzZDkxZjNjZmI3MjlhMDAzMjkwNDQyMWExOGFkNTVlMDJiZmFiM2IzNjcyMzNlMzhmZjgwYjg1MjJkYmIiLCJpYXQiOjE3NTQ2NTYwMjUuMDMwMjk0LCJuYmYiOjE3NTQ2NTYwMjUuMDMwMjk2LCJleHAiOjQ5MDgyNTYwMjUuMDI4MTU0LCJzdWIiOiI5OTg1NzUiLCJzY29wZXMiOltdfQ.LlE_2FYMdB6RSri0RdTU4gcw96aOha7MgAVnRff_L4ahPXHGJuI6KP-qvsZMdUlvB8BjiKuu_TQl8q0fY3u1I4t-OrYKVe04WiLc23pu2py-svEF6IaAlTTpCsIe459dPBoE5mFPdJ9CoqMwfd2UFNRlXfgSIS1oII0BJplaz_2xFR5nGkh78HiE741o7qrekfdc1FTD2E0_X_wy0ef-ispQ2pVxiKoloPGmmd1nteBZmwsZVmkdJnuv4we_Th9eSvpKWVxMAd5doGcA-C-dz7pM5CbYhk7gKJF-ckIkeT1C88BMVciJtE3ycJUCZjcKgy81Jp-PtEIVdnhAFa8eadxArih2mGcPlPve2S8WE0zbDoNcHyTmqoULwTioXLS-IqHOTcgIuvQzdvHh2MSNekM-K_ur0to94IoLGZWxwKhMgZvGyGeR2SLa88TbHv99cn2i2rBV2QkuzU0pzennFtADoKBzcMLqEyoo4TYJzUuyYOg2h1_gj1jUXGIJgYSzPVs8g0Ofi4eNX2KrvnPsRIRml00Chgk8RjQ86aGO5gcuas3eX0vLsyLdxhYej2Ehqa4knoGEImrTmz7a-4Fj8O-hROLOrCRzsskhnJS8QKYJNPLuGqfbT9zbIo5lLdTOraO_1FLDQPA_hX7Va81QSkcoySMeNpl6QPffsf6ruPU';
  static const String _baseUrl = 'https://api.sender.net';

  /// Send welcome email to new users using Sender.net workflow
  static Future<EmailResult> sendWelcomeEmail({
    required String userEmail,
    required String userName,
  }) async {
    try {
// print('📧 Sending welcome email to: $userEmail');
// print('📧 User name: $userName');

      // Create the request body for welcome workflow
      final requestBody = {
        'email': userEmail,
        'groups': ['b4KQA6'], // Welcome group ID for Onboarding workflow
        'fields': {
          'client_name': userName,
          'message_body':
              'Welcome to Impact Graphics ZA! We\'re excited to have you on board and look forward to working with you on your creative projects.',
          'welcome_trigger': 'true', // Custom field to trigger welcome workflow
        },
      };

// print('📧 Welcome email request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

// print('📧 Welcome email response status: ${response.statusCode}');
// print('📧 Welcome email response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
// print('📧 ✅ Welcome email sent successfully! Response: $responseData');
        return EmailResult(
          success: true,
          messageId: responseData['id']?.toString() ?? 'unknown',
          message: 'Welcome email sent successfully',
        );
      } else {
        final errorData = jsonDecode(response.body);
// print('📧 ❌ Welcome email error: $errorData');
        return EmailResult(
          success: false,
          message: errorData['message'] ?? 'Failed to send welcome email',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
// print('📧 Error sending welcome email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending welcome email: $e',
      );
    }
  }

  /// Test welcome email functionality
  static Future<EmailResult> testWelcomeEmail({
    String testEmail = 'test@example.com',
    String testName = 'Test User',
  }) async {
// print('🧪 Testing welcome email functionality...');
    return await sendWelcomeEmail(userEmail: testEmail, userName: testName);
  }
}

/// Result class for email operations
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

  @override
  String toString() {
    return 'EmailResult(success: $success, message: $message, messageId: $messageId, errorCode: $errorCode)';
  }
}
