import axios from 'axios';
import * as functions from 'firebase-functions';

/**
 * Image Proxy Cloud Function
 * Proxies external images to bypass CORS restrictions
 * 
 * Usage: GET /imageProxy?url=https://external.com/image.jpg
 */
export const imageProxy = functions.https.onRequest(async (req, res) => {
    // Set CORS headers to allow requests from your app
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight request
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    // Only allow GET requests
    if (req.method !== 'GET') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }

    try {
        // Get the image URL from query parameter
        const imageUrl = req.query.url as string;

        if (!imageUrl) {
            res.status(400).json({ error: 'Missing url parameter' });
            return;
        }

        // Validate URL
        try {
            new URL(imageUrl);
        } catch (error) {
            res.status(400).json({ error: 'Invalid URL format' });
            return;
        }

        // Fetch the image from the external source
        const response = await axios.get(imageUrl, {
            responseType: 'arraybuffer',
            timeout: 15000,
            maxContentLength: 10 * 1024 * 1024, // 10MB max
            headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; ImpactGraphicsBot/1.0)',
            },
        });

        // Get content type from response
        const contentType = response.headers['content-type'] || 'image/jpeg';

        // Set appropriate headers
        res.set('Content-Type', contentType);
        res.set('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
        res.set('Access-Control-Allow-Origin', '*');

        // Send the image data
        res.send(Buffer.from(response.data));

        console.log(`✅ Proxied image: ${imageUrl}`);

    } catch (error: any) {
        console.error('❌ Error proxying image:', error.message);

        // Return error response
        if (error.response) {
            res.status(error.response.status).json({
                error: 'Failed to fetch image',
                status: error.response.status,
            });
        } else if (error.code === 'ECONNABORTED') {
            res.status(504).json({ error: 'Request timeout' });
        } else {
            res.status(500).json({ error: 'Internal server error' });
        }
    }
});

/**
 * Batch Image Proxy
 * Proxies multiple images at once
 * 
 * Usage: POST /batchImageProxy
 * Body: { urls: ["url1", "url2", ...] }
 */
export const batchImageProxy = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }

    try {
        const { urls } = req.body;

        if (!Array.isArray(urls)) {
            res.status(400).json({ error: 'urls must be an array' });
            return;
        }

        if (urls.length > 10) {
            res.status(400).json({ error: 'Maximum 10 URLs allowed' });
            return;
        }

        // Fetch all images
        const results = await Promise.allSettled(
            urls.map(async (url: string) => {
                try {
                    const response = await axios.get(url, {
                        responseType: 'arraybuffer',
                        timeout: 10000,
                        maxContentLength: 10 * 1024 * 1024,
                        headers: {
                            'User-Agent': 'Mozilla/5.0 (compatible; ImpactGraphicsBot/1.0)',
                        },
                    });

                    return {
                        url,
                        success: true,
                        contentType: response.headers['content-type'],
                        size: response.data.length,
                    };
                } catch (error: any) {
                    return {
                        url,
                        success: false,
                        error: error.message,
                    };
                }
            })
        );

        res.json({
            results: results.map((r) =>
                r.status === 'fulfilled' ? r.value : r.reason
            ),
        });

    } catch (error: any) {
        console.error('❌ Error in batch proxy:', error.message);
        res.status(500).json({ error: 'Internal server error' });
    }
});



