# DATA RETENTION AND DELETION POLICY

**Last Updated: October 2, 2025**  
**Policy Version:** 1.0

## PURPOSE

This Data Retention and Deletion Policy outlines how Impact Graphics ZA collects, retains, and deletes personal and business data in compliance with the Protection of Personal Information Act 4 of 2013 (POPIA) and other applicable South African laws.

## SCOPE

This policy applies to:
- All user data collected through the Impact Graphics ZA mobile app
- Data stored in Firebase Firestore, Firebase Storage, and other cloud services
- Data processed by third-party service providers
- All employees and contractors with access to user data

## 1. DATA CLASSIFICATION

### 1.1 Personal Information
**Definition:** Information that identifies or relates to an identifiable individual

**Includes:**
- Name, surname
- Email address
- Phone number
- ID numbers (if provided)
- Physical/postal address
- Profile pictures
- Biometric data (if applicable)
- IP addresses
- Device identifiers

### 1.2 Financial Information
**Definition:** Information related to financial transactions and payment

**Includes:**
- Transaction records
- Payment method details (tokenized)
- Wallet balance
- Invoice records
- Tax information
- Subscription history
- Refund records

### 1.3 Usage Data
**Definition:** Information about how users interact with the app

**Includes:**
- Login timestamps
- Feature usage statistics
- Navigation patterns
- Error logs
- Performance metrics
- Analytics data
- Ad interaction data

### 1.4 Communication Data
**Definition:** Information exchanged between users and Impact Graphics ZA

**Includes:**
- Chat messages
- Support tickets
- Email correspondence
- Consultation requests
- Feedback and reviews
- Push notification interactions

### 1.5 Business Data
**Definition:** Data related to services and orders

**Includes:**
- Order details
- Project descriptions
- Deliverables
- Portfolio items
- Service preferences
- Loyalty points
- Referral information

## 2. RETENTION PERIODS

### 2.1 Active User Accounts

| Data Type | Retention Period | Justification |
|-----------|------------------|---------------|
| **Account Information** | Duration of account + 30 days | Service provision |
| **Profile Data** | Duration of account + 30 days | Service provision |
| **Transaction History** | 7 years from transaction date | SARS requirement |
| **Invoices** | 7 years from issue date | Tax compliance |
| **Order Records** | 3 years from completion | Legal protection, disputes |
| **Chat Messages** | 2 years from last message | Support quality, disputes |
| **Support Tickets** | 3 years from closure | Service improvement |
| **Wallet Transactions** | 7 years from transaction | Financial compliance |
| **Usage Analytics** | 2 years from collection | Service improvement |
| **Error Logs** | 1 year from occurrence | Technical support |
| **Push Notification Tokens** | Duration of account + 30 days | Service provision |
| **Loyalty Points** | Duration of account | Program operation |
| **Referral Data** | 3 years from referral | Commission tracking |

### 2.2 Deleted/Inactive Accounts

| Data Type | Retention After Deletion | Justification |
|-----------|-------------------------|---------------|
| **Personal Information** | 30 days | Recovery period |
| **Transaction Records** | 7 years | Legal requirement |
| **Tax Documents** | 7 years | SARS compliance |
| **Dispute Records** | 3 years | Legal protection |
| **Fraud Prevention Data** | 5 years (anonymized) | Security |
| **Aggregated Analytics** | Indefinite (anonymized) | Business intelligence |

### 2.3 Special Retention Periods

**Inactive Accounts:**
- Accounts inactive for 3 years receive deletion warning
- Deleted after 3.5 years if no response
- Financial records retained per legal requirements

**Marketing Data:**
- Removed immediately upon opt-out
- Suppression list maintained to prevent re-contact

**Minors' Data:**
- Deleted immediately upon discovery
- No retention permitted

## 3. LEGAL AND REGULATORY REQUIREMENTS

### 3.1 South African Requirements

**SARS (South African Revenue Service):**
- Financial records: 7 years
- Tax invoices: 7 years
- Supporting documents: 5 years

**POPIA (Protection of Personal Information Act):**
- Data minimization principle
- Purpose limitation
- Retention limitation
- Subject to data subject rights

**Companies Act 71 of 2008:**
- Accounting records: 7 years
- Annual financial statements: 7 years

**Electronic Communications and Transactions Act:**
- Electronic records: 5 years minimum

### 3.2 Compliance Monitoring
- Annual policy review
- Quarterly retention audits
- Regular data cleanup procedures
- Staff training on compliance

## 4. DATA DELETION PROCEDURES

### 4.1 User-Initiated Deletion

**Process:**
1. User navigates to Settings > Account > Delete Account
2. System displays warning about:
   - Permanent deletion
   - Wallet balance forfeiture
   - Loss of loyalty points
   - Irreversible action
3. User confirms via password/OTP
4. System initiates deletion workflow
5. Confirmation email sent
6. 30-day recovery period begins

**What Happens During Deletion:**

**Immediate (Within 24 hours):**
- Account access disabled
- Profile hidden from system
- Active sessions terminated
- API tokens revoked
- Push notifications disabled

**Within 7 days:**
- Personal information anonymized
- Profile data removed
- Preferences deleted
- Device tokens removed
- Loyalty points deleted

**Within 30 days:**
- All deletable personal data removed
- Account marked as deleted
- Recovery no longer possible

**Retained (Legal Requirements):**
- Transaction records (7 years)
- Tax documents (7 years)
- Invoices (7 years)
- Anonymized fraud prevention data

### 4.2 Automated Deletion

**Scheduled Jobs:**
- Daily: Delete expired temporary data
- Weekly: Remove old error logs
- Monthly: Archive old transactions
- Quarterly: Purge deleted account data
- Annually: Review retention compliance

**Automated Deletion Triggers:**
- Account inactive > 3.5 years
- Email bounced > 6 months + no activity
- Deleted account > 30 days
- Expired promotional data
- Completed retention period

### 4.3 Manual Deletion

**Admin-Initiated:**
- Requires two-factor authentication
- Reason must be documented
- Audit log entry created
- Cannot delete if legal hold

**Bulk Deletion:**
- Requires Information Officer approval
- Automated script execution
- Verification before and after
- Full audit trail

## 5. DATA ANONYMIZATION

### 5.1 Anonymization Process

**When Applied:**
- After retention period expires
- For research and analytics
- When legal retention not required
- Upon user request (where applicable)

**Anonymization Techniques:**
- Personal identifiers removed
- Data aggregated
- Hashing of identifiable fields
- Generalization of specific data
- Randomization where appropriate

**Verification:**
- Re-identification attempt testing
- Regular anonymization audits
- Third-party assessment annually

### 5.2 Pseudonymization

**When Used:**
- During retention period
- For internal analytics
- Where full anonymization not possible
- Fraud prevention purposes

**Protection:**
- Encryption keys stored separately
- Limited access to mapping data
- Regular access audits

## 6. DATA BACKUP AND ARCHIVAL

### 6.1 Backup Retention

**Production Backups:**
- Daily backups: Retained 30 days
- Weekly backups: Retained 90 days
- Monthly backups: Retained 1 year
- Annual backups: Retained according to data retention policy

**Backup Deletion:**
- Follows same schedule as primary data
- Deleted account data removed from backups during next backup cycle
- Verification of deletion from all backup locations

### 6.2 Disaster Recovery

**Long-term Archival:**
- Financial records: 7 years
- Legal compliance documents: Per legal requirements
- Encrypted storage
- Access logging and monitoring

**Archive Deletion:**
- Automated deletion upon retention expiry
- Manual review for legal holds
- Verification and audit trail

## 7. THIRD-PARTY DATA PROCESSING

### 7.1 Service Provider Requirements

**Contractual Obligations:**
- Must comply with our retention policies
- Delete data upon request
- Provide deletion confirmation
- Regular compliance audits

**Key Providers:**

**Firebase/Google Cloud:**
- Firestore: User data, transactions, messages
- Storage: Profile images, portfolio items
- Authentication: User credentials
- **Retention:** According to our configuration

**Payment Processors:**
- Paystack: Transaction logs (their policy applies)
- Yoco: Transaction logs (their policy applies)
- **Our Retention:** 7 years for our records

**AdMob:**
- Advertising IDs and interaction data
- **Retention:** Per Google's policies

### 7.2 Data Processing Agreements

- Data Processing Agreements (DPAs) in place
- Regular compliance verification
- Incident response procedures
- Right to audit

## 8. DATA SUBJECT RIGHTS

### 8.1 Right to Access
**Response Time:** 30 days
**Process:**
1. Verify identity
2. Compile requested data
3. Provide in portable format
4. Explain retention periods

### 8.2 Right to Deletion
**Response Time:** 30 days for deletion, immediate for access blocking
**Exceptions:**
- Legal retention requirements
- Ongoing disputes
- Fraud investigation
- Legal holds

### 8.3 Right to Rectification
**Response Time:** 7 days
**Process:**
- Update incorrect information
- Notify relevant third parties
- Document changes

### 8.4 Right to Restriction
**Response Time:** 7 days
**Options:**
- Temporary processing suspension
- Storage only
- Limited access

## 9. SPECIAL CIRCUMSTANCES

### 9.1 Legal Holds

**When Applied:**
- Active litigation
- Regulatory investigation
- Court order
- Government request

**Process:**
- Immediate notification to IT team
- Retention period suspended
- Data preserved in separate location
- Access logged and monitored
- Hold released only by legal counsel

### 9.2 Deceased Users

**Policy:**
- Account deleted upon notification
- Exception for executor requests
- Requires death certificate
- Limited access to necessary records
- Financial records retained per legal requirements

### 9.3 Fraud or Security Incidents

**Extended Retention:**
- Fraud-related data: 5 years minimum
- Security incident logs: 3 years
- Investigation records: Until resolution + 3 years
- Anonymized after investigation complete

## 10. AUDIT AND COMPLIANCE

### 10.1 Internal Audits

**Frequency:** Quarterly
**Scope:**
- Retention period compliance
- Deletion process verification
- Backup retention review
- Third-party compliance check
- Policy adherence

**Documentation:**
- Audit findings report
- Non-compliance issues
- Remediation actions
- Timeline for corrections

### 10.2 External Audits

**Annual Review:**
- Independent third-party assessment
- POPIA compliance verification
- Retention policy effectiveness
- Recommendations for improvement

### 10.3 Metrics and Reporting

**KPIs Tracked:**
- Deletion request response time
- Automated deletion success rate
- Retention compliance percentage
- Backup restoration time
- Data breach incidents

**Reporting:**
- Monthly metrics to management
- Quarterly board reports
- Annual public transparency report

## 11. EMPLOYEE RESPONSIBILITIES

### 11.1 Data Handling

**Requirements:**
- Access only necessary data
- Follow retention guidelines
- Report non-compliance
- Complete annual training
- Sign confidentiality agreements

### 11.2 Departure Procedures

**When Employee Leaves:**
- Access revoked immediately
- Company devices returned
- Data deletion from personal devices
- Exit interview on data handling
- Confidentiality obligations continue

## 12. INCIDENT RESPONSE

### 12.1 Data Breach

**Immediate Actions:**
- Contain breach
- Assess scope and impact
- Notify affected users (within 72 hours)
- Notify Information Regulator
- Document incident

**Retention Impact:**
- Extend retention for affected data
- Preserve evidence
- Maintain incident logs

### 12.2 Unauthorized Deletion

**Response:**
- Investigate cause
- Restore from backup if available
- Assess impact
- Notify affected parties
- Improve controls

## 13. POLICY REVIEW AND UPDATES

### 13.1 Review Schedule

**Annual Review:**
- Regulatory changes assessment
- Technology updates consideration
- Business needs evaluation
- Feedback incorporation

**Triggers for Update:**
- New legal requirements
- Significant business changes
- Data breach learnings
- Technology migrations

### 13.2 Change Management

**Process:**
- Draft revised policy
- Legal review
- Stakeholder consultation
- Approval by management
- Staff training
- User communication
- Implementation monitoring

## 14. CONTACT INFORMATION

**Information Officer:**
- **Email:** privacy@impactgraphicsza.com
- **Phone:** [To be provided]

**Data Protection Queries:**
- **Email:** dataprotection@impactgraphicsza.com
- **Response Time:** 48 hours

**South African Information Regulator:**
- **Website:** www.justice.gov.za/inforeg
- **Email:** inforeg@justice.gov.za
- **Phone:** 012 406 4818

## 15. DEFINITIONS

| Term | Definition |
|------|------------|
| **Anonymization** | Process of removing personally identifiable information |
| **Archival** | Long-term storage of data for compliance |
| **Data Subject** | Individual to whom personal information relates |
| **Deletion** | Permanent removal of data from all systems |
| **Personal Information** | Information relating to identifiable person |
| **Processing** | Any operation performed on personal information |
| **Pseudonymization** | Replacing identifiers with artificial identifiers |
| **Retention Period** | Time data is kept before deletion |

## 16. POLICY ENFORCEMENT

**Non-Compliance Consequences:**
- Employee: Disciplinary action
- Contractor: Contract termination
- Partner: Agreement review/termination

**Reporting Violations:**
- Internal: Report to Information Officer
- External: Information Regulator complaint

---

**Policy Owner:** Information Officer  
**Approved By:** Management  
**Next Review Date:** October 2, 2026

**© 2025 Impact Graphics ZA. All rights reserved.**

**This policy complies with POPIA and applicable South African legislation.**

