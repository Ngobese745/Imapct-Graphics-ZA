import 'dart:convert';
import 'package:http/http.dart' as http;

class SimplifiedEmailService {
  static const String _apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiMGQ2OTFmMTJmYzFiMTdiNzk5MjAzZDkxZjNjZmI3MjlhMDAzMjkwNDQyMWExOGFkNTVlMDJiZmFiM2IzNjcyMzNlMzhmZjgwYjg1MjJkYmIiLCJpYXQiOjE3NTQ2NTYwMjUuMDMwMjk0LCJuYmYiOjE3NTQ2NTYwMjUuMDMwMjk2LCJleHAiOjQ5MDgyNTYwMjUuMDI4MTU0LCJzdWIiOiI5OTg1NzUiLCJzY29wZXMiOltdfQ.LlE_2FYMdB6RSri0RdTU4gcw96aOha7MgAVnRff_L4ahPXHGJuI6KP-qvsZMdUlvB8BjiKuu_TQl8q0fY3u1I4t-OrYKVe04WiLc23pu2py-svEF6IaAlTTpCsIe459dPBoE5mFPdJ9CoqMwfd2UFNRlXfgSIS1oII0BJplaz_2xFR5nGkh78HiE741o7qrekfdc1FTD2E0_X_wy0ef-ispQ2pVxiKoloPGmmd1nteBZmwsZVmkdJnuv4we_Th9eSvpKWVxMAd5doGcA-C-dz7pM5CbYhk7gKJF-ckIkeT1C88BMVciJtE3ycJUCZjcKgy81Jp-PtEIVdnhAFa8eadxArih2mGcPlPve2S8WE0zbDoNcHyTmqoULwTioXLS-IqHOTcgIuvQzdvHh2MSNekM-K_ur0to94IoLGZWxwKhMgZvGyGeR2SLa88TbHv99cn2i2rBV2QkuzU0pzennFtADoKBzcMLqEyoo4TYJzUuyYOg2h1_gj1jUXGIJgYSzPVs8g0Ofi4eNX2KrvnPsRIRml00Chgk8RjQ86aGO5gcuas3eX0vLsyLdxhYej2Ehqa4knoGEImrTmz7a-4Fj8O-hROLOrCRzsskhnJS8QKYJNPLuGqfbT9zbIo5lLdTOraO_1FLDQPA_hX7Va81QSkcoySMeNpl6QPffsf6ruPU';
  static const String _baseUrl = 'https://api.sender.net';

  /// Simplified proposal email sending that works for all subscribers
  static Future<EmailResult> sendProposalEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
// print('📧 Simplified Email Service: Sending proposal email to: $toEmail');
// print('📧 Proposal type: $proposalType, Value: R$proposalValue');

      // Always add/update subscriber in Proposal group
      // This ensures they're in the group for manual campaigns
      final result = await _addSubscriberToGroup(
        email: toEmail,
        name: toName,
        subject: subject,
        body: body,
        proposalType: proposalType,
        proposalValue: proposalValue,
      );

      return result;
    } catch (e) {
// print('📧 Error in simplified email service: $e');
      return EmailResult(
        success: false,
        message: 'Error sending proposal email: $e',
      );
    }
  }

  /// Add subscriber to Proposal group with all necessary data
  static Future<EmailResult> _addSubscriberToGroup({
    required String email,
    required String name,
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
  }) async {
    try {
// print('📧 Adding subscriber $email to Proposal group...');

      final requestBody = {
        'email': email,
        'groups': ['boJV4X'], // Proposal group ID
        'fields': {
          'subject': subject,
          'message': body,
          'proposal_type': proposalType,
          'proposal_value': proposalValue,
          'client_name': name,
          'email_sent': 'true', // Flag to indicate email was sent
          'sent_date': DateTime.now().toIso8601String(),
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

// print('📧 Response status: ${response.statusCode}');
// print('📧 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
// print('📧 ✅ Subscriber added to Proposal group successfully!');

        return EmailResult(
          success: true,
          messageId: responseData['id']?.toString() ?? 'unknown',
          message:
              'Subscriber added to Proposal group - ready for manual campaign',
        );
      } else {
        final errorData = jsonDecode(response.body);
// print('📧 ❌ Error adding subscriber: $errorData');
        return EmailResult(
          success: false,
          message: errorData['message'] ?? 'Failed to add subscriber to group',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
// print('📧 Error adding subscriber to group: $e');
      return EmailResult(
        success: false,
        message: 'Error adding subscriber: $e',
      );
    }
  }

  /// Get all subscribers in Proposal group for manual campaigns
  static Future<List<Map<String, dynamic>>>
  getProposalGroupSubscribers() async {
    try {
// print('📧 Fetching subscribers from Proposal group...');

      final response = await http.get(
        Uri.parse('$_baseUrl/v2/groups/boJV4X/subscribers'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subscribers = data['data'] as List;
// print('📧 ✅ Found ${subscribers.length} subscribers in Proposal group');
        return subscribers.cast<Map<String, dynamic>>();
      } else {
// print('📧 ❌ Error fetching subscribers: ${response.body}');
        return [];
      }
    } catch (e) {
// print('📧 Error fetching subscribers: $e');
      return [];
    }
  }

  /// Generate HTML template for manual campaigns
  static String generateHtmlTemplate({
    required String subject,
    required String body,
    required String proposalType,
    required String proposalValue,
    required String clientName,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New Proposal - Impact Graphics ZA</title>
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

      <!-- Greeting -->
      <div style="margin-bottom: 30px;">
        <h2 style="color: #E53935; margin: 0 0 15px 0; font-size: 24px; font-weight: 600;">New Proposal Received</h2>
        <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0;">Hello <strong style="color: #E53935;">{{client_name}}</strong>,</p>
        <p style="color: #555555; font-size: 16px; line-height: 1.6; margin: 10px 0 0 0;">We're excited to present you with a customized proposal tailored to your needs.</p>
      </div>

      <!-- Message Section -->
      <div style="margin: 30px 0;">
        <h3 style="color: #E53935; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">💬 Project Message</h3>
        <div style="background-color: #ffffff; border: 2px solid #e9ecef; border-radius: 8px; padding: 20px; font-style: italic; color: #555555; line-height: 1.6;">
          "{{message}}"
        </div>
      </div>

      <!-- Call to Action with Reply Button -->
      <div style="text-align: center; margin: 40px 0;">
        <div style="background: linear-gradient(135deg, #E53935 0%, #171819 100%); border-radius: 8px; padding: 30px; margin: 20px 0;">
          <h3 style="color: #ffffff; margin: 0 0 15px 0; font-size: 20px; font-weight: 600;">Ready to Get Started?</h3>
          <p style="color: #fddede; margin: 0 0 25px 0; font-size: 16px;">We're excited to bring your vision to life with our creative expertise and professional approach.</p>
          
          <!-- Reply Button -->
          <a href="mailto:admin@impactgraphicsza.co.za?subject=Re: {{subject}}&body=Hi Impact Graphics ZA Team,%0D%0A%0D%0AI'm interested in your proposal.%0D%0A%0D%0AProposal Reference: {{subject}}%0D%0A%0D%0APlease let me know the next steps.%0D%0A%0D%0ABest regards,%0D%0A{{client_name}}" 
             style="display: inline-block; background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%); color: #E53935; text-decoration: none; padding: 15px 30px; border-radius: 8px; font-weight: 700; font-size: 16px; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 4px 12px rgba(0,0,0,0.2); transition: all 0.3s ease; border: 2px solid #ffffff; margin: 10px;">
            📧 Reply to This Proposal
          </a>
          
          <!-- Alternative Contact Button -->
          <a href="mailto:admin@impactgraphicsza.co.za?subject=Question about Proposal" 
             style="display: inline-block; background: transparent; color: #fddede; text-decoration: none; padding: 12px 25px; border-radius: 6px; font-weight: 600; font-size: 14px; border: 2px solid #fddede; margin: 10px; transition: all 0.3s ease;">
            💬 Ask Questions
          </a>
        </div>
      </div>

      <!-- Contact Information -->
      <div style="background-color: #f8f9fa; border-radius: 8px; padding: 25px; margin: 30px 0;">
        <h3 style="color: #E53935; margin: 0 0 20px 0; font-size: 18px; font-weight: 600;">📞 Get in Touch</h3>
        <div style="display: flex; flex-direction: column; gap: 10px;">
          <p style="color: #555555; margin: 0; font-size: 14px;"><strong style="color: #E53935;">Email:</strong> admin@impactgraphicsza.co.za</p>
          <p style="color: #555555; margin: 0; font-size: 14px;"><strong style="color: #E53935;">Website:</strong> www.impactgraphicsza.co.za</p>
          <p style="color: #555555; margin: 0; font-size: 14px;"><strong style="color: #E53935;">Response Time:</strong> Anytime</p>
        </div>
      </div>

    </div>

    <!-- Footer -->
    <div style="background-color: #171819; padding: 25px; text-align: center;">
      <p style="color: #fddede; margin: 0 0 10px 0; font-size: 16px; font-weight: 600;">Impact Graphics ZA</p>
      <p style="color: #9EA3A8; margin: 0; font-size: 14px;">Creative Solutions • Professional Results • South Africa</p>
      <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #2a2a2a;">
        <p style="color: #9EA3A8; margin: 0; font-size: 12px;">Design Inspires and Development Delivers.</p>
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
