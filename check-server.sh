#!/bin/bash

# Link Preview Server Health Check Script
echo "🔍 Checking Link Preview Server Status..."
echo ""

# Check if PM2 is running
if command -v pm2 &> /dev/null; then
    echo "✅ PM2 is installed"
    
    # Check if link-preview-server is running
    if pm2 status | grep -q "link-preview-server.*online"; then
        echo "✅ Link Preview Server is ONLINE"
        
        # Check server health
        if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
            echo "✅ Server is responding to health checks"
            
            # Get server details
            response=$(curl -s http://localhost:3001/api/health)
            echo ""
            echo "📊 Server Details:"
            echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
        else
            echo "⚠️  Server is running but not responding"
            echo "Try: pm2 restart link-preview-server"
        fi
    else
        echo "❌ Link Preview Server is NOT running"
        echo ""
        echo "🔧 To start the server, run:"
        echo "   pm2 start link-preview-server"
        echo ""
        echo "Or if not configured yet:"
        echo "   cd link-preview-backend && pm2 start server.js --name link-preview-server"
    fi
    
    echo ""
    echo "📱 PM2 Status:"
    pm2 status
else
    echo "❌ PM2 is not installed"
    echo ""
    echo "🔧 To install PM2, run:"
    echo "   npm install -g pm2"
fi

echo ""
echo "================================"
echo "Quick Commands:"
echo "================================"
echo "Status:   pm2 status"
echo "Logs:     pm2 logs link-preview-server"
echo "Restart:  pm2 restart link-preview-server"
echo "Monitor:  pm2 monit"
echo "================================"

