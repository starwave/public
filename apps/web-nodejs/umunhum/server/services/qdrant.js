/**
 * Qdrant client service
 */
import { QdrantClient } from '@qdrant/js-client-rest';

const client = new QdrantClient({
    host: process.env.QDRANT_HOST || '11.11.11.12',
    port: parseInt(process.env.QDRANT_PORT || '6333'),
    checkCompatibility: false
});

const COLLECTION = process.env.QDRANT_COLLECTION || 'prado_images';

/**
 * Search for similar images in Qdrant
 * @param {number[]} embedding - Image embedding vector
 * @param {number} topK - Number of results to return
 * @returns {Promise<Array>} - Search results
 */
export async function searchSimilarImages(embedding, topK = 5) {
    try {
        // Search with more results to account for filtering out removed images
        const results = await client.search(COLLECTION, {
            vector: embedding,
            limit: topK * 2,  // Request double to ensure we get enough after filtering
            with_payload: true,
            filter: {
                // Only include images with status "done" or no status (old vectors)
                should: [
                    { key: 'status', match: { value: 'done' } },
                    { is_empty: { key: 'status' } }  // Include old vectors without status
                ]
            }
        });

        // Take only the top K after filtering
        const filtered = results.slice(0, topK);
        console.log(`Found ${filtered.length} similar images (searched ${results.length}, filtered to ${filtered.length})`);
        return filtered;

    } catch (error) {
        console.error('Qdrant search error:', error);
        throw error;
    }
}

/**
 * Get image by ID from Qdrant
 * @param {number} id - Point ID
 * @returns {Promise<Object>} - Image data
 */
export async function getImageById(id) {
    try {
        const result = await client.retrieve(COLLECTION, {
            ids: [id],
            with_payload: true,
            with_vector: false
        });

        if (result && result.length > 0) {
            return result[0];
        }
        return null;

    } catch (error) {
        console.error('Qdrant retrieve error:', error);
        throw error;
    }
}

/**
 * Get collection info
 * @returns {Promise<Object>} - Collection information
 */
export async function getCollectionInfo() {
    try {
        const info = await client.getCollection(COLLECTION);
        return info;
    } catch (error) {
        console.error('Qdrant collection info error:', error);
        throw error;
    }
}
