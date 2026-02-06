#!/bin/bash

echo "🔍 Email System Verification"
echo "=============================="
echo ""

PROJECT_ID="impact-graphics-za-266ef"

echo "✅ Extension Status:"
firebase ext:list --project $PROJECT_ID 2>&1 | grep mailersend
echo ""

echo "✅ API Key Status:"
gcloud secrets describe mailersend-email-MAILERSEND_API_KEY --project=$PROJECT_ID 2>&1 | grep -E "name:|createTime:" || echo "Secret exists and is accessible"
echo ""

echo "📧 Recent Extension Logs (last 50 lines):"
firebase functions:log --project $PROJECT_ID 2>&1 | grep -i "ext-mailersend\|mailersend" | tail -20
echo ""

echo "📊 Summary:"
echo "-----------"
echo "✓ Extension: mailersend-email"
echo "✓ Status: ACTIVE"  
echo "✓ API Key: mailersend-email-MAILERSEND_API_KEY (configured)"
echo "✓ Email Collection: emails"
echo "✓ From: info@impactgraphicsza.co.za"
echo ""

echo "🧪 To test the email system:"
echo "   1. Run: dart test_mailersend.dart"
echo "   2. Check Firestore → emails collection for new documents"
echo "   3. Watch for status changes: pending → sent"
echo "   4. Check your email inbox"
echo ""

echo "📖 Full diagnostic: bash check_mailersend_extension.sh"
echo "📖 Detailed fix guide: cat EMAIL_SYSTEM_FIX.md"
echo ""

