#!/bin/bash

# Create All Required Firestore Indexes
# This script creates all the required composite indexes for the web app

echo "🔧 Creating All Required Firestore Indexes..."
echo "============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Indexes to Create:${NC}"
echo "1. Potential Clients Index"
echo "   - Collection: users"
echo "   - Fields: role (Ascending), createdAt (Descending)"
echo ""
echo "2. Marketing Packages Index"
echo "   - Collection Group: package_subscriptions"
echo "   - Fields: status (Ascending), createdAt (Ascending)"
echo ""

echo -e "${YELLOW}🌐 Opening Firebase Console for Index Creation...${NC}"
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

echo -e "${GREEN}1. Creating Potential Clients Index...${NC}"
open_url "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=ClZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3VzZXJzL2luZGV4ZXMvXxABGggKBHJvbGUQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"

echo ""
echo -e "${GREEN}2. Creating Marketing Packages Index...${NC}"
open_url "https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbRleGVzL18QARoKCgZzdGF0dXMQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"

echo ""
echo -e "${BLUE}📝 Steps to Complete:${NC}"
echo "1. Two Firebase Console tabs should open"
echo "2. In each tab, click 'Create Index' button"
echo "3. Wait for both indexes to build (1-2 minutes each)"
echo "4. Return to your web app and test both screens"
echo ""

echo -e "${GREEN}✅ Once both indexes are created:${NC}"
echo "   - Potential Clients list will load properly"
echo "   - Marketing Packages will show Active, Paused, and Cancelled packages"
echo ""

echo -e "${BLUE}🔍 Monitor Index Status:${NC}"
echo "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"
echo ""

echo -e "${YELLOW}🧪 Test Your App:${NC}"
echo "1. Go to: https://impact-graphics-za-266ef.web.app"
echo "2. Navigate to 'Potential Clients' - should show user list"
echo "3. Navigate to 'Marketing Packages' - should show packages by status"
echo ""

echo -e "${GREEN}🎉 All indexes will be created! Your web app should work perfectly!${NC}"

