import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  // Expansion state for legal documents
  bool _termsExpanded = false;
  bool _privacyExpanded = false;
  bool _cookieExpanded = false;
  bool _retentionExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'About Us',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo/Header
            Center(
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFF5F5F5)],
                        ),
                        borderRadius: BorderRadius.circular(70),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B0000).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF8B0000).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(62),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 5,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(62),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 124,
                            height: 124,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if logo fails to load
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8B0000),
                                      Color(0xFFA00000),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(62),
                                ),
                                child: const Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Company Name
            const Center(
              child: Text(
                'Impact Graphics ZA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            const Center(
              child: Text(
                'Professional Design Services',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 32),

            // About Section
            _buildSection(
              'About Us',
              'We are a leading design agency specializing in creating impactful visual solutions for businesses across South Africa. Our team of experienced designers and developers work tirelessly to bring your vision to life through innovative design, cutting-edge technology, and exceptional service.',
            ),

            // Services Section
            _buildSection(
              'Our Services',
              '• Branding & Identity Design\n'
                  '• Website Development\n'
                  '• Mobile App Design\n'
                  '• Marketing Materials\n'
                  '• Business Cards & Stationery\n'
                  '• Digital Marketing Solutions',
            ),

            // Mission Section
            _buildSection(
              'Our Mission',
              'To empower businesses with exceptional design solutions that drive growth, enhance brand recognition, and create lasting impressions in the digital landscape.',
            ),

            // How We Work Section
            _buildSection(
              'How We Work',
              '1. Browse our services and packages\n'
                  '2. Add items to cart and complete payment\n'
                  '3. Admin reviews and accepts your order\n'
                  '4. We deliver high-quality work on time\n'
                  '5. Revisions included as per your package',
            ),

            // Transparency & Trust Section
            _buildTransparencySection(),

            // Refund Policy Section
            _buildRefundPolicySection(),

            // Legal Documents Section
            _buildLegalSection(),

            // Contact Information
            _buildContactSection(),

            const SizedBox(height: 32),

            // Social Media Links
            _buildSocialSection(),

            const SizedBox(height: 32),

            // Copyright
            const Center(
              child: Text(
                '© 2025 Impact Graphics ZA. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparencySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFA00000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Our Commitment to Transparency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTransparencyPoint(
            '💳 Secure Payments',
            'All payments processed securely via Paystack',
          ),
          _buildTransparencyPoint(
            '📊 Track Everything',
            'View all transactions and invoices in your wallet',
          ),
          _buildTransparencyPoint(
            '💰 Fair Pricing',
            'Transparent pricing with no hidden fees',
          ),
          _buildTransparencyPoint(
            '🔄 Clear Refund Policy',
            '25% cancellation fee for in-progress orders, full refund for pending',
          ),
          _buildTransparencyPoint(
            '📧 Order Updates',
            'Real-time notifications for all order status changes',
          ),
          _buildTransparencyPoint(
            '🔒 Data Protection',
            'POPIA compliant - your data is secure',
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencyPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPolicySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.policy, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'Refund Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPolicyItem(
            '✅ Pending Orders',
            'Full refund (100%) if cancelled before admin acceptance',
          ),
          _buildPolicyItem(
            '⚠️ Accepted/In Progress Orders',
            '75% refund (25% cancellation fee applies)',
          ),
          _buildPolicyItem(
            '❌ Completed Orders',
            'No refund available once project is delivered',
          ),
          _buildPolicyItem(
            '💰 Refund Processing',
            'Automatic refund to wallet within seconds',
          ),
          _buildPolicyItem(
            '📧 Notifications',
            'Immediate notification with refund details',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All refunds are processed to your wallet balance immediately',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal & Privacy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 16),

          // Terms & Conditions Dropdown
          _buildLegalDropdown(
            title: 'Terms & Conditions',
            icon: Icons.description,
            isExpanded: _termsExpanded,
            onTap: () => setState(() => _termsExpanded = !_termsExpanded),
            content: _getTermsContent(),
          ),
          const SizedBox(height: 12),

          // Privacy Policy Dropdown
          _buildLegalDropdown(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip,
            isExpanded: _privacyExpanded,
            onTap: () => setState(() => _privacyExpanded = !_privacyExpanded),
            content: _getPrivacyContent(),
          ),
          const SizedBox(height: 12),

          // Cookie Policy Dropdown
          _buildLegalDropdown(
            title: 'Cookie Policy',
            icon: Icons.cookie,
            isExpanded: _cookieExpanded,
            onTap: () => setState(() => _cookieExpanded = !_cookieExpanded),
            content: _getCookieContent(),
          ),
          const SizedBox(height: 12),

          // Data Retention Policy Dropdown
          _buildLegalDropdown(
            title: 'Data Retention Policy',
            icon: Icons.storage,
            isExpanded: _retentionExpanded,
            onTap: () =>
                setState(() => _retentionExpanded = !_retentionExpanded),
            content: _getRetentionContent(),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'POPIA Compliant - Your data is protected under South African law',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDropdown({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF8B0000).withOpacity(0.5)
              : const Color(0xFF3A3A3A),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFF8B0000), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                ),
              ),
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTermsContent() {
    return '''
TERMS AND CONDITIONS

Last Updated: October 2, 2025

1. ACCEPTANCE OF TERMS
By using the IMPACT GRAPHICS ZA app, you agree to these Terms and Conditions. If you disagree, please do not use the App.

2. USER ACCOUNTS
• You must provide accurate information during registration
• You're responsible for maintaining account security
• Must be 18+ years old to create an account
• Notify us immediately of unauthorized access

3. SERVICES PROVIDED
• Logo Design, Branding, Marketing Materials
• Web Design, Social Media Graphics
• Print Design and more
• Project timelines are estimates
• Revisions provided per selected package

4. PAYMENTS & PRICING
• Prices in South African Rand (ZAR/R)
• Payment via Paystack, Wallet
• Non-refundable wallet credit (except as required by law)
• Ad rewards: Earn R1 per ad watched

5. REFUND POLICY
• Full refund if service not commenced
• 75% refund for in-progress orders (25% cancellation fee)
• No refund after project completion
• Refunds processed within seconds to wallet

6. ORDER CANCELLATION
• Pending orders: 100% refund
• Accepted/In Progress: 75% refund (25% fee)
• Completed orders: No cancellation allowed

7. INTELLECTUAL PROPERTY
• You retain ownership of content you provide
• Upon full payment, you receive ownership of final deliverables
• We retain right to display work in portfolio

8. USER CONDUCT
Prohibited activities include:
• Providing false information
• Harassment or abusive behavior
• Fraudulent payment activities
• Violating intellectual property rights

9. LIMITATION OF LIABILITY
• We're not liable for indirect or consequential damages
• Total liability limited to amount paid for specific service

10. GOVERNING LAW
• These Terms governed by South African law
• Disputes subject to South African jurisdiction

11. CONTACT
Email: support@impactgraphicsza.co.za
Phone: +27 68 367 5755

© 2025 Impact Graphics ZA. All rights reserved.
''';
  }

  String _getPrivacyContent() {
    return '''
PRIVACY POLICY

Last Updated: October 2, 2025

POPIA COMPLIANT - We protect your personal information in accordance with the Protection of Personal Information Act (POPIA).

1. INFORMATION WE COLLECT
• Personal: Name, email, phone, profile picture
• Payment: Transaction history, wallet balance (payment details tokenized)
• Usage: App activity, features used, error logs
• Device: Device type, OS version, unique identifiers
• Communications: Chat messages, support tickets

2. HOW WE USE YOUR INFORMATION
• Service delivery and order processing
• Customer support and communications
• App improvement and analytics
• Fraud prevention and security
• Marketing (with your consent)

3. DATA SHARING
We share data only with:
• Firebase (Google) - Authentication, storage, analytics
• Paystack - Payment processing
• AdMob - Advertisement delivery
• Legal requirements - When required by law

4. DATA RETENTION
• Active account data: While account exists
• Transaction records: 7 years (tax compliance)
• Chat messages: 2 years
• Support tickets: 3 years

5. YOUR RIGHTS (POPIA)
You have the right to:
• Access your personal information
• Correct inaccurate data
• Delete your account and data
• Restrict processing
• Object to marketing
• Data portability
• Lodge complaint with Information Regulator

6. DATA SECURITY
• Encryption in transit (TLS/SSL)
• Secure Firebase Authentication
• Access controls and monitoring
• Regular security audits

7. CHILDREN'S PRIVACY
• App not intended for users under 18
• We don't knowingly collect data from minors

8. CONTACT
Information Officer: privacy@impactgraphicsza.co.za
Data Requests: dataprotection@impactgraphicsza.co.za

Information Regulator:
Website: www.justice.gov.za/inforeg
Email: inforeg@justice.gov.za
Phone: 012 406 4818

© 2025 Impact Graphics ZA. POPIA Compliant.
''';
  }

  String _getCookieContent() {
    return '''
COOKIE AND TRACKING POLICY

Last Updated: October 2, 2025

1. WHAT WE TRACK
• Local Storage: App preferences, authentication
• Analytics: Firebase Analytics, usage patterns
• Advertising: AdMob interaction data
• Performance: Crash reports, error logs

2. TYPES OF TRACKING

Essential (Required):
• User authentication
• Security tokens
• App configuration

Analytics (Optional):
• Screen views and feature usage
• User behavior patterns
• Can be disabled in Settings

Advertising (Optional):
• Ad views and interactions
• Advertising ID
• Can opt-out in device settings

3. THIRD-PARTY TRACKING
• Firebase (Google) - Analytics, performance
• AdMob (Google) - Ad delivery
• Facebook SDK - If using Facebook login
• Payment processors - Transaction data

4. YOUR CHOICES
In-App Controls:
• Settings > Privacy > Analytics (Enable/Disable)
• Settings > Privacy > Personalized Ads (Enable/Disable)

Device Controls:
Android: Settings > Google > Ads > Opt out
iOS: Settings > Privacy > Advertising > Limit Ad Tracking

5. DATA RETENTION
• Analytics data: 2 months (raw), 14 months (aggregated)
• Crash reports: 90 days
• Ad interaction: Per AdMob policy
• Local preferences: Until app uninstall

6. CONTACT
Privacy questions: privacy@impactgraphicsza.co.za

© 2025 Impact Graphics ZA. POPIA Compliant.
''';
  }

  String _getRetentionContent() {
    return '''
DATA RETENTION POLICY

Last Updated: October 2, 2025

1. RETENTION PERIODS

Active Accounts:
• Account data: While account active
• Transactions: 7 years (SARS requirement)
• Chat messages: 2 years
• Support tickets: 3 years
• Analytics: 2 years

Deleted Accounts:
• Personal data: 30 days after deletion
• Transaction records: 7 years (legal requirement)
• Anonymized data: May be retained indefinitely

2. WHAT GETS DELETED
Upon account deletion:
• Profile information (30 days)
• Personal details (30 days)
• Wallet balance forfeited
• Loyalty points removed
• Chat history (30 days)
• Preferences (30 days)

3. WHAT WE RETAIN
Legal requirements:
• Transaction records: 7 years (SARS/tax compliance)
• Invoices: 7 years
• Tax documents: 7 years
• Fraud prevention data: 5 years (anonymized)

4. DELETION PROCESS
User-Initiated:
1. Settings > Account > Delete Account
2. Confirm deletion
3. 30-day recovery period
4. Permanent deletion after 30 days

Automatic:
• Inactive accounts: 3.5 years
• Expired data: Per schedule
• Completed retention periods

5. LEGAL BASIS
• SARS: 7-year tax record requirement
• POPIA: Data retention limitation
• Companies Act: 7-year accounting records
• Electronic Communications Act: 5-year minimum

6. YOUR RIGHTS
• Request data deletion anytime
• Access retention information
• Export your data
• Object to certain processing

7. CONTACT
Privacy: privacy@impactgraphicsza.co.za
Data Requests: dataprotection@impactgraphicsza.co.za

© 2025 Impact Graphics ZA. POPIA Compliant.
''';
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.email,
            'Email',
            'info@impactgraphicsza.co.za',
          ),
          _buildContactItem(Icons.phone, 'Phone', '+27 68 367 5755'),
          _buildContactItem(Icons.location_on, 'Location', 'South Africa'),
          _buildContactItem(
            Icons.access_time,
            'Business Hours',
            'Mon - Fri: 9:00 AM - 6:00 PM',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B0000), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect With Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSocialButton(
                Icons.message,
                'WhatsApp',
                () => _launchWhatsApp(),
              ),
              _buildSocialButton(Icons.email, 'Email', () => _launchEmail()),
              _buildSocialButton(Icons.phone, 'Call', () => _launchPhone()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B0000).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF8B0000), size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchWhatsApp() async {
    final phoneNumber = '+27683675755';
    final message = 'Hi! I would like to know more about your services.';
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Could not launch WhatsApp: $e');
    }
  }

  void _launchEmail() async {
    final email = 'info@impactgraphicsza.co.za';
    final subject = 'Inquiry from Impact Graphics App';
    final body =
        'Hello,\n\nI am interested in your services and would like to know more.\n\nBest regards,';
    final url =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Could not launch email: $e');
    }
  }

  void _launchPhone() async {
    final phoneNumber = '+27683675755';
    final url = 'tel:$phoneNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Could not launch phone: $e');
    }
  }
}
