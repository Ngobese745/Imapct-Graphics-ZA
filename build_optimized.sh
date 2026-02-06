#!/bin/bash

# Optimized Flutter Web Build Script
# This script builds the Flutter web app with maximum performance optimizations

echo "🚀 Building Impact Graphics ZA Web App with Performance Optimizations..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build with optimizations
echo "⚡ Building with performance optimizations..."
flutter build web \
  --release \
  --web-renderer html \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --tree-shake-icons \
  --source-maps \
  --no-sound-null-safety

echo "✅ Build completed successfully!"
echo "📁 Build output: build/web/"
echo "🌐 Ready for deployment!"

# Display build size
echo "📊 Build size analysis:"
du -sh build/web/

echo ""
echo "🚀 Deploy with: firebase deploy --only hosting"
