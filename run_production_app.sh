#!/bin/bash

# Impact Graphics ZA - Production App Runner
# This script ensures a clean build every time

echo "🚀 Starting Impact Graphics ZA v2.0 - Production Version"
echo "📱 Features: Enhanced Splash Screen, Daily Ad Rewards, Priority Services"
echo ""

# Stop any existing Flutter processes
echo "🛑 Stopping existing Flutter processes..."
pkill -f flutter

# Clean everything
echo "🧹 Cleaning Flutter cache..."
flutter clean

# Remove build caches
echo "🗑️ Removing build caches..."
rm -rf ios/build android/build

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run the app with fresh build
echo "🏃 Running production app..."
flutter run --debug --no-hot

echo ""
echo "✅ Production app should now be running with all latest features!"
echo "🎯 Look for: Enhanced splash screen, daily ad rewards, priority services"
