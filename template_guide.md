# 🎨 IMPACT GRAPHICS ZA - EMAIL TEMPLATE GUIDE

## 📧 SUBJECT LINE
```
New Proposal: {{subject}} | Impact Graphics ZA
```

## 📄 SIMPLE TEXT TEMPLATE
```
═══════════════════════════════════════════════════════════════
                    IMPACT GRAPHICS ZA
              Creative Solutions • Professional Results
═══════════════════════════════════════════════════════════════

Hello {{client_name}},

Thank you for your interest in our services! We're excited to present 
you with a customized proposal tailored to your needs.

📋 PROPOSAL DETAILS
─────────────────────────────────────────────────────────────
Proposal Type: {{proposal_type}}
Investment:     R{{proposal_value}}
Reference:      {{subject}}

💬 PROJECT MESSAGE
─────────────────────────────────────────────────────────────
{{message}}

🚀 READY TO GET STARTED?
─────────────────────────────────────────────────────────────
We're excited to bring your vision to life with our creative 
expertise and professional approach.

📞 CONTACT INFORMATION
─────────────────────────────────────────────────────────────
Email:    admin@impactgraphicsza.co.za
Website:  www.impactgraphicsza.co.za
Response: Within 24 hours

Best regards,
The Impact Graphics ZA Team

═══════════════════════════════════════════════════════════════
Impact Graphics ZA | Creative Solutions • Professional Results
This is an automated message. Please do not reply to this email.
═══════════════════════════════════════════════════════════════
```

## 🎨 PROFESSIONAL HTML TEMPLATE
Use the `branded_template.html` file I created - it includes:
- Impact Graphics ZA branding
- Professional blue color scheme (#1e3c72, #2a5298)
- Responsive design
- Clean typography
- Call-to-action sections
- Contact information
- Professional footer

## 🔧 HOW TO IMPLEMENT IN SENDER.NET

### Step 1: Access Email Template
1. Go to Sender.net → Automations
2. Click on "Proposal" workflow
3. Click the envelope icon ("Send email" action)

### Step 2: Choose Template Type
- **For Simple Setup:** Use the text template above
- **For Professional Look:** Copy the HTML from `branded_template.html`

### Step 3: Configure Fields
Make sure these custom fields are available:
- `{{client_name}}` - Client's name
- `{{subject}}` - Proposal subject
- `{{message}}` - Proposal message
- `{{proposal_type}}` - Type of proposal
- `{{proposal_value}}` - Proposal value

### Step 4: Test the Template
1. Save the workflow
2. Run: `dart test_template.dart`
3. Check your email inbox!

## 🎯 BRAND ELEMENTS USED
- **Primary Color:** #1e3c72 (Dark Blue)
- **Secondary Color:** #2a5298 (Medium Blue)
- **Accent Color:** #28a745 (Green for pricing)
- **Typography:** Segoe UI, clean and professional
- **Logo:** "IMPACT GRAPHICS ZA" in bold
- **Tagline:** "Creative Solutions • Professional Results"

## 📱 RESPONSIVE FEATURES
- Mobile-friendly design
- Clean typography
- Professional spacing
- Clear call-to-action buttons
- Easy-to-read contact information

## ✨ PROFESSIONAL TOUCHES
- Gradient backgrounds
- Card-based layout
- Clear visual hierarchy
- Professional color scheme
- Branded footer
- Automated message disclaimer
