#!/bin/bash

# Link Preview Backend - Startup Script
# This script ensures the link preview backend runs forever using PM2

echo "======================================================"
echo "Starting Link Preview Backend with PM2"
echo "======================================================"
echo ""

# Navigate to the link-preview-backend directory
cd "$(dirname "$0")"

# Create logs directory if it doesn't exist
mkdir -p logs

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "❌ PM2 is not installed!"
    echo "Installing PM2 globally..."
    npm install -g pm2
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install PM2"
        echo "Please run: sudo npm install -g pm2"
        exit 1
    fi
    echo "✅ PM2 installed successfully"
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed"
fi

# Stop existing instance if running
echo "🔄 Stopping any existing instance..."
pm2 stop link-preview-backend 2>/dev/null || true
pm2 delete link-preview-backend 2>/dev/null || true

# Start the application with PM2
echo "🚀 Starting Link Preview Backend..."
pm2 start ecosystem.config.js

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================================"
    echo "✅ Link Preview Backend started successfully!"
    echo "======================================================"
    echo ""
    echo "📊 Process Status:"
    pm2 status link-preview-backend
    echo ""
    echo "📝 Useful Commands:"
    echo "  - View logs:      pm2 logs link-preview-backend"
    echo "  - Stop service:   pm2 stop link-preview-backend"
    echo "  - Restart:        pm2 restart link-preview-backend"
    echo "  - Status:         pm2 status"
    echo "  - Monitor:        pm2 monit"
    echo ""
    echo "🔗 Service URL: http://localhost:3001"
    echo "💚 Health Check: http://localhost:3001/api/health"
    echo ""
    
    # Save PM2 process list
    echo "💾 Saving PM2 process list..."
    pm2 save
    
    # Setup PM2 to start on system boot
    echo "🔧 Setting up PM2 startup script..."
    pm2 startup | tail -n 1 | sh 2>/dev/null || echo "⚠️  PM2 startup may require sudo. Run: pm2 startup"
    
    echo ""
    echo "======================================================"
    echo "🎉 Setup Complete!"
    echo "======================================================"
    echo "The Link Preview Backend will now:"
    echo "  ✅ Auto-restart on crashes"
    echo "  ✅ Auto-restart on system reboot"
    echo "  ✅ Run forever in the background"
    echo "  ✅ Log all activity to ./logs/"
    echo ""
else
    echo ""
    echo "❌ Failed to start Link Preview Backend"
    echo "Check the logs for more information:"
    echo "  pm2 logs link-preview-backend"
    exit 1
fi



