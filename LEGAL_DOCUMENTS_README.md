# LEGAL DOCUMENTS IMPLEMENTATION GUIDE

**Created: October 2, 2025**

## OVERVIEW

This guide explains the legal documents created for Impact Graphics ZA and how to implement them in your app.

## DOCUMENTS CREATED

### ✅ 1. Terms and Conditions
**File:** `TERMS_AND_CONDITIONS.md`

**Key Sections:**
- User accounts and registration
- Services provided
- Payment terms and refund policy
- Order process and cancellation
- Intellectual property rights
- Loyalty and referral programs
- User conduct
- Liability limitations
- Dispute resolution
- POPIA compliance

**Action Required:**
- [ ] Review and customize company contact information
- [ ] Update support email addresses
- [ ] Add business registration details
- [ ] Host on website: www.impactgraphicsza.com/terms
- [ ] Link from app: Settings > Legal > Terms & Conditions

---

### ✅ 2. Privacy Policy
**File:** `PRIVACY_POLICY.md`

**Key Sections:**
- Information collection practices
- How data is used
- Legal basis for processing (POPIA)
- Data sharing and disclosure
- Data retention periods
- Security measures
- User rights under POPIA
- Children's privacy
- International data transfers
- Contact information

**Action Required:**
- [ ] Appoint Information Officer (required by POPIA)
- [ ] Update Information Officer contact details
- [ ] Review third-party services listed
- [ ] Host on website: www.impactgraphicsza.com/privacy
- [ ] Link from app: Settings > Legal > Privacy Policy
- [ ] Display during signup (checkbox to accept)

---

### ✅ 3. Data Retention Policy
**File:** `DATA_RETENTION_POLICY.md`

**Key Sections:**
- Data classification
- Retention periods for different data types
- Legal and regulatory requirements
- Deletion procedures (user-initiated and automated)
- Data anonymization process
- Backup and archival policies
- Third-party data processing
- Data subject rights
- Audit and compliance

**Action Required:**
- [ ] Set up automated deletion jobs in Firebase
- [ ] Configure Firebase data retention settings
- [ ] Implement audit procedures
- [ ] Train staff on data handling
- [ ] Internal document (not required to be public, but available on request)

---

### ✅ 4. Cookie and Tracking Policy
**File:** `COOKIE_POLICY.md`

**Key Sections:**
- Types of tracking technologies used
- Essential vs. optional tracking
- Third-party tracking (Firebase, AdMob, Facebook)
- User choices and controls
- Device-level controls
- Data retention for tracking data
- POPIA compliance

**Action Required:**
- [ ] Verify all tracking technologies are listed
- [ ] Test opt-out controls work properly
- [ ] Host on website: www.impactgraphicsza.com/cookies
- [ ] Link from app: Settings > Legal > Cookie Policy
- [ ] Consider cookie consent on first launch (optional for mobile apps)

---

## IMPLEMENTATION CHECKLIST

### Phase 1: Document Review (Week 1)
- [ ] **Legal Review:** Have lawyer review all documents
- [ ] **Customization:** Update placeholder information:
  - [ ] Company registration details
  - [ ] Physical address
  - [ ] Contact phone numbers
  - [ ] Email addresses (support@, privacy@, dataprotection@)
  - [ ] Information Officer name and contact
- [ ] **Accuracy Check:** Verify all services and features mentioned are accurate
- [ ] **Translation:** Consider Afrikaans/Zulu translations if needed

### Phase 2: Website Hosting (Week 1-2)
- [ ] **Create Website Pages:**
  - [ ] www.impactgraphicsza.com/terms
  - [ ] www.impactgraphicsza.com/privacy
  - [ ] www.impactgraphicsza.com/cookies
  - [ ] www.impactgraphicsza.com/data-retention (optional)
- [ ] **Format for Web:** Convert markdown to HTML
- [ ] **Make Accessible:** Ensure documents are mobile-friendly
- [ ] **Version Control:** Date all documents clearly

### Phase 3: App Integration (Week 2)
- [ ] **Add Links to Settings:**
  ```dart
  Settings > Legal
    - Terms & Conditions (opens browser/WebView)
    - Privacy Policy (opens browser/WebView)
    - Cookie Policy (opens browser/WebView)
    - Data Retention (opens browser/WebView)
  ```

- [ ] **Signup Flow:**
  - [ ] Add checkboxes during registration:
    ```
    ☐ I agree to the Terms & Conditions
    ☐ I have read the Privacy Policy
    ```
  - [ ] Make Terms checkbox mandatory
  - [ ] Store consent timestamp in Firebase

- [ ] **In-App Display Option:**
  - Consider using WebView to display documents within app
  - Or open in external browser

### Phase 4: POPIA Compliance (Week 2-3)
- [ ] **Appoint Information Officer**
  - [ ] Register with Information Regulator
  - [ ] Update all documents with contact details

- [ ] **Set Up Email Addresses:**
  - [ ] support@impactgraphicsza.com
  - [ ] privacy@impactgraphicsza.com
  - [ ] dataprotection@impactgraphicsza.com

- [ ] **Implement Data Rights:**
  - [ ] Add "Data Rights Request" form in app
  - [ ] Set up process to handle:
    - Access requests
    - Deletion requests
    - Rectification requests
    - Data portability requests

- [ ] **Configure Firebase:**
  - [ ] Set retention periods for Firestore
  - [ ] Set retention for Firebase Storage
  - [ ] Enable audit logging

### Phase 5: Automated Processes (Week 3-4)
- [ ] **Deletion Automation:**
  - [ ] Implement 30-day deletion for deleted accounts
  - [ ] Create scheduled function for old data cleanup
  - [ ] Test deletion process thoroughly

- [ ] **Backup Management:**
  - [ ] Configure backup retention periods
  - [ ] Set up deletion from backups

- [ ] **Monitoring:**
  - [ ] Set up alerts for data breach
  - [ ] Configure audit logging
  - [ ] Create dashboard for compliance metrics

### Phase 6: User Communication (Week 4)
- [ ] **Notify Existing Users:**
  - [ ] Send email about new policies
  - [ ] In-app notification
  - [ ] Request re-consent if needed

- [ ] **Marketing Materials:**
  - [ ] Update App Store description
  - [ ] Update Google Play description
  - [ ] Mention POPIA compliance

### Phase 7: Training (Ongoing)
- [ ] **Staff Training:**
  - [ ] Train on data handling
  - [ ] Train on privacy rights
  - [ ] Train on incident response

- [ ] **Documentation:**
  - [ ] Create internal procedures
  - [ ] Document processes
  - [ ] Create response templates

---

## MANDATORY POPIA REQUIREMENTS

### ✅ You Must Have:
1. **Information Officer** - Appoint and register
2. **Privacy Policy** - Clear and accessible
3. **Lawful Processing Basis** - Consent, legitimate interest, etc.
4. **Data Subject Rights Process** - How users exercise rights
5. **Security Measures** - Protect personal information
6. **Retention Periods** - Define and enforce
7. **Breach Notification Process** - Within 72 hours
8. **Third-Party Agreements** - Data Processing Agreements with providers

### ⚠️ Penalties for Non-Compliance:
- Up to R10 million fine
- Up to 10 years imprisonment
- Civil claims from data subjects
- Reputational damage

---

## CONTACT INFORMATION TO UPDATE

Replace these placeholders throughout all documents:

### Company Details:
```
Company Name: Impact Graphics ZA
Business Registration: [YOUR REGISTRATION NUMBER]
VAT Number: [IF APPLICABLE]
Physical Address: [YOUR ADDRESS]
Postal Address: [YOUR POSTAL ADDRESS]
```

### Contact Emails:
```
General: support@impactgraphicsza.com
Privacy: privacy@impactgraphicsza.com
Data Protection: dataprotection@impactgraphicsza.com
Opt-Out: optout@impactgraphicsza.com
```

### Information Officer:
```
Name: [OFFICER NAME]
Email: privacy@impactgraphicsza.com
Phone: [PHONE NUMBER]
Registration: [REGULATOR REGISTRATION NUMBER]
```

---

## TECHNICAL IMPLEMENTATION

### 1. Add Legal Documents Screen

Create `lib/screens/legal_documents_screen.dart`:

```dart
class LegalDocumentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Legal')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Terms & Conditions'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _openDocument(context, 'terms'),
          ),
          ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _openDocument(context, 'privacy'),
          ),
          ListTile(
            title: Text('Cookie Policy'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _openDocument(context, 'cookies'),
          ),
          ListTile(
            title: Text('Data Retention Policy'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _openDocument(context, 'retention'),
          ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context, String doc) {
    final urls = {
      'terms': 'https://www.impactgraphicsza.com/terms',
      'privacy': 'https://www.impactgraphicsza.com/privacy',
      'cookies': 'https://www.impactgraphicsza.com/cookies',
      'retention': 'https://www.impactgraphicsza.com/data-retention',
    };
    
    launchUrl(Uri.parse(urls[doc]!));
    // Or use WebView for in-app display
  }
}
```

### 2. Add Consent Checkboxes to Signup

Update `signup_screen.dart`:

```dart
bool _acceptedTerms = false;
bool _readPrivacy = false;

// In form:
CheckboxListTile(
  title: RichText(
    text: TextSpan(
      text: 'I agree to the ',
      children: [
        TextSpan(
          text: 'Terms & Conditions',
          style: TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openTerms(),
        ),
      ],
    ),
  ),
  value: _acceptedTerms,
  onChanged: (val) => setState(() => _acceptedTerms = val!),
),

// Validation:
if (!_acceptedTerms) {
  showError('Please accept Terms & Conditions');
  return;
}

// Store consent:
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .update({
  'consents': {
    'termsAcceptedAt': FieldValue.serverTimestamp(),
    'privacyReadAt': FieldValue.serverTimestamp(),
  }
});
```

---

## MAINTENANCE

### Regular Reviews:
- **Quarterly:** Review for accuracy
- **Annually:** Full legal review
- **When:** Making significant app changes
- **When:** Laws change

### Version Control:
- Date each update clearly
- Keep archive of previous versions
- Notify users of significant changes
- Document what changed and why

---

## QUESTIONS?

For legal advice, consult with a South African attorney specializing in:
- Information Technology Law
- Privacy and Data Protection (POPIA)
- Intellectual Property
- E-commerce

**Recommended:** Have these documents reviewed by a lawyer before publishing.

---

## ADDITIONAL RESOURCES

**POPIA Resources:**
- Information Regulator: www.justice.gov.za/inforeg
- POPIA Full Text: www.gov.za/documents/protection-personal-information-act
- POPIA Code of Conduct: Check Information Regulator website

**Firebase Resources:**
- Firebase GDPR/POPIA Guide: firebase.google.com/support/privacy
- Data Deletion Guide: firebase.google.com/support/privacy/manage-data

**Payment Processor Compliance:**
- Paystack Privacy: paystack.com/privacy
- Yoco Privacy: yoco.com/za/privacy

---

**Created by:** AI Assistant  
**Date:** October 2, 2025  
**Status:** ✅ Ready for Review  
**Next Step:** Legal review and customization


