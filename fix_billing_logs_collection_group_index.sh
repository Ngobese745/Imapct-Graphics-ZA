#!/bin/bash

# Fix Billing Logs Index - Create Collection Group Index
# The existing index is for Collection scope, but we need Collection Group scope

echo "🔧 Fixing Billing Logs Index - Collection Group Required..."
echo "========================================================="

echo "❌ Problem Identified:"
echo "   - Existing index: Collection scope (wrong)"
echo "   - Required index: Collection Group scope (correct)"
echo "   - The error shows 'index already exists' because Collection index exists"
echo "   - But Billing Logs needs Collection Group index"
echo ""

echo "📋 CORRECT Index Details:"
echo "   Collection Group: package_subscriptions"
echo "   Field 1: status (Ascending)"
echo "   Field 2: nextBillingDate (Ascending)"
echo "   Query Scope: Collection Group (NOT Collection)"
echo ""

echo "🌐 Opening Firebase Console to create Collection Group index..."
echo ""

# Open the direct link to create the Collection Group index
if command -v open &> /dev/null; then
    # macOS
    open "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoTCg9uZXh0QmlsbGluZ0RhdGUQARO MCghfX25hbWVfXXAB"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoTCg9uZXh0QmlsbGluZ0RhdGUQARO MCghfX25hbWVfXXAB"
else
    echo "Please open this URL manually:"
    echo "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoTCg9uZXh0QmlsbGluZ0RhdGUQARO MCghfX25hbWVfXXAB"
fi

echo ""
echo "📝 Steps to create the CORRECT Collection Group index:"
echo "1. The Firebase Console should open automatically"
echo "2. Click 'Create Index' button"
echo "3. IMPORTANT: Set Query scope to 'Collection group' (NOT Collection)"
echo "4. Collection ID: package_subscriptions"
echo "5. Field 1: status (Ascending)"
echo "6. Field 2: nextBillingDate (Ascending)"
echo "7. Click 'Create'"
echo ""

echo "🔍 Verify the index:"
echo "   - Collection ID: package_subscriptions"
echo "   - Query scope: Collection group (NOT Collection)"
echo "   - Fields: status (Ascending), nextBillingDate (Ascending)"
echo "   - Status: Enabled (not Building)"
echo ""

echo "✅ After creating the Collection Group index:"
echo "   - Billing Logs will show correct statistics"
echo "   - No more 'query requires an index' errors"
echo "   - Automated billing will function correctly"
echo "   - The existing Collection index won't conflict"
echo ""

echo "🧪 Test Steps:"
echo "1. Wait for Collection Group index to build (1-2 minutes)"
echo "2. Hard refresh web app: Ctrl+Shift+R or Cmd+Shift+R"
echo "3. Go to Billing Logs"
echo "4. Verify billing runs show correct data"
echo "5. Check that error messages are gone"
echo ""

echo "💡 Key Difference:"
echo "   - Collection: For queries within a single collection"
echo "   - Collection Group: For queries across multiple collections with same name"
echo "   - Billing Logs needs Collection Group scope!"

