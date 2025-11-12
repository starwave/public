/**
 * Umunhum Web App
 * Express server
 */
// IMPORTANT: Load dotenv FIRST, before any other imports that use env vars
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import searchRoutes from './routes/search.js';
import { createUploadDir } from './middleware/upload.js';
import { exiftool } from 'exiftool-vendored';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3002;

// Create upload directory
createUploadDir();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../dist')));

// Routes
app.use('/api/search', searchRoutes);

// Serve images from Prado root
app.get('/api/image', (req, res) => {
    const relativePath = req.query.path;
    if (!relativePath) {
        return res.status(400).json({ error: 'No image path provided' });
    }

    const pradoRoot = process.env.PRADO_ROOT;
    if (!pradoRoot) {
        return res.status(500).json({ error: 'PRADO_ROOT not configured' });
    }

    // Construct absolute path
    const absolutePath = path.join(pradoRoot, relativePath);

    // Security check: ensure the resolved path is within PRADO_ROOT
    const resolvedPath = path.resolve(absolutePath);
    const resolvedRoot = path.resolve(pradoRoot);
    if (!resolvedPath.startsWith(resolvedRoot)) {
        return res.status(403).json({ error: 'Access denied' });
    }

    // Send the file
    res.sendFile(resolvedPath, (err) => {
        if (err) {
            console.error('Error serving image:', err.message);
            res.status(404).json({ error: 'Image not found' });
        }
    });
});

// Get EXIF data for an image
app.get('/api/image/exif', async (req, res) => {
    const relativePath = req.query.path;
    if (!relativePath) {
        return res.status(400).json({ error: 'No image path provided' });
    }

    const pradoRoot = process.env.PRADO_ROOT;
    if (!pradoRoot) {
        return res.status(500).json({ error: 'PRADO_ROOT not configured' });
    }

    try {
        // Construct absolute path
        const absolutePath = path.join(pradoRoot, relativePath);

        // Security check: ensure the resolved path is within PRADO_ROOT
        const resolvedPath = path.resolve(absolutePath);
        const resolvedRoot = path.resolve(pradoRoot);
        if (!resolvedPath.startsWith(resolvedRoot)) {
            return res.status(403).json({ error: 'Access denied' });
        }

        // Read EXIF data
        const tags = await exiftool.read(resolvedPath);

        // Extract useful fields
        const exifData = {
            description: tags.Description || tags.ImageDescription || null,
            title: tags.Title || null,
            subject: tags.Subject || null,
            keywords: tags.Keywords || null,
            make: tags.Make || null,
            model: tags.Model || null,
            dateTime: tags.DateTimeOriginal || tags.CreateDate || null,
            width: tags.ImageWidth || null,
            height: tags.ImageHeight || null
        };

        res.json(exifData);

    } catch (err) {
        console.error('Error reading EXIF:', err.message);
        res.status(500).json({ error: 'Failed to read EXIF data' });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'umunhum',
        version: '1.0.0'
    });
});

// Serve React app for all other routes
app.get('*', (req, res) => {
    const indexPath = path.join(__dirname, '../dist/index.html');
    // Check if dist exists (production), otherwise send message
    if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        res.json({
            message: 'Umunhum API Server',
            note: 'Run "npm run build" to build the frontend'
        });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Umunhum server running at http://0.0.0.0:${PORT}`);
    console.log(`Prado API: ${process.env.PRADO_API_URL}`);
    console.log(`Qdrant: ${process.env.QDRANT_HOST}:${process.env.QDRANT_PORT}`);
});
