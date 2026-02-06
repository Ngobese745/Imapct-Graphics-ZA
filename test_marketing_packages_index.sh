#!/bin/bash

# Test Marketing Packages Index
# This script helps troubleshoot the Marketing Packages index issue

echo "🔍 Testing Marketing Packages Index..."
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Troubleshooting Steps:${NC}"
echo ""

echo -e "${YELLOW}1. Check Index Status:${NC}"
echo "   Go to: https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/indexes"
echo "   Look for: Collection Group 'package_subscriptions' with fields 'status' and 'createdAt'"
echo "   Status should be: 'Enabled' (not 'Building')"
echo ""

echo -e "${YELLOW}2. Clear Browser Cache:${NC}"
echo "   - Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)"
echo "   - Or open in incognito/private mode"
echo "   - Or clear site data in DevTools"
echo ""

echo -e "${YELLOW}3. Verify Index Type:${NC}"
echo "   The index MUST be for 'Collection Group' not 'Collection'"
echo "   Collection Group: package_subscriptions ✅"
echo "   Collection: package_subscriptions ❌"
echo ""

echo -e "${YELLOW}4. Test Web App:${NC}"
echo "   URL: https://impact-graphics-za-266ef.web.app"
echo "   Navigate to: Marketing Packages"
echo "   Try all filters: All Packages, Active, Paused, Cancelled"
echo ""

echo -e "${BLUE}🔧 If index is missing or wrong type:${NC}"
echo "   Create the correct index using this link:"
echo "   https://console.firebase.google.com/v1/r/project/impact-graphics-za-266ef/firestore/indexes?create_composite=CmZwcm9qZWN0cy9pbXBhY3QtZ3JhcGhpY3MtemEtMjY2ZWYvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3BhY2thZ2Vfc3Vic2NyaXB0aW9ucy9pbRleGVzL18QARoKCgZzdGF0dXMQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC"
echo ""

echo -e "${GREEN}✅ Expected Result:${NC}"
echo "   - Marketing Packages list should load without errors"
echo "   - All filters (Active, Paused, Cancelled) should work"
echo "   - No more 'query requires an index' errors"
echo ""

echo -e "${RED}❌ If still not working:${NC}"
echo "   - Check browser console for new error messages"
echo "   - Verify the index is for Collection Group, not Collection"
echo "   - Wait a few more minutes for index to fully build"
echo "   - Try a different browser or incognito mode"

