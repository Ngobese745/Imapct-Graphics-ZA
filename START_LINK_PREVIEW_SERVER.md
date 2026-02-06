# Link Preview Server - Quick Start Guide

## What is this?
The link preview server enables automatic title and description autofill when admins add portfolio items by pasting URLs.

## How to Start the Server

### Option 1: Using Terminal
```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za/link-preview-backend"
npm start
```

### Option 2: Using the Start Script
```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za/link-preview-backend"
./start-server.sh
```

## How to Check if Server is Running

Run this command:
```bash
curl http://localhost:3001/api/health
```

If you see `{"status":"OK","timestamp":"...","cacheSize":0}`, the server is running! ✅

## Server Details
- **Port**: 3001
- **API Endpoint**: http://localhost:3001/api/preview
- **Health Check**: http://localhost:3001/api/health

## Common Issues

### Issue: "Cannot connect to server"
**Solution**: Start the server using the commands above

### Issue: "Port 3001 already in use"
**Solution**: Kill the existing process:
```bash
lsof -ti:3001 | xargs kill -9
```
Then start the server again.

### Issue: "npm command not found"
**Solution**: Install Node.js and npm from https://nodejs.org/

## How It Works

1. Admin pastes a URL in the "Add Portfolio Item" dialog
2. The app sends the URL to the backend server (localhost:3001)
3. The server fetches the webpage and extracts Open Graph metadata
4. The title and description fields are automatically filled
5. Results are cached for 30 minutes for faster subsequent requests

## Required Dependencies
The server uses:
- Express.js (web server)
- Axios (HTTP client)
- Cheerio (HTML parsing)
- CORS (cross-origin support)
- Rate limiting (security)

All dependencies are already installed in the `node_modules` folder.

## Stopping the Server

Press `Ctrl + C` in the terminal where the server is running.

Or kill the process:
```bash
lsof -ti:3001 | xargs kill -9
```

## Background Running (Optional)

To run the server in the background:
```bash
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za/link-preview-backend"
npm start &
```

To run it with automatic restart on crashes:
```bash
npm install -g pm2
pm2 start server.js --name link-preview
pm2 save
pm2 startup
```

## Testing the Server

Test with a sample URL:
```bash
curl -X POST http://localhost:3001/api/preview \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.facebook.com/share/v/1BRh4pVuTm/"}'
```

You should see JSON response with title, description, and image URL.

