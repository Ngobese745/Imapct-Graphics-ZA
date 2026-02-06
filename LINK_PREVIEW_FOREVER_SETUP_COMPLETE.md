# Link Preview Engine - Forever Running Setup Complete

## Overview
Configured the link preview backend to run forever using PM2 process manager with auto-restart, auto-recovery, and system boot integration.

## Date: October 19, 2025
## Status: ✅ COMPLETED AND READY TO START
## Location: `link-preview-backend/`

---

## 🎯 What Was Implemented

### **Forever Running Features**
- ✅ **Auto-restart on crash**: Service automatically restarts if it crashes
- ✅ **Auto-restart on reboot**: Service starts automatically when system boots
- ✅ **Memory management**: Auto-restart if memory exceeds 500MB
- ✅ **Daily restart**: Automatic restart at 3 AM daily (keeps it fresh)
- ✅ **Exponential backoff**: Smart restart delays to prevent boot loops
- ✅ **Logging**: Complete logging of all activity
- ✅ **Health monitoring**: Built-in health check endpoint

### **Management Tools**
- ✅ **Startup script**: One command to start and configure everything
- ✅ **Management script**: Easy commands for all operations
- ✅ **PM2 ecosystem**: Professional process management configuration
- ✅ **Interactive menu**: User-friendly interface for management

---

## 📁 Files Created

### **1. ecosystem.config.js**
**Purpose**: PM2 configuration file

**Key Features**:
```javascript
{
  name: 'link-preview-backend',
  autorestart: true,              // Auto-restart on crash
  max_memory_restart: '500M',     // Restart if memory > 500MB
  cron_restart: '0 3 * * *',      // Daily restart at 3 AM
  max_restarts: 10,               // Max 10 restarts in min_uptime window
  min_uptime: '10s',              // Must run 10s to be considered started
  restart_delay: 4000,            // 4s delay between restarts
  exp_backoff_restart_delay: 100  // Exponential backoff
}
```

### **2. start-link-preview.sh**
**Purpose**: One-command startup script

**What It Does**:
- Checks if PM2 is installed (installs if not)
- Checks if dependencies are installed (npm install if not)
- Stops any existing instance
- Starts the service with PM2
- Saves PM2 process list
- Sets up auto-start on system boot
- Shows status and useful commands

### **3. manage-link-preview.sh**
**Purpose**: Complete management interface

**Commands**:
```bash
./manage-link-preview.sh start      # Start the service
./manage-link-preview.sh stop       # Stop the service
./manage-link-preview.sh restart    # Restart the service
./manage-link-preview.sh status     # View status
./manage-link-preview.sh logs       # View logs
./manage-link-preview.sh monitor    # Live monitoring
./manage-link-preview.sh health     # Health check
./manage-link-preview.sh setup      # Setup auto-start
./manage-link-preview.sh delete     # Remove service
./manage-link-preview.sh            # Interactive menu
```

---

## 🚀 Quick Start

### **Step 1: Start the Service**
```bash
cd link-preview-backend
./start-link-preview.sh
```

This will:
1. Install PM2 if not installed
2. Install dependencies if needed
3. Start the service
4. Configure auto-restart
5. Setup auto-start on boot
6. Show status

### **Step 2: Verify It's Running**
```bash
./manage-link-preview.sh status
```

Or check health:
```bash
./manage-link-preview.sh health
```

Or visit:
```
http://localhost:3001/api/health
```

### **Step 3: View Logs** (Optional)
```bash
./manage-link-preview.sh logs
```

---

## 📊 Management Commands

### **Start Service**
```bash
cd link-preview-backend
./manage-link-preview.sh start
```

### **Stop Service**
```bash
./manage-link-preview.sh stop
```

### **Restart Service**
```bash
./manage-link-preview.sh restart
```

### **View Status**
```bash
./manage-link-preview.sh status
```

### **View Logs**
```bash
./manage-link-preview.sh logs
```

### **Live Monitoring**
```bash
./manage-link-preview.sh monitor
```

### **Health Check**
```bash
./manage-link-preview.sh health
```

### **Interactive Menu**
```bash
./manage-link-preview.sh
```

---

## 🔧 PM2 Commands (Advanced)

### **Direct PM2 Commands**
```bash
# View all PM2 processes
pm2 list

# View specific service status
pm2 status link-preview-backend

# View logs (streaming)
pm2 logs link-preview-backend

# View logs (last 100 lines)
pm2 logs link-preview-backend --lines 100

# Monitor all processes
pm2 monit

# Show detailed info
pm2 info link-preview-backend

# Restart service
pm2 restart link-preview-backend

# Stop service
pm2 stop link-preview-backend

# Delete service
pm2 delete link-preview-backend

# Save process list
pm2 save

# Resurrect saved processes
pm2 resurrect
```

---

## 🔄 Auto-Restart Behavior

### **When Does It Restart?**

| Trigger | Action | Description |
|---------|--------|-------------|
| **Crash** | Auto-restart | Immediately restarts on crash |
| **High Memory** | Auto-restart | Restarts if memory > 500MB |
| **Daily** | Auto-restart | Restarts every day at 3 AM |
| **System Boot** | Auto-start | Starts when system boots |
| **Manual Stop** | No restart | Stays stopped if manually stopped |

### **Restart Delays**
- **First restart**: 4 seconds
- **Second restart**: 4 seconds
- **Third restart**: ~4.1 seconds (exponential backoff)
- **Subsequent**: Increasing delays (exponential backoff)

### **Max Restarts**
- **Limit**: 10 restarts within 10 seconds
- **Protection**: Prevents boot loops
- **Recovery**: Resets after successful 10s uptime

---

## 📝 Logging

### **Log Files**
Located in `link-preview-backend/logs/`:

- **error.log**: Error messages only
- **out.log**: Standard output (console.log)
- **combined.log**: All logs combined

### **View Logs**
```bash
# Via management script
./manage-link-preview.sh logs

# Via PM2
pm2 logs link-preview-backend

# Via file
tail -f logs/combined.log
```

### **Log Rotation**
PM2 automatically manages log files. For custom rotation:
```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
```

---

## 💚 Health Monitoring

### **Health Check Endpoint**
```
GET http://localhost:3001/api/health
```

**Response**:
```json
{
  "status": "OK",
  "timestamp": "2025-10-19T12:00:00.000Z",
  "cacheSize": 42
}
```

### **Automated Health Checks**
You can set up automated health checks using cron:

```bash
# Add to crontab
*/5 * * * * curl -s http://localhost:3001/api/health || echo "Link Preview Service Down!" | mail -s "Alert" admin@example.com
```

---

## 🔒 System Integration

### **Auto-Start on Boot**

#### **Setup (Done by start-link-preview.sh)**
```bash
pm2 startup
# Follow the command it shows (may need sudo)
pm2 save
```

#### **Verify**
```bash
pm2 startup
```

#### **Disable Auto-Start**
```bash
pm2 unstartup
```

---

## 🎯 Production Checklist

### **Initial Setup**
- [ ] Run `./start-link-preview.sh`
- [ ] Verify service is running: `./manage-link-preview.sh status`
- [ ] Check health: `./manage-link-preview.sh health`
- [ ] View logs: `./manage-link-preview.sh logs`
- [ ] Test crash recovery: `pm2 restart link-preview-backend`

### **System Boot Test**
- [ ] Reboot system: `sudo reboot`
- [ ] After boot, check if service auto-started: `./manage-link-preview.sh status`
- [ ] Verify health: `./manage-link-preview.sh health`

### **Crash Recovery Test**
- [ ] Kill process: `pm2 kill link-preview-backend` (or crash it manually)
- [ ] Wait 5 seconds
- [ ] Check if auto-restarted: `./manage-link-preview.sh status`

### **Memory Test**
- [ ] Monitor memory: `./manage-link-preview.sh monitor`
- [ ] Verify memory usage stays reasonable
- [ ] Check logs for memory-related restarts

---

## 🔍 Troubleshooting

### **Service Won't Start**

**Check logs**:
```bash
./manage-link-preview.sh logs
```

**Check PM2 status**:
```bash
pm2 status
```

**Check if port 3001 is in use**:
```bash
lsof -i :3001
```

### **Service Keeps Crashing**

**View error logs**:
```bash
tail -f link-preview-backend/logs/error.log
```

**Check PM2 info**:
```bash
pm2 info link-preview-backend
```

**Disable auto-restart temporarily**:
```bash
pm2 stop link-preview-backend --no-autorestart
```

### **Service Not Auto-Starting on Boot**

**Re-setup startup**:
```bash
pm2 unstartup
pm2 startup
# Run the command it shows
pm2 save
```

**Check PM2 startup config**:
```bash
pm2 startup
```

### **High Memory Usage**

**Current limit**: 500MB

**Increase limit**:
Edit `ecosystem.config.js`:
```javascript
max_memory_restart: '1G'  // 1GB instead of 500MB
```

Then restart:
```bash
./manage-link-preview.sh restart
```

---

## 📈 Performance Monitoring

### **Real-Time Monitoring**
```bash
./manage-link-preview.sh monitor
```

Shows:
- CPU usage
- Memory usage
- Restart count
- Uptime
- Log output

### **Process Info**
```bash
pm2 info link-preview-backend
```

Shows:
- Status
- Uptime
- Restart count
- Memory usage
- CPU usage
- Process ID

### **List All Processes**
```bash
pm2 list
```

---

## 🎛️ Configuration

### **Change Port**
Edit `ecosystem.config.js`:
```javascript
env: {
  NODE_ENV: 'production',
  PORT: 3002  // Change port here
}
```

### **Change Restart Schedule**
Edit `ecosystem.config.js`:
```javascript
cron_restart: '0 2 * * *'  // 2 AM instead of 3 AM
// or
cron_restart: '0 */6 * * *'  // Every 6 hours
// or remove line to disable cron restart
```

### **Change Memory Limit**
Edit `ecosystem.config.js`:
```javascript
max_memory_restart: '1G'  // 1GB
```

### **Change Log Location**
Edit `ecosystem.config.js`:
```javascript
error_file: '/var/log/link-preview/error.log',
out_file: '/var/log/link-preview/out.log',
```

---

## 🔐 Security Considerations

### **Port Exposure**
- Default: `localhost:3001` (not exposed externally)
- **For external access**: Setup reverse proxy (nginx/apache)
- **Never** expose directly to internet without authentication

### **Rate Limiting**
- Built-in rate limiting: 100 requests per 15 minutes per IP
- Configured in `server.js`

### **CORS**
- Currently allows all origins
- For production, restrict in `server.js`:
```javascript
app.use(cors({
  origin: 'https://yourdomain.com'
}));
```

---

## 📞 Quick Reference

### **Start Everything**
```bash
cd link-preview-backend && ./start-link-preview.sh
```

### **Check Status**
```bash
cd link-preview-backend && ./manage-link-preview.sh status
```

### **View Logs**
```bash
cd link-preview-backend && ./manage-link-preview.sh logs
```

### **Restart**
```bash
cd link-preview-backend && ./manage-link-preview.sh restart
```

### **Health Check**
```bash
curl http://localhost:3001/api/health
```

---

## 🎉 Success Metrics

### **Forever Running**
- ✅ Auto-restarts on crash
- ✅ Auto-starts on system boot
- ✅ Daily automatic restarts
- ✅ Memory management
- ✅ Exponential backoff retry
- ✅ Complete logging
- ✅ Health monitoring

### **Easy Management**
- ✅ One-command startup
- ✅ Interactive management menu
- ✅ Simple status checks
- ✅ Easy log viewing
- ✅ Health check endpoint

---

## 🎊 Conclusion

The link preview engine is now configured to run forever! It will:

1. **Auto-restart** if it crashes
2. **Auto-start** when the system boots
3. **Restart daily** to keep it fresh
4. **Manage memory** automatically
5. **Log everything** for debugging
6. **Monitor health** continuously

Just run `./start-link-preview.sh` once, and it will keep running forever!

---

**Status**: ✅ **READY TO START**  
**Date**: October 19, 2025  
**Location**: `link-preview-backend/`  
**Command**: `./start-link-preview.sh`  
**Impact**: **Link preview engine will run forever with auto-recovery!** 🚀✨🔄



