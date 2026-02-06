#!/bin/bash

# Force Fresh Install Script for Impact Graphics ZA v2.0
# This script ensures a completely fresh installation

echo "🚀 FORCE FRESH INSTALL - Impact Graphics ZA v2.0"
echo "📱 This will uninstall the old app and install the new version"
echo ""

# Stop all Flutter processes
echo "🛑 Stopping all Flutter processes..."
pkill -f flutter
sleep 2

# Clean everything
echo "🧹 Cleaning Flutter cache..."
flutter clean

# Remove build caches
echo "🗑️ Removing build caches..."
rm -rf ios/build android/build
rm -rf build/

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Uninstall app from device/simulator
echo "🗑️ Uninstalling old app from device..."
flutter clean
adb uninstall com.example.impact_graphics_za 2>/dev/null || echo "App not installed or using simulator"

# Build and install fresh
echo "🏗️ Building and installing fresh app..."
flutter run --debug --no-hot

echo ""
echo "✅ Fresh installation complete!"
echo "🎯 You should now see:"
echo "   - App title: 'Impact Graphics ZA v2.0'"
echo "   - Console message: 'STARTING IMPACT GRAPHICS ZA v2.0'"
echo "   - Enhanced splash screen"
echo "   - Daily ad rewards in wallet"
echo "   - Priority checkbox in graphics services"




