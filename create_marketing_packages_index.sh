#!/bin/bash

# Create Firestore Index for Marketing Packages Query
# This script creates the required composite index for the package_subscriptions collection group

echo "🔧 Creating Firestore Index for Marketing Packages Query..."
echo "========================================================"

# The index we need to create:
# Collection Group: package_subscriptions
# Fields: status (Ascending), createdAt (Ascending)

echo "📋 Index Details:"
echo "   Collection Group: package_subscriptions"
echo "   Field 1: status (Ascending)"
echo "   Field 2: createdAt (Ascending)"
echo ""

echo "🌐 Opening Firebase Console to create index..."
echo ""

# Open the direct link to create the index
if command -v open &> /dev/null; then
    # macOS
    open "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbRleGVzL18QARoKCgZzdGF0dXMQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbRleGVzL18QARoKCgZzdGF0dXMQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
else
    echo "Please open this URL manually:"
    echo "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbRleGVzL18QARoKCgZzdGF0dXMQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
fi

echo ""
echo "📝 Steps to complete:"
echo "1. The Firebase Console should open automatically"
echo "2. Click 'Create Index' button"
echo "3. Wait for the index to build (1-2 minutes)"
echo "4. Return to your web app and refresh the Marketing Packages page"
echo ""
echo "✅ Once the index is created, the Marketing Packages list should load properly!"
echo "   - Active packages will show"
echo "   - Paused packages will show"
echo "   - Cancelled packages will show"
echo ""
echo "🔍 You can monitor the index status at:"
echo "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"

