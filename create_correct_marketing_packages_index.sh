#!/bin/bash

# Create the CORRECT Firestore Index for Marketing Packages Query
# This script creates the proper composite index for the package_subscriptions collection

echo "🔧 Creating CORRECT Firestore Index for Marketing Packages Query..."
echo "=================================================================="

# The CORRECT index we need to create:
# Collection: package_subscriptions (NOT Collection Group)
# Fields: status (Ascending), createdAt (Descending)

echo "📋 CORRECT Index Details:"
echo "   Collection: package_subscriptions"
echo "   Query Scope: Collection (NOT Collection Group)"
echo "   Field 1: status (Ascending)"
echo "   Field 2: createdAt (Descending)"
echo ""

echo "❌ Previous attempts may have been:"
echo "   - Collection Group instead of Collection"
echo "   - Wrong field order"
echo "   - Wrong field directions"
echo ""

echo "🌐 Opening Firebase Console to create the CORRECT index..."
echo ""

# Open the direct link to create the index
if command -v open &> /dev/null; then
    # macOS
    open "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"
else
    echo "Please open this URL manually:"
    echo "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"
fi

echo ""
echo "📝 Steps to create the CORRECT index:"
echo "1. Click 'Add index' button"
echo "2. Set Collection ID: package_subscriptions"
echo "3. Set Query scope: Collection (NOT Collection Group)"
echo "4. Add Field 1: status (Ascending)"
echo "5. Add Field 2: createdAt (Descending)"
echo "6. Click 'Create'"
echo ""

echo "🔍 Verify the index:"
echo "   - Collection ID: package_subscriptions"
echo "   - Query scope: Collection"
echo "   - Fields: status (Ascending), createdAt (Descending)"
echo "   - Status: Enabled (not Building)"
echo ""

echo "✅ After creating the correct index:"
echo "   - Marketing Packages screen will load without errors"
echo "   - All filters (Active, Paused, Cancelled, Expired) will work"
echo "   - Packages will be sorted by creation date (newest first)"
echo ""

echo "🧪 Test Steps:"
echo "1. Wait for index to build (1-2 minutes)"
echo "2. Hard refresh web app: Ctrl+Shift+R or Cmd+Shift+R"
echo "3. Go to Marketing Packages"
echo "4. Try all filter buttons"
echo "5. Verify packages load and are sorted correctly"

