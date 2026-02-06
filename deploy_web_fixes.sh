#!/bin/bash

# Web Deployment Script - Deploy Paystack and Ads Fixes
# This script builds and deploys the web app with fixes

set -e  # Exit on error

echo "🚀 Starting Web Deployment with Fixes..."
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Clean previous build
echo -e "${BLUE}📦 Step 1: Cleaning previous build...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${BLUE}📥 Step 2: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 3: Build for web
echo -e "${BLUE}🔨 Step 3: Building for web (production)...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
flutter build web --release
echo -e "${GREEN}✅ Web build complete${NC}"
echo ""

# Step 4: Deploy to Firebase Hosting
echo -e "${BLUE}🚀 Step 4: Deploying to Firebase Hosting...${NC}"
firebase deploy --only hosting
echo -e "${GREEN}✅ Deployment complete${NC}"
echo ""

# Success message
echo "=========================================="
echo -e "${GREEN}🎉 SUCCESS! Web app deployed with fixes!${NC}"
echo ""
echo -e "${BLUE}What was fixed:${NC}"
echo "  ✅ Payment authentication issue FIXED - logged-in users can now pay"
echo "  ✅ Paystack payment now works on web"
echo "  ✅ Gold Tier subscription flows fixed"
echo "  ✅ Ads properly disabled on web (no errors)"
echo "  ✅ Improved payment UX with clear instructions"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Visit your web app"
echo "  2. Test Paystack payment"
echo "  3. Check browser console for errors"
echo "  4. Verify all features work"
echo ""
echo -e "${YELLOW}Note: Allow popups in your browser for payment to work${NC}"
echo "=========================================="

