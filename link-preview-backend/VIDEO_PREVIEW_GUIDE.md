# Video Preview - Quick Start Guide 🎥

## ✅ Status: LIVE AND WORKING

**Service**: 🟢 Online  
**Port**: 3001  
**Video Support**: ✅ Enabled  

---

## 🎥 Supported Platforms

✅ **YouTube** (youtube.com, youtu.be)  
✅ **Vimeo** (vimeo.com)  
✅ **TikTok** (tiktok.com)  
✅ **Facebook** (facebook.com, fb.watch)  
✅ **Instagram** (instagram.com)  
✅ **Twitter/X** (twitter.com, x.com)  
✅ **Generic** (any site with og:video tags)  

---

## 🧪 Quick Test

### **Test YouTube Video**
```bash
curl -X POST http://localhost:3001/api/preview \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}' | jq .
```

### **Test All Platforms**
```bash
curl http://localhost:3001/api/test-video | jq .
```

---

## 📋 Response Format

### **Video Preview Response**
```json
{
  "title": "Video Title",
  "description": "Description",
  "image": "https://thumbnail.jpg",
  "video": "https://embed-url",
  "hasVideo": true,
  "videoPlatform": {
    "platform": "youtube",
    "videoId": "abc123",
    "embedUrl": "https://youtube.com/embed/abc123",
    "thumbnailUrl": "https://thumbnail.jpg"
  }
}
```

### **Key Fields**
- `hasVideo`: `true` if video detected
- `video`: Video or embed URL
- `videoPlatform`: Platform-specific info
- `image`: Thumbnail image

---

## 🎯 Integration

### **In Your App**

```dart
// Fetch preview
final preview = await fetchLinkPreview(url);

// Check if it's a video
if (preview['hasVideo'] == true) {
  // Show video player
  final platform = preview['videoPlatform']?['platform'];
  final embedUrl = preview['videoPlatform']?['embedUrl'];
  final thumbnail = preview['image'];
  
  // Display video preview with thumbnail and play button
}
```

---

## 📊 Examples

### **YouTube**
```
Input:  https://www.youtube.com/watch?v=dQw4w9WgXcQ
Output: hasVideo = true
        platform = "youtube"
        embedUrl = "https://www.youtube.com/embed/dQw4w9WgXcQ"
        thumbnail = "https://img.youtube.com/vi/.../maxresdefault.jpg"
```

### **Vimeo**
```
Input:  https://vimeo.com/148751763
Output: hasVideo = true
        platform = "vimeo"
        embedUrl = "https://player.vimeo.com/video/148751763"
```

### **Regular Website**
```
Input:  https://google.com
Output: hasVideo = false
        (standard link preview)
```

---

## 🔄 Service Management

### **Status**
```bash
pm2 status link-preview-backend
```

### **Restart** (apply updates)
```bash
pm2 restart link-preview-backend
```

### **Logs**
```bash
pm2 logs link-preview-backend
```

---

## 📞 Endpoints

- **Preview**: `POST /api/preview`
- **Multiple**: `POST /api/previews`
- **Test Videos**: `GET /api/test-video`
- **Health**: `GET /api/health`

---

**🎉 Video preview support is now live! Test it with any YouTube, Vimeo, or TikTok link!** 🎥✨🚀



