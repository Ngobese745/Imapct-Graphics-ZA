#!/bin/bash

echo "🔍 MailerSend Extension Configuration Checker"
echo "=============================================="
echo ""

PROJECT_ID="impact-graphics-za-266ef"

echo "📱 Project: $PROJECT_ID"
echo ""

echo "📋 Step 1: Checking installed extensions..."
firebase ext:list --project $PROJECT_ID
echo ""

echo "📋 Step 2: Checking extension configuration..."
echo "Note: Extension configuration is stored in Firebase Secret Manager"
echo ""

echo "🔑 Step 3: Checking secrets..."
firebase functions:secrets:access MAILERSEND_API_KEY --project $PROJECT_ID 2>&1 || echo "⚠️  MAILERSEND_API_KEY secret not found or not accessible"
echo ""

echo "📜 Step 4: Checking recent Firebase Functions logs..."
echo "Looking for MailerSend extension activity..."
firebase functions:log --project $PROJECT_ID 2>&1 | grep -i "mailersend\|ext-mailersend\|email" | head -20
echo ""

echo "🔧 Step 5: Checking Firestore rules for emails collection..."
firebase firestore:rules --project $PROJECT_ID 2>&1 | grep -A 5 -B 5 "emails" || echo "No specific rules for 'emails' collection found"
echo ""

echo "📊 Step 6: Extension Status Summary"
echo "-----------------------------------"
firebase ext:list --project $PROJECT_ID 2>&1 | grep -A 1 "mailersend"
echo ""

echo "✅ Check completed!"
echo ""
echo "🔧 NEXT STEPS:"
echo "1. If extension is not listed, install it from Firebase Console"
echo "2. If extension is INACTIVE, check the configuration"
echo "3. If API key is missing, add it via Secret Manager"
echo "4. Check logs for 'ext-mailersend-email' function"
echo ""
echo "📖 To manually check extension configuration:"
echo "   Visit: https://console.firebase.google.com/project/$PROJECT_ID/extensions"
echo ""

