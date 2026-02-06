import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiMGQ2OTFmMTJmYzFiMTdiNzk5MjAzZDkxZjNjZmI3MjlhMDAzMjkwNDQyMWExOGFkNTVlMDJiZmFiM2IzNjcyMzNlMzhmZjgwYjg1MjJkYmIiLCJpYXQiOjE3NTQ2NTYwMjUuMDMwMjk0LCJuYmYiOjE3NTQ2NTYwMjUuMDMwMjk2LCJleHAiOjQ5MDgyNTYwMjUuMDI4MTU0LCJzdWIiOiI5OTg1NzUiLCJzY29wZXMiOltdfQ.LlE_2FYMdB6RSri0RdTU4gcw96aOha7MgAVnRff_L4ahPXHGJuI6KP-qvsZMdUlvB8BjiKuu_TQl8q0fY3u1I4t-OrYKVe04WiLc23pu2py-svEF6IaAlTTpCsIe459dPBoE5mFPdJ9CoqMwfd2UFNRlXfgSIS1oII0BJplaz_2xFR5nGkh78HiE741o7qrekfdc1FTD2E0_X_wy0ef-ispQ2pVxiKoloPGmmd1nteBZmwsZVmkdJnuv4we_Th9eSvpKWVxMAd5doGcA-C-dz7pM5CbYhk7gKJF-ckIkeT1C88BMVciJtE3ycJUCZjcKgy81Jp-PtEIVdnhAFa8eadxArih2mGcPlPve2S8WE0zbDoNcHyTmqoULwTioXLS-IqHOTcgIuvQzdvHh2MSNekM-K_ur0to94IoLGZWxwKhMgZvGyGeR2SLa88TbHv99cn2i2rBV2QkuzU0pzennFtADoKBzcMLqEyoo4TYJzUuyYOg2h1_gj1jUXGIJgYSzPVs8g0Ofi4eNX2KrvnPsRIRml00Chgk8RjQ86aGO5gcuas3eX0vLsyLdxhYej2Ehqa4knoGEImrTmz7a-4Fj8O-hROLOrCRzsskhnJS8QKYJNPLuGqfbT9zbIo5lLdTOraO_1FLDQPA_hX7Va81QSkcoySMeNpl6QPffsf6ruPU';
  static const String _baseUrl = 'https://api.sender.net';

  /// Send proposal email using Sender.net API
  static Future<EmailResult> sendProposalEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
// print('📧 Sending proposal email to: $toEmail');
// print('📧 Proposal type: $proposalType, Value: R$proposalValue');

// print('📧 Using original email: $toEmail');

      // Create the request body with minimal required fields
      final requestBody = {
        'email': toEmail,
        'groups': ['boJV4X'], // New Proposal group ID
        'fields': {
          'subject': subject,
          'message': body,
          'proposal_type': proposalType,
          'proposal_value': proposalValue,
          'client_name': toName,
        },
      };

// print('📧 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

// print('📧 Sender.net response status: ${response.statusCode}');
// print('📧 Sender.net response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
// print('📧 ✅ Email sent successfully! Response: $responseData');
        return EmailResult(
          success: true,
          messageId: responseData['id']?.toString() ?? 'unknown',
          message: 'Proposal email sent successfully',
        );
      } else {
        final errorData = jsonDecode(response.body);
// print('📧 ❌ Sender.net error: $errorData');
        return EmailResult(
          success: false,
          message: errorData['message'] ?? 'Failed to send proposal email',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
// print('📧 Error sending proposal email: $e');
      return EmailResult(
        success: false,
        message: 'Error sending proposal email: $e',
      );
    }
  }

  /// Send appointment reminder email using Sender.net API
  static Future<EmailResult> sendAppointmentReminder({
    required String toEmail,
    required String toName,
    required String appointmentType,
    required String appointmentDate,
    required String appointmentTime,
    String? meetingLink,
  }) async {
    try {
// print('📧 Sending appointment reminder to: $toEmail');
// print(
//        '📧 Appointment type: $appointmentType, Date: $appointmentDate, Time: $appointmentTime',
//      );

      // Create appointment reminder message
      final messageBody =
          '''
Dear $toName,

This is a reminder about your upcoming appointment:

Appointment Type: $appointmentType
Date: $appointmentDate
Time: $appointmentTime${meetingLink != null ? '\nMeeting Link: $meetingLink' : ''}

Please let us know if you need to reschedule or have any questions.

Best regards,
Impact Graphics ZA Team
      ''';

      // Create the request body
      final requestBody = {
        'email': toEmail,
        'groups': ['boJV4X'], // Use new Proposal group
        'fields': {
          'subject': 'Appointment Reminder - $appointmentType',
          'message': messageBody,
          'appointment_type': appointmentType,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'meeting_link': meetingLink ?? '',
          'client_name': toName,
        },
      };

// print('📧 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/v2/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

// print('📧 Sender.net response status: ${response.statusCode}');
// print('📧 Sender.net response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
// print(
//          '📧 ✅ Appointment reminder sent successfully! Response: $responseData',
//        );
        return EmailResult(
          success: true,
          messageId: responseData['id']?.toString() ?? 'unknown',
          message: 'Appointment reminder sent successfully',
        );
      } else {
        final errorData = jsonDecode(response.body);
// print('📧 ❌ Sender.net error: $errorData');
        return EmailResult(
          success: false,
          message:
              errorData['message'] ?? 'Failed to send appointment reminder',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
// print('📧 Error sending appointment reminder: $e');
      return EmailResult(
        success: false,
        message: 'Error sending appointment reminder: $e',
      );
    }
  }

  /// Test Sender.net API connection
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
// print('🔍 Testing Sender.net API connection...');

      final groupsResponse = await http.get(
        Uri.parse('$_baseUrl/v2/groups'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

// print('🔍 Groups response status: ${groupsResponse.statusCode}');
// print('🔍 Groups response body: ${groupsResponse.body}');

      if (groupsResponse.statusCode == 200) {
        final groupsData = jsonDecode(groupsResponse.body);
        return {
          'success': true,
          'groups': groupsData,
          'message': 'API connection successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get groups: ${groupsResponse.statusCode}',
          'error': groupsResponse.body,
        };
      }
    } catch (e) {
// print('🔍 API connection test failed: $e');
      return {'success': false, 'message': 'API connection test failed: $e'};
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
