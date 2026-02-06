# Link Preview Backend - Quick Reference 🚀

## ⚡ One-Line Commands

### **Start Service**
```bash
cd link-preview-backend && ./start-link-preview.sh
```

### **Check Status**
```bash
pm2 status link-preview-backend
```

### **View Logs**
```bash
pm2 logs link-preview-backend
```

### **Restart**
```bash
pm2 restart link-preview-backend
```

### **Stop**
```bash
pm2 stop link-preview-backend
```

### **Health Check**
```bash
curl http://localhost:3001/api/health
```

---

## 📊 Service Status

**Currently**: 🟢 **ONLINE**  
**Port**: 3001  
**Health**: http://localhost:3001/api/health  

---

## 🔄 Forever Running

✅ Auto-restarts on crash  
✅ Auto-starts on system reboot  
✅ Restarts daily at 3 AM  
✅ Memory management (500MB limit)  

---

## 📝 Management

**Interactive Menu**:
```bash
./manage-link-preview.sh
```

**Direct Commands**:
```bash
./manage-link-preview.sh {start|stop|restart|status|logs|monitor|health}
```

---

## 🆘 Troubleshooting

**Not running?**
```bash
./manage-link-preview.sh start
```

**Crashed?**
```bash
pm2 logs link-preview-backend --err
```

**High memory?**
```bash
pm2 restart link-preview-backend
```

---

## 📞 Support

**Logs**: `link-preview-backend/logs/`  
**Docs**: `LINK_PREVIEW_PRODUCTION_READY.md`  
**Health**: http://localhost:3001/api/health  

---

**🎉 Service is running forever! No manual intervention needed!**



