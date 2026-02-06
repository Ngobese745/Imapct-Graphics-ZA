# Link Preview Backend - Forever Running Service

## 🚀 Quick Start

### **Start the Service** (One Command)
```bash
./start-link-preview.sh
```

This will:
- ✅ Install PM2 if needed
- ✅ Install dependencies if needed
- ✅ Start the service
- ✅ Configure auto-restart
- ✅ Setup auto-start on boot
- ✅ Make it run forever!

---

## 📊 Management

### **Interactive Menu**
```bash
./manage-link-preview.sh
```

Shows menu with all options:
1. Start service
2. Stop service
3. Restart service
4. View status
5. View logs
6. Monitor service
7. Health check
8. Setup auto-start on boot
9. Remove service

### **Command Line**
```bash
./manage-link-preview.sh start      # Start
./manage-link-preview.sh stop       # Stop
./manage-link-preview.sh restart    # Restart
./manage-link-preview.sh status     # Status
./manage-link-preview.sh logs       # View logs
./manage-link-preview.sh monitor    # Live monitor
./manage-link-preview.sh health     # Health check
```

---

## 💚 Health Check

### **Check if Running**
```bash
curl http://localhost:3001/api/health
```

**Response**:
```json
{
  "status": "OK",
  "timestamp": "2025-10-19T12:00:00.000Z",
  "cacheSize": 42
}
```

---

## 📝 View Logs

### **Via Management Script**
```bash
./manage-link-preview.sh logs
```

### **Via PM2**
```bash
pm2 logs link-preview-backend
```

### **Via File**
```bash
tail -f logs/combined.log
```

---

## 🔄 Forever Running Features

### **Auto-Restart**
- ✅ Crashes: Automatically restarts within 4 seconds
- ✅ High memory: Restarts if using > 500MB
- ✅ Daily: Restarts at 3 AM every day

### **Auto-Start on Boot**
- ✅ System reboot: Automatically starts on boot
- ✅ PM2 resurrection: Restores saved process list

### **Monitoring**
- ✅ Health endpoint: `/api/health`
- ✅ PM2 monitoring: `pm2 monit`
- ✅ Complete logging: All activity logged

---

## 🆘 Troubleshooting

### **Service Won't Start**
```bash
# Check logs
./manage-link-preview.sh logs

# Check status
./manage-link-preview.sh status

# Try manual start
pm2 start ecosystem.config.js
```

### **Port Already in Use**
```bash
# Find what's using port 3001
lsof -i :3001

# Kill it
kill -9 <PID>

# Or change port in ecosystem.config.js
```

### **Not Auto-Starting on Boot**
```bash
# Re-setup
pm2 unstartup
pm2 startup
# Run the command it shows (may need sudo)
pm2 save
```

---

## 📚 Documentation

- **Full Setup Guide**: `LINK_PREVIEW_FOREVER_SETUP_COMPLETE.md`
- **This File**: `README.md`
- **Original Guide**: `START_LINK_PREVIEW_SERVER.md`

---

## ✅ Checklist

- [ ] Run `./start-link-preview.sh`
- [ ] Verify: `./manage-link-preview.sh status`
- [ ] Test health: `curl http://localhost:3001/api/health`
- [ ] View logs: `./manage-link-preview.sh logs`
- [ ] Reboot test: Reboot system and verify auto-start

---

## 🎉 You're All Set!

The link preview engine will now run forever with automatic recovery! 🚀✨🔄

**Need help?** Check `LINK_PREVIEW_FOREVER_SETUP_COMPLETE.md`



