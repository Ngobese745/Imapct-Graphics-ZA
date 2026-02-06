#!/bin/bash

# Create Firestore Index for Potential Clients Query
# This script creates the required composite index for the users collection

echo "🔧 Creating Firestore Index for Potential Clients Query..."
echo "=================================================="

# The index we need to create:
# Collection: users
# Fields: role (Ascending), createdAt (Descending)

echo "📋 Index Details:"
echo "   Collection: users"
echo "   Field 1: role (Ascending)"
echo "   Field 2: createdAt (Descending)"
echo ""

echo "🌐 Opening Firebase Console to create index..."
echo ""

# Open the direct link to create the index
if command -v open &> /dev/null; then
    # macOS
    open "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=ClZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3VzZXJzL2luZGV4ZXMvXxABGggKBHJvbGUQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=ClZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3VzZXJzL2luZGV4ZXMvXxABGggKBHJvbGUQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
else
    echo "Please open this URL manually:"
    echo "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=ClZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3VzZXJzL2luZGV4ZXMvXxABGggKBHJvbGUQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
fi

echo ""
echo "📝 Steps to complete:"
echo "1. The Firebase Console should open automatically"
echo "2. Click 'Create Index' button"
echo "3. Wait for the index to build (1-2 minutes)"
echo "4. Return to your web app and refresh the Potential Clients page"
echo ""
echo "✅ Once the index is created, the Potential Clients list should load properly!"
echo ""
echo "🔍 You can monitor the index status at:"
echo "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"

