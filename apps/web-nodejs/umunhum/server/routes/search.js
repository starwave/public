/**
 * Search routes for Umunhum
 */
import express from 'express';
import { upload } from '../middleware/upload.js';
import { searchSimilarImages } from '../services/qdrant.js';
import { embedImage, isScanInProgress } from '../services/embedder.js';
import fs from 'fs/promises';
import axios from 'axios';

const router = express.Router();

/**
 * POST /api/search/similar
 * Upload an image and get top K similar images
 */
router.post('/similar', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    // Check if scan is in progress (only for API mode, not needed for local CPU mode)
    const embedMode = process.env.EMBED_MODE || 'api';
    if (embedMode === 'api') {
      const scanStatus = await isScanInProgress();
      if (scanStatus.scanning) {
        // Clean up uploaded file
        await fs.unlink(req.file.path);
        return res.status(503).json({
          error: 'Service temporarily unavailable',
          message: `A scan is currently in progress (${scanStatus.progress.toFixed(1)}% complete, ${scanStatus.processed}/${scanStatus.totalImages} images). Please try again later.`,
          scanning: true,
          progress: scanStatus.progress
        });
      }
    } else {
      console.log('[LOCAL CPU MODE] Skipping scan check - no memory conflict');
    }

    console.log(`Received image: ${req.file.originalname} (${req.file.size} bytes)`);

    // Generate embedding for uploaded image
    const embedding = await embedImage(req.file.path);

    if (!embedding) {
      await fs.unlink(req.file.path);
      return res.status(500).json({ error: 'Failed to generate embedding' });
    }

    // Search Qdrant for similar images
    const topK = parseInt(req.query.top_k || process.env.TOP_K || '5');
    const results = await searchSimilarImages(embedding, topK);

    // Clean up uploaded file
    await fs.unlink(req.file.path);

    res.json({
      success: true,
      results: results.map(r => ({
        id: r.id,
        score: r.score,
        path: r.payload.path,
        pid: r.payload.pid,
        payload: r.payload
      }))
    });

  } catch (error) {
    console.error('Search error:', error);
    // Try to clean up file if it exists
    if (req.file) {
      try {
        await fs.unlink(req.file.path);
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    res.status(500).json({
      error: 'Search failed',
      message: error.message
    });
  }
});

/**
 * GET /api/search/status
 * Get system status
 */
router.get('/status', async (req, res) => {
  try {
    const pradoUrl = process.env.PRADO_API_URL;
    const qdrantHost = process.env.QDRANT_HOST;
    const qdrantPort = process.env.QDRANT_PORT;

    const checks = {
      umunhum: 'ok',
      prado: 'unknown',
      qdrant: 'unknown'
    };

    // Check Prado
    if (pradoUrl) {
      try {
        await axios.get(`${pradoUrl}/health`, { timeout: 2000 });
        checks.prado = 'ok';
      } catch (e) {
        checks.prado = 'error';
      }
    }

    // Check Qdrant
    try {
      await axios.get(`http://${qdrantHost}:${qdrantPort}/health`, { timeout: 2000 });
      checks.qdrant = 'ok';
    } catch (e) {
      checks.qdrant = 'error';
    }

    res.json({
      status: 'ok',
      checks,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

export default router;
