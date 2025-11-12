/**
 * Image embedding service
 * Supports both Prado API (GPU) and local CPU embedding
 */
import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';

// Helper functions to get config at runtime (not module load time)
const getPradoUrl = () => process.env.PRADO_API_URL || 'http://11.11.11.11:3003';
const getEmbedMode = () => process.env.EMBED_MODE || 'api';

// Lazy load local embedder only if needed
let embedImageLocal = null;
async function getLocalEmbedder() {
  if (!embedImageLocal) {
    try {
      const module = await import('./embedder-local.js');
      embedImageLocal = module.embedImageLocal;
    } catch (error) {
      throw new Error(
        'Local embedder not available. Ensure Python3, SAM model, and segment-anything package are installed. See INSTALL.md for setup instructions.'
      );
    }
  }
  return embedImageLocal;
}

/**
 * Generate embedding for an image using Prado API (GPU)
 * @param {string} imagePath - Path to image file
 * @returns {Promise<number[]>} - Embedding vector
 */
export async function embedImageViaAPI(imagePath) {
  try {
    console.log(`Generating embedding for: ${imagePath}`);

    // Create form data with image file
    const formData = new FormData();
    formData.append('file', fs.createReadStream(imagePath));

    // Call Prado API
    const response = await axios.post(
      `${getPradoUrl()}/embed`,
      formData,
      {
        headers: {
          ...formData.getHeaders()
        },
        timeout: 30000 // 30 second timeout
      }
    );

    if (response.data && response.data.embedding) {
      console.log(`Generated embedding with ${response.data.embedding.length} dimensions`);
      return response.data.embedding;
    }

    throw new Error('Invalid response from Prado API');

  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      console.error('[PRADO API] Cannot connect - is it running?');
    } else {
      console.error('[PRADO API] Error generating embedding:', error.message);
    }
    throw error;
  }
}

/**
 * Generate embedding for an image (router function)
 * Uses either API or local CPU based on EMBED_MODE configuration
 * Automatically falls back to local mode if API mode fails
 * @param {string} imagePath - Path to image file
 * @returns {Promise<number[]>} - Embedding vector
 */
export async function embedImage(imagePath) {
  const embedMode = getEmbedMode();
  console.log(`[EMBED] Mode: ${embedMode} (EMBED_MODE=${process.env.EMBED_MODE})`);

  if (embedMode === 'local') {
    console.log('[EMBED] Using LOCAL CPU mode');
    const localEmbedder = await getLocalEmbedder();
    return await localEmbedder(imagePath);
  } else {
    // Try API mode first
    console.log('[EMBED] Using PRADO API mode');
    try {
      return await embedImageViaAPI(imagePath);
    } catch (apiError) {
      // API failed, try to fall back to local mode
      console.warn('[EMBED] ⚠️  Prado API failed, attempting fallback to LOCAL CPU mode...');
      console.warn(`[EMBED] API Error: ${apiError.message}`);

      try {
        const localEmbedder = await getLocalEmbedder();
        const result = await localEmbedder(imagePath);
        console.log('[EMBED] ✅ Successfully fell back to LOCAL CPU mode');
        return result;
      } catch (localError) {
        // Both API and local failed
        console.error('[EMBED] ❌ Both API and LOCAL modes failed');
        console.error(`[EMBED] Local Error: ${localError.message}`);
        throw new Error(
          `Embedding generation failed. API: ${apiError.message}. Local: ${localError.message}`
        );
      }
    }
  }
}

/**
 * Check if Prado API is available
 * @returns {Promise<boolean>} - True if available
 */
export async function isPradoAvailable() {
  try {
    const response = await axios.get(`${getPradoUrl()}/health`, {
      timeout: 5000
    });
    return response.status === 200;
  } catch (error) {
    return false;
  }
}

/**
 * Check if a scan is currently in progress
 * Only relevant in API mode (not local mode)
 * @returns {Promise<{scanning: boolean, progress?: number}>} - Scan status
 */
export async function isScanInProgress() {
  // In local mode, we don't use Prado API, so no scan conflict possible
  if (getEmbedMode() === 'local') {
    return { scanning: false };
  }

  try {
    const response = await axios.get(`${getPradoUrl()}/status`, {
      timeout: 5000
    });
    return {
      scanning: response.data.scanning || false,
      progress: response.data.progress_percent || 0,
      totalImages: response.data.total_images || 0,
      processed: response.data.processed || 0
    };
  } catch (error) {
    console.error('[PRADO API] Error checking scan status:', error.message);
    // If we can't check status, assume no scan is running
    return { scanning: false };
  }
}
