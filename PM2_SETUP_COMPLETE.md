# ✅ Link Preview Server - Permanent Setup Complete!

## 🎉 Server is Now Running Forever!

Your link preview server is now managed by **PM2** and will:
- ✅ Run permanently in the background
- ✅ Auto-restart if it crashes
- ✅ Run even after closing the terminal
- ✅ Survive system reboots (after final setup step below)

## 📊 Server Status

**Current Status**: 🟢 ONLINE  
**Port**: 3001  
**Process Manager**: PM2  
**Process Name**: `link-preview-server`

## 🔄 Final Setup Step (One-Time Only)

To make the server auto-start when you restart your computer, run this command **once**:

```bash
sudo env PATH=$PATH:/opt/homebrew/Cellar/node@20/20.19.4/bin /opt/homebrew/lib/node_modules/pm2/bin/pm2 startup launchd -u wonder --hp /Users/wonder
```

This will:
- Create a launch daemon for macOS
- Automatically start PM2 (and your server) on system boot
- Require your password (sudo)

## 📱 PM2 Commands Cheat Sheet

### Check Server Status
```bash
pm2 status
```

### View Server Logs (Real-time)
```bash
pm2 logs link-preview-server
```

### Restart Server
```bash
pm2 restart link-preview-server
```

### Stop Server
```bash
pm2 stop link-preview-server
```

### Start Server (if stopped)
```bash
pm2 start link-preview-server
```

### Monitor Server (Dashboard)
```bash
pm2 monit
```

### Server Information
```bash
pm2 info link-preview-server
```

### Delete Server from PM2
```bash
pm2 delete link-preview-server
```

## 🔧 Troubleshooting

### Server Not Responding?
```bash
# Check status
pm2 status

# View logs to see errors
pm2 logs link-preview-server --lines 50

# Restart the server
pm2 restart link-preview-server
```

### Port 3001 Already in Use?
```bash
# List PM2 processes
pm2 list

# Delete old process
pm2 delete link-preview-server

# Restart with PM2
cd "/Volumes/work/Impact Graphics ZA/impact_graphics_za/link-preview-backend"
pm2 start server.js --name link-preview-server
pm2 save
```

### Server Not Auto-Starting on Reboot?
Make sure you ran the startup command above (the sudo command).

Then verify:
```bash
pm2 startup
# Should show: "Platform launchd : script already setup"
```

## 📈 Monitoring & Logs

### Real-time Logs
```bash
pm2 logs link-preview-server
```

### View Last 100 Lines
```bash
pm2 logs link-preview-server --lines 100
```

### Clear Logs
```bash
pm2 flush
```

### Monitoring Dashboard
```bash
pm2 monit
```
(Press `Ctrl+C` to exit)

## 🔍 Health Check

Test if server is running:
```bash
curl http://localhost:3001/api/health
```

Expected response:
```json
{"status":"OK","timestamp":"2025-10-01T18:15:46.087Z","cacheSize":0}
```

## 🚀 Server Features

1. **Auto-restart**: If the server crashes, PM2 restarts it immediately
2. **Load balancing**: Can run multiple instances if needed
3. **Log management**: Automatic log rotation and storage
4. **Memory management**: Restarts if memory usage is too high
5. **Zero-downtime reload**: Update code without stopping the server

## 🔄 Updating the Server Code

If you make changes to `server.js`:

```bash
# Reload with zero downtime
pm2 reload link-preview-server

# OR restart (brief downtime)
pm2 restart link-preview-server
```

## 📦 PM2 Advanced Features

### Run Multiple Instances (Load Balancing)
```bash
pm2 scale link-preview-server 3  # Run 3 instances
```

### CPU/Memory Limits
```bash
pm2 start server.js --name link-preview-server --max-memory-restart 200M
```

### Auto-restart on File Changes (Development)
```bash
pm2 start server.js --name link-preview-server --watch
```

## 🛑 Completely Remove PM2 (if needed)

```bash
# Stop all processes
pm2 kill

# Remove PM2 globally
npm uninstall -g pm2

# Remove startup script
pm2 unstartup launchd
```

## 📞 Support

If you encounter issues:

1. Check logs: `pm2 logs link-preview-server`
2. Check status: `pm2 status`
3. Restart: `pm2 restart link-preview-server`
4. Health check: `curl http://localhost:3001/api/health`

## 🎯 What About Old Portfolio Items?

Old portfolio items don't have images because they were added before the server was running. 

**Solution**: I'll add a "Refresh" button in the admin dashboard to re-fetch metadata for old items.

See `PORTFOLIO_REFRESH_GUIDE.md` for instructions.

---

## ✅ Quick Reference Card

| Task | Command |
|------|---------|
| Status | `pm2 status` |
| Logs | `pm2 logs link-preview-server` |
| Restart | `pm2 restart link-preview-server` |
| Stop | `pm2 stop link-preview-server` |
| Start | `pm2 start link-preview-server` |
| Monitor | `pm2 monit` |
| Health | `curl http://localhost:3001/api/health` |

**Your server is now running 24/7 professionally! 🚀**

