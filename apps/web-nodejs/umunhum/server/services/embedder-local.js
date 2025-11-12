/**
 * Local CPU-based image embedding service
 * Uses SAM (Segment Anything Model) on CPU to match Prado's embeddings
 */
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Path to Python script
const PYTHON_SCRIPT = join(__dirname, 'sam-embedder.py');

/**
 * Generate embedding for an image using local CPU with SAM
 * @param {string} imagePath - Path to image file
 * @returns {Promise<number[]>} - 256D SAM embedding vector (normalized)
 */
export async function embedImageLocal(imagePath) {
  return new Promise((resolve, reject) => {
    console.log(`[LOCAL SAM] Generating embedding for: ${imagePath}`);
    const startTime = Date.now();

    // Spawn Python process
    const python = spawn('python3', [PYTHON_SCRIPT, imagePath]);

    let stdout = '';
    let stderr = '';

    python.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    python.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    python.on('close', (code) => {
      const inferenceTime = ((Date.now() - startTime) / 1000).toFixed(2);

      if (code !== 0) {
        console.error('[LOCAL SAM] Python script failed:', stderr);
        reject(new Error(stderr || 'Failed to generate SAM embedding'));
        return;
      }

      try {
        const result = JSON.parse(stdout);

        if (result.error) {
          console.error('[LOCAL SAM] Error:', result.error);
          if (result.download_url) {
            console.error('[LOCAL SAM] Download SAM model from:', result.download_url);
          }
          reject(new Error(result.error));
          return;
        }

        if (!result.embedding || !Array.isArray(result.embedding)) {
          reject(new Error('Invalid embedding format from Python script'));
          return;
        }

        console.log(`[LOCAL SAM] Generated ${result.dimensions}D embedding in ${inferenceTime}s (model: ${result.model})`);
        resolve(result.embedding);

      } catch (parseError) {
        console.error('[LOCAL SAM] Failed to parse output:', parseError.message);
        console.error('[LOCAL SAM] Output:', stdout);
        reject(new Error('Failed to parse Python script output'));
      }
    });

    python.on('error', (error) => {
      console.error('[LOCAL SAM] Failed to spawn Python process:', error.message);
      reject(new Error('Python3 not available. Install Python 3 and segment-anything package.'));
    });
  });
}

/**
 * Warm up the SAM model by running a dummy inference
 * Note: SAM model is loaded by Python script, no pre-warming needed
 */
export async function warmupModel() {
  console.log('[LOCAL SAM] Model will be loaded on first use');
}
