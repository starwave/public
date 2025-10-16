import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import path from 'path';

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Mock theme library data
const themeLibrary = [
    { Label: 'Nature Collection', Config: '/nature;;#green#|#forest#' },
    { Label: 'Urban Scenes', Config: '/urban;;#city#|#architecture#' },
    { Label: 'Abstract Art', Config: '/abstract;;#modern#|#colors#' },
    { Label: 'Minimalist', Config: '/minimal;;#simple#|#clean#' },
    { Label: 'Space & Astronomy', Config: '/space;;#galaxy#|#stars#' }
];

// API Routes

// Get theme library
app.get('/maramboi', (req: Request, res: Response) => {
    const action = req.query.a;

    if (action === 'g') {
        res.json(themeLibrary);
    } else {
        res.status(400).json({ error: 'Invalid action' });
    }
});

// Get wallpaper (proxy to actual wallpaper service)
app.get('/ngorongoro', (req: Request, res: Response) => {
    const { a, d, t, o } = req.query;

    // In production, this would proxy to your actual wallpaper service
    // For now, return a placeholder or redirect

    console.log('Wallpaper request:', { action: a, dimension: d, theme: t, options: o });

    // You would implement actual image fetching logic here
    // For example, fetch from a database or external API

    res.json({
        message: 'Wallpaper endpoint',
        params: { a, d, t, o }
    });
});

// Health check
app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve React app for all other routes (SPA)
app.get('*', (_req: Request, res: Response) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Error handling middleware
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});

export default app;