#!/bin/bash

# Create All Remaining Required Firestore Indexes
# This script creates all the remaining composite indexes for the web app

echo "🔧 Creating All Remaining Firestore Indexes..."
echo "============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Indexes to Create:${NC}"
echo "1. ✅ Potential Clients Index (COMPLETED)"
echo "   - Collection: users"
echo "   - Fields: role (Ascending), createdAt (Descending)"
echo ""
echo "2. ✅ Marketing Packages Index (COMPLETED)"
echo "   - Collection: package_subscriptions"
echo "   - Fields: status (Ascending), createdAt (Descending)"
echo ""
echo "3. 🔧 Billing Logs Index (IN PROGRESS)"
echo "   - Collection Group: package_subscriptions"
echo "   - Fields: status (Ascending), nextBillingDate (Ascending)"
echo ""

echo -e "${YELLOW}🌐 Opening Firebase Console for Billing Logs Index...${NC}"
echo ""

# Function to open URL
open_url() {
    local url=$1
    if command -v open &> /dev/null; then
        # macOS
        open "$url"
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$url"
    else
        echo "Please open this URL manually:"
        echo "$url"
    fi
}

echo -e "${GREEN}Creating Billing Logs Index...${NC}"
open_url "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoTCg9uZXh0QmlsbGluZ0RhdGUQARO MCghfX25hbWVfXXAB"

echo ""
echo -e "${BLUE}📝 Steps to Complete:${NC}"
echo "1. Firebase Console should open automatically"
echo "2. Click 'Create Index' button"
echo "3. Wait for the index to build (1-2 minutes)"
echo "4. Return to your web app and test all screens"
echo ""

echo -e "${GREEN}✅ After Billing Logs Index is Created:${NC}"
echo "   - Billing Logs will show correct statistics"
echo "   - No more 'query requires an index' errors"
echo "   - Automated billing will function correctly"
echo "   - All admin screens will work properly"
echo ""

echo -e "${BLUE}🔍 Monitor Index Status:${NC}"
echo "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"
echo ""

echo -e "${YELLOW}🧪 Test Your App After Index Creation:${NC}"
echo "1. Go to: https://impact-graphics-za-266ef.web.app"
echo "2. Test Potential Clients - should show user list"
echo "3. Test Marketing Packages - should show packages by status"
echo "4. Test Billing Logs - should show correct billing statistics"
echo ""

echo -e "${GREEN}🎉 All indexes will be created! Your web app should work perfectly!${NC}"
echo ""
echo -e "${BLUE}📊 Summary of What Was Fixed:${NC}"
echo "✅ Payment authentication issues"
echo "✅ Potential Clients list loading"
echo "✅ Marketing Packages filtering"
echo "🔧 Billing Logs statistics (in progress)"
echo ""
echo -e "${YELLOW}Next: Create the Billing Logs index and test everything!${NC}"

