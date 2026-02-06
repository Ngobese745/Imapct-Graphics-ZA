import 'dart:convert';
import 'package:http/http.dart' as http;

class EnhancedEmailService {
  static const String _apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiMGQ2OTFmMTJmYzFiMTdiNzk5MjAzZDkxZjNjZmI3MjlhMDAzMjkwNDQyMWExOGFkNTVlMDJiZmFiM2IzNjcyMzNlMzhmZjgwYjg1MjJkYmIiLCJpYXQiOjE3NTQ2NTYwMjUuMDMwMjk0LCJuYmYiOjE3NTQ2NTYwMjUuMDMwMjk2LCJleHAiOjQ5MDgyNTYwMjUuMDI4MTU0LCJzdWIiOiI5OTg1NzUiLCJzY29wZXMiOltdfQ.LlE_2FYMdB6RSri0RdTU4gcw96aOha7MgAVnRff_L4ahPXHGJuI6KP-qvsZMdUlvB8BjiKuu_TQl8q0fY3u1I4t-OrYKVe04WiLc23pu2py-svEF6IaAlTTpCsIe459dPBoE5mFPdJ9CoqMwfd2UFNRlXfgSIS1oII0BJplaz_2xFR5nGkh78HiE741o7qrekfdc1FTD2E0_X_wy0ef-ispQ2pVxiKoloPGmmd1nteBZmwsZVmkdJnuv4we_Th9eSvpKWVxMAd5doGcA-C-dz7pM5CbYhk7gKJF-ckIkeT1C88BMVciJtE3ycJUCZjcKgy81Jp-PtEIVdnhAFa8eadxArih2mGcPlPve2S8WE0zbDoNcHyTmqoULwTioXLS-IqHOTcgIuvQzdvHh2MSNekM-K_ur0to94IoLGZWxwKhMgZvGyGeR2SLa88TbHv99cn2i2rBV2QkuzU0pzennFtADoKBzcMLqEyoo4TYJzUuyYOg2h1_gj1jUXGIJgYSzPVs8g0Ofi4eNX2KrvnPsRIRml00Chgk8RjQ86aGO5gcuas3eX0vLsyLdxhYej2Ehqa4knoGEImrTmz7a-4Fj8O-hROLOrCRzsskhnJS8QKYJNPLuGqfbT9zbIo5lLdTOraO_1FLDQPA_hX7Va81QSkcoySMeNpl6QPffsf6ruPU';
  static const String _baseUrl = 'https://api.sender.net';

  /// Enhanced proposal email sending that handles both new and existing subscribers
  static Future<EmailResult> sendProposalEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
// print('📧 Enhanced email service: Sending proposal email to: $toEmail');
// print('📧 Proposal type: $proposalType, Value: R$proposalValue');

      // Step 1: Check if subscriber already exists in the group
      final isExistingSubscriber = await _checkSubscriberExists(toEmail);

      if (isExistingSubscriber) {
// print('📧 Existing subscriber detected - using direct email API');
        return await _sendDirectEmail(
          toEmail: toEmail,
          toName: toName,
          subject: subject,
          body: body,
          proposalType: proposalType,
          proposalValue: proposalValue,
        );
      } else {
// print('📧 New subscriber detected - using workflow method');
        return await _sendViaWorkflow(
          toEmail: toEmail,
          toName: toName,
          subject: subject,
          body: body,
          proposalType: proposalType,
          proposalValue: proposalValue,
        );
      }
    } catch (e) {
// print('📧 Error in enhanced email service: $e');
      return EmailResult(
        success: false,
        message: 'Error sending proposal email: $e',
      );
    }
  }

  /// Check if subscriber already exists in the Proposal group
  static Future<bool> _checkSubscriberExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v2/subscribers?email=$email'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscribers = data['data'] as List;

        if (subscribers.isNotEmpty) {
          final subscriber = subscribers.first;
          final groups = subscriber['subscriber_tags'] as List;

          // Check if subscriber is in Proposal group (boJV4X)
          for (var group in groups) {
            if (group['id'] == 'boJV4X') {
// print('📧 Subscriber $email already exists in Proposal group');
              return true;
            }
          }
        }
      }

// print('📧 Subscriber $email is new or not in Proposal group');
      return false;
    } catch (e) {
// print('📧 Error checking subscriber existence: $e');
      return false; // Assume new subscriber if check fails
    }
  }

  /// Send email via workflow (for new subscribers)
  static Future<EmailResult> _sendViaWorkflow({
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
      final requestBody = {
        'email': toEmail,
        'groups': ['boJV4X'], // Proposal group ID
        'fields': {
          'subject': subject,
          'message': body,
          'proposal_type': proposalType,
          'proposal_value': proposalValue,
          'client_name': toName,
        },
      };

// print('📧 Workflow request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

// print('📧 Workflow response status: ${response.statusCode}');
// print('📧 Workflow response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
// print('📧 ✅ Workflow email sent successfully! Response: $responseData');
        return EmailResult(
          success: true,
          messageId: responseData['id']?.toString() ?? 'unknown',
          message: 'Proposal email sent via workflow',
        );
      } else {
        final errorData = jsonDecode(response.body);
// print('📧 ❌ Workflow error: $errorData');
        return EmailResult(
          success: false,
          message:
              errorData['message'] ??
              'Failed to send proposal email via workflow',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
// print('📧 Error in workflow method: $e');
      return EmailResult(
        success: false,
        message: 'Error sending via workflow: $e',
      );
    }
  }

  /// Send direct email (for existing subscribers)
  static Future<EmailResult> _sendDirectEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
      // For now, we'll use the same method but with a different approach
      // In a real implementation, you would use Sender.net's direct email API
      // or a different email service for existing subscribers

// print('📧 Direct email method - updating subscriber fields');

      // Update subscriber fields to trigger a different workflow or use direct email
      final requestBody = {
        'email': toEmail,
        'groups': ['boJV4X'],
        'fields': {
          'subject': subject,
          'message': body,
          'proposal_type': proposalType,
          'proposal_value': proposalValue,
          'client_name': toName,
          'email_trigger': 'true', // Custom field to trigger email
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

// print('📧 Direct email response status: ${response.statusCode}');
// print('📧 Direct email response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
// print('📧 ✅ Direct email sent successfully! Response: $responseData');
        return EmailResult(
          success: true,
          messageId: responseData['id']?.toString() ?? 'unknown',
          message: 'Proposal email sent via direct method',
        );
      } else {
        final errorData = jsonDecode(response.body);
// print('📧 ❌ Direct email error: $errorData');
        return EmailResult(
          success: false,
          message: errorData['message'] ?? 'Failed to send direct email',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
// print('📧 Error in direct email method: $e');
      return EmailResult(
        success: false,
        message: 'Error sending direct email: $e',
      );
    }
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
