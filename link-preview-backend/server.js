const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const axios = require('axios');
const cheerio = require('cheerio');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Cache for storing preview data
const previewCache = new Map();
const CACHE_DURATION = 30 * 60 * 1000; // 30 minutes

// Helper function to detect video platform and extract video ID
function detectVideoPlatform(url) {
  const urlObj = new URL(url);
  const hostname = urlObj.hostname.toLowerCase();

  // YouTube
  if (hostname.includes('youtube.com') || hostname.includes('youtu.be')) {
    let videoId = null;
    if (hostname.includes('youtu.be')) {
      videoId = urlObj.pathname.slice(1);
    } else {
      videoId = urlObj.searchParams.get('v');
    }
    if (videoId) {
      return {
        platform: 'youtube',
        videoId: videoId,
        embedUrl: `https://www.youtube.com/embed/${videoId}`,
        thumbnailUrl: `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`
      };
    }
  }

  // Vimeo
  if (hostname.includes('vimeo.com')) {
    const videoId = urlObj.pathname.split('/').filter(p => p)[0];
    if (videoId) {
      return {
        platform: 'vimeo',
        videoId: videoId,
        embedUrl: `https://player.vimeo.com/video/${videoId}`,
        thumbnailUrl: null // Vimeo requires API call for thumbnail
      };
    }
  }

  // TikTok
  if (hostname.includes('tiktok.com')) {
    return {
      platform: 'tiktok',
      videoId: urlObj.pathname,
      embedUrl: url,
      thumbnailUrl: null
    };
  }

  // Facebook Video
  if (hostname.includes('facebook.com') || hostname.includes('fb.watch')) {
    return {
      platform: 'facebook',
      videoId: urlObj.pathname,
      embedUrl: url,
      thumbnailUrl: null
    };
  }

  // Instagram Video
  if (hostname.includes('instagram.com')) {
    return {
      platform: 'instagram',
      videoId: urlObj.pathname,
      embedUrl: url,
      thumbnailUrl: null
    };
  }

  // Twitter/X Video
  if (hostname.includes('twitter.com') || hostname.includes('x.com')) {
    return {
      platform: 'twitter',
      videoId: urlObj.pathname,
      embedUrl: url,
      thumbnailUrl: null
    };
  }

  return null;
}

// Function to extract metadata from URL
async function extractMetadata(url) {
  try {
    // Check cache first
    const cached = previewCache.get(url);
    if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.data;
    }

    // Check if it's a known video platform
    const videoPlatform = detectVideoPlatform(url);

    // Fetch the webpage
    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; LinkPreviewBot/1.0; +https://impactgraphicsza.co.za)'
      }
    });

    const $ = cheerio.load(response.data);

    // Extract Open Graph tags
    const title = $('meta[property="og:title"]').attr('content') ||
      $('meta[name="twitter:title"]').attr('content') ||
      $('title').text() ||
      'Untitled';

    const description = $('meta[property="og:description"]').attr('content') ||
      $('meta[name="twitter:description"]').attr('content') ||
      $('meta[name="description"]').attr('content') ||
      'No description available';

    const image = $('meta[property="og:image"]').attr('content') ||
      $('meta[name="twitter:image"]').attr('content') ||
      $('meta[name="twitter:image:src"]').attr('content') ||
      '';

    // Extract video metadata
    const video = $('meta[property="og:video"]').attr('content') ||
      $('meta[property="og:video:url"]').attr('content') ||
      $('meta[property="og:video:secure_url"]').attr('content') ||
      $('meta[name="twitter:player"]').attr('content') ||
      '';

    const videoType = $('meta[property="og:video:type"]').attr('content') ||
      $('meta[name="twitter:player:stream:content_type"]').attr('content') ||
      '';

    const videoWidth = $('meta[property="og:video:width"]').attr('content') ||
      $('meta[name="twitter:player:width"]').attr('content') ||
      '';

    const videoHeight = $('meta[property="og:video:height"]').attr('content') ||
      $('meta[name="twitter:player:height"]').attr('content') ||
      '';

    const siteName = $('meta[property="og:site_name"]').attr('content') ||
      new URL(url).hostname;

    const contentType = $('meta[property="og:type"]').attr('content') || 'website';

    // Clean up the image URL (make it absolute if it's relative)
    let imageUrl = image;
    if (imageUrl && !imageUrl.startsWith('http')) {
      const baseUrl = new URL(url).origin;
      imageUrl = imageUrl.startsWith('/') ? baseUrl + imageUrl : baseUrl + '/' + imageUrl;
    }

    // Clean up the video URL (make it absolute if it's relative)
    let videoUrl = video;
    if (videoUrl && !videoUrl.startsWith('http')) {
      const baseUrl = new URL(url).origin;
      videoUrl = videoUrl.startsWith('/') ? baseUrl + videoUrl : baseUrl + '/' + videoUrl;
    }

    // Merge video platform info if available
    const previewData = {
      title: title.trim(),
      description: description.trim(),
      image: imageUrl || (videoPlatform?.thumbnailUrl) || '',
      video: videoUrl || (videoPlatform?.embedUrl) || '',
      videoType: videoType,
      videoWidth: videoWidth ? parseInt(videoWidth) : null,
      videoHeight: videoHeight ? parseInt(videoHeight) : null,
      contentType: contentType,
      url: url,
      siteName: siteName,
      timestamp: Date.now(),
      hasVideo: !!videoUrl || !!videoPlatform,
      videoPlatform: videoPlatform ? {
        platform: videoPlatform.platform,
        videoId: videoPlatform.videoId,
        embedUrl: videoPlatform.embedUrl,
        thumbnailUrl: videoPlatform.thumbnailUrl
      } : null
    };

    // Cache the result
    previewCache.set(url, {
      data: previewData,
      timestamp: Date.now()
    });

    return previewData;

  } catch (error) {
    console.error('Error extracting metadata:', error.message);

    // Return fallback data
    return {
      title: 'Link Preview',
      description: 'Unable to load preview for this link',
      image: '',
      video: '',
      videoType: '',
      videoWidth: null,
      videoHeight: null,
      contentType: 'website',
      url: url,
      siteName: new URL(url).hostname,
      hasVideo: false,
      error: true
    };
  }
}

// API endpoint to get link preview
app.post('/api/preview', async (req, res) => {
  try {
    const { url } = req.body;

    if (!url) {
      return res.status(400).json({ error: 'URL is required' });
    }

    // Validate URL
    try {
      new URL(url);
    } catch (error) {
      return res.status(400).json({ error: 'Invalid URL format' });
    }

    const previewData = await extractMetadata(url);
    res.json(previewData);

  } catch (error) {
    console.error('Error in preview endpoint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// API endpoint to get multiple previews
app.post('/api/previews', async (req, res) => {
  try {
    const { urls } = req.body;

    if (!Array.isArray(urls) || urls.length === 0) {
      return res.status(400).json({ error: 'URLs array is required' });
    }

    const previews = await Promise.all(
      urls.map(url => extractMetadata(url))
    );

    res.json(previews);

  } catch (error) {
    console.error('Error in previews endpoint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    cacheSize: previewCache.size
  });
});

// Clear cache endpoint (for admin use)
app.post('/api/clear-cache', (req, res) => {
  previewCache.clear();
  res.json({ message: 'Cache cleared successfully' });
});

// Test video preview endpoint
app.get('/api/test-video', async (req, res) => {
  const testUrls = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://vimeo.com/148751763',
    'https://www.tiktok.com/@username/video/1234567890'
  ];

  try {
    const previews = await Promise.all(
      testUrls.map(url => extractMetadata(url))
    );

    res.json({
      message: 'Video preview test',
      testUrls: testUrls,
      previews: previews,
      videoSupport: {
        youtube: true,
        vimeo: true,
        tiktok: true,
        facebook: true,
        instagram: true,
        twitter: true,
        generic: true
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, () => {
  console.log(`🚀 Link Preview Backend running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔗 Preview endpoint: http://localhost:${PORT}/api/preview`);
  console.log(`🎥 Video support: YouTube, Vimeo, TikTok, Facebook, Instagram, Twitter`);
  console.log(`🧪 Test videos: http://localhost:${PORT}/api/test-video`);
});

module.exports = app;
