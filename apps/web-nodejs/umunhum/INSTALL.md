# Umunhum Web App - Installation Guide

## Overview

Umunhum is a React-based web application that allows users to upload an image and find the top 5 most similar images from the Qdrant vector database.

## Server Information

- **Host**: 11.11.11.11
- **Port**: 3002
- **URL**: http://11.11.11.11:3002/

## Technology Stack

- **Frontend**: React 18+ with TypeScript
- **Backend**: Node.js with Express
- **UI Library**: Material-UI (MUI) or similar
- **HTTP Client**: Axios
- **Image Processing**: Sharp or Canvas API

## Prerequisites

### 1. Install Node.js

```bash
# On Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# Verify installation
node --version  # Should be v20.x or higher
npm --version   # Should be v10.x or higher

# On macOS
brew install node@20
```

### 2. Install Build Tools

```bash
# On Ubuntu/Debian
sudo apt install -y build-essential

# On macOS (install Xcode Command Line Tools)
xcode-select --install
```

## Installation Steps

### 1. Navigate to Project Directory

```bash
cd ~/thirdwave_git/shared/nodejs/umunhum
```

### 2. Initialize Project (if starting fresh)

```bash
# Create React app with TypeScript
npx create-react-app . --template typescript

# Or use Vite for faster development
npm create vite@latest . -- --template react-ts
```

### 3. Install Dependencies

Create `package.json`:

```json
{
  "name": "umunhum",
  "version": "1.0.0",
  "description": "Image similarity search web application",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.2",
    "@mui/material": "^5.15.0",
    "@mui/icons-material": "^5.15.0",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "multer": "^1.4.5-lts.1",
    "sharp": "^0.33.1",
    "@qdrant/js-client-rest": "^1.7.0",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.45",
    "@types/react-dom": "^18.2.18",
    "@types/node": "^20.10.5",
    "@types/express": "^4.17.21",
    "@types/cors": "^2.8.17",
    "@types/multer": "^1.4.11",
    "typescript": "^5.3.3",
    "vite": "^5.0.8",
    "@vitejs/plugin-react": "^4.2.1",
    "concurrently": "^8.2.2"
  },
  "scripts": {
    "dev": "concurrently \"npm run dev:server\" \"npm run dev:client\"",
    "dev:server": "node --watch server/index.js",
    "dev:client": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "start": "node server/index.js"
  }
}
```

Install dependencies:

```bash
npm install
```

### 4. Create Configuration

Create `.env` file:

```bash
# Server Configuration
HOST=0.0.0.0
PORT=3002
NODE_ENV=production

# Backend API
API_PORT=3002
API_URL=http://11.11.11.12:3002/api

# Qdrant Configuration
QDRANT_HOST=11.11.11.12
QDRANT_PORT=6333
QDRANT_COLLECTION=prado_images

# Prado Service
PRADO_API_URL=http://11.11.11.11:3003

# Upload Configuration
UPLOAD_DIR=/tmp/umunhum_uploads
MAX_FILE_SIZE=10485760
ALLOWED_TYPES=image/jpeg,image/png,image/jpg,image/bmp,image/webp

# Search Configuration
TOP_K=5
EMBEDDING_MODEL=clip
```

### 5. Project Structure

Create the following structure:

```
umunhum/
├── INSTALL.md (this file)
├── README.md
├── package.json
├── tsconfig.json
├── vite.config.ts
├── .env
├── .gitignore
├── public/
│   └── index.html
├── src/
│   ├── App.tsx              # Main React component
│   ├── main.tsx             # Entry point
│   ├── components/
│   │   ├── ImageUpload.tsx  # Image upload component
│   │   ├── SearchResults.tsx # Results display
│   │   └── ImagePreview.tsx  # Image preview
│   ├── services/
│   │   └── api.ts           # API client
│   ├── types/
│   │   └── index.ts         # TypeScript types
│   └── styles/
│       └── App.css
└── server/
    ├── index.js             # Express server
    ├── routes/
    │   └── search.js        # Search routes
    ├── services/
    │   ├── embedder.js      # Image embedding
    │   └── qdrant.js        # Qdrant client
    └── middleware/
        └── upload.js        # File upload handler
```

### 6. Create TypeScript Configuration

Create `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### 7. Create Vite Configuration

Create `vite.config.ts`:

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port: 3002,
    proxy: {
      "/api": {
        target: "http://localhost:3002",
        changeOrigin: true,
      },
    },
  },
});
```

### 8. Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
/.pnp
.pnp.js

# Testing
/coverage

# Production
/build
/dist

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
*.log

# Editor
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Uploads
/tmp/
uploads/
EOF
```

## Backend Server Setup

### 1. Create Express Server

Create `server/index.js`:

```javascript
const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const searchRoutes = require("./routes/search");

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "../dist")));

// Routes
app.use("/api/search", searchRoutes);

// Health check
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", service: "umunhum" });
});

// Serve React app
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../dist/index.html"));
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Umunhum server running at http://0.0.0.0:${PORT}`);
});
```

### 2. Create Search Routes

Create `server/routes/search.js`:

```javascript
const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs").promises;
const { searchSimilarImages } = require("../services/qdrant");
const { embedImage } = require("../services/embedder");

// Configure multer
const upload = multer({
  dest: process.env.UPLOAD_DIR || "/tmp/umunhum_uploads",
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760, // 10MB
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      "image/jpeg",
      "image/png",
      "image/jpg",
      "image/bmp",
      "image/webp",
    ];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Invalid file type. Only images allowed."));
    }
  },
});

// POST /api/search/similar
router.post("/similar", upload.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No image file provided" });
    }

    // Generate embedding for uploaded image
    const embedding = await embedImage(req.file.path);

    // Search Qdrant for similar images
    const topK = parseInt(process.env.TOP_K) || 5;
    const results = await searchSimilarImages(embedding, topK);

    // Clean up uploaded file
    await fs.unlink(req.file.path);

    res.json({
      success: true,
      results: results.map((r) => ({
        id: r.id,
        score: r.score,
        path: r.payload.path,
        pid: r.payload.pid,
      })),
    });
  } catch (error) {
    console.error("Search error:", error);
    res.status(500).json({
      error: "Search failed",
      message: error.message,
    });
  }
});

// GET /api/search/status
router.get("/status", async (req, res) => {
  try {
    // Check connections
    const axios = require("axios");

    const qdrantHealth = await axios.get(
      `http://${process.env.QDRANT_HOST}:${process.env.QDRANT_PORT}/health`
    );

    res.json({
      status: "ok",
      qdrant: qdrantHealth.data,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ status: "error", message: error.message });
  }
});

module.exports = router;
```

### 3. Create Qdrant Service

Create `server/services/qdrant.js`:

```javascript
const { QdrantClient } = require("@qdrant/js-client-rest");

const client = new QdrantClient({
  host: process.env.QDRANT_HOST || "11.11.11.12",
  port: parseInt(process.env.QDRANT_PORT) || 6333,
});

const COLLECTION = process.env.QDRANT_COLLECTION || "prado_images";

async function searchSimilarImages(embedding, topK = 5) {
  try {
    const results = await client.search(COLLECTION, {
      vector: embedding,
      limit: topK,
      with_payload: true,
    });
    return results;
  } catch (error) {
    console.error("Qdrant search error:", error);
    throw error;
  }
}

async function getImageById(id) {
  try {
    const result = await client.retrieve(COLLECTION, {
      ids: [id],
      with_payload: true,
      with_vector: false,
    });
    return result[0];
  } catch (error) {
    console.error("Qdrant retrieve error:", error);
    throw error;
  }
}

module.exports = {
  searchSimilarImages,
  getImageById,
};
```

### 4. Create Embedder Service

Create `server/services/embedder.js`:

```javascript
const sharp = require("sharp");
const axios = require("axios");

// This is a placeholder. You'll need to implement actual embedding generation
// Options:
// 1. Use CLIP model via Python service
// 2. Use TensorFlow.js with a pre-trained model
// 3. Call Prado service to generate embeddings

async function embedImage(imagePath) {
  try {
    // Resize and normalize image
    const imageBuffer = await sharp(imagePath)
      .resize(224, 224, { fit: "cover" })
      .removeAlpha()
      .raw()
      .toBuffer();

    // Call Prado service for embedding (recommended)
    const pradoUrl = process.env.PRADO_API_URL;
    if (pradoUrl) {
      const response = await axios.post(`${pradoUrl}/embed`, imageBuffer, {
        headers: { "Content-Type": "application/octet-stream" },
      });
      return response.data.embedding;
    }

    // Fallback: Generate simple feature vector (not recommended for production)
    // This is just a placeholder - implement proper embedding
    const features = new Array(256).fill(0);
    for (let i = 0; i < Math.min(imageBuffer.length, 256); i++) {
      features[i] = imageBuffer[i] / 255.0;
    }
    return features;
  } catch (error) {
    console.error("Embedding generation error:", error);
    throw error;
  }
}

module.exports = {
  embedImage,
};
```

## Frontend Setup

### 1. Create Main App Component

Create `src/App.tsx`:

```typescript
import React from "react";
import { Container, Box, Typography } from "@mui/material";
import ImageUpload from "./components/ImageUpload";
import SearchResults from "./components/SearchResults";
import "./styles/App.css";

interface SearchResult {
  id: number;
  score: number;
  path: string;
  pid: number;
}

function App() {
  const [results, setResults] = React.useState<SearchResult[]>([]);
  const [loading, setLoading] = React.useState(false);

  const handleSearch = async (file: File) => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append("image", file);

      const response = await fetch("/api/search/similar", {
        method: "POST",
        body: formData,
      });

      const data = await response.json();
      setResults(data.results || []);
    } catch (error) {
      console.error("Search failed:", error);
      alert("Search failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h3" component="h1" gutterBottom align="center">
          Umunhum
        </Typography>
        <Typography
          variant="subtitle1"
          gutterBottom
          align="center"
          color="text.secondary"
        >
          Upload an image to find similar images
        </Typography>

        <ImageUpload onUpload={handleSearch} loading={loading} />

        {results.length > 0 && <SearchResults results={results} />}
      </Box>
    </Container>
  );
}

export default App;
```

## Running the Application

### 1. Development Mode

```bash
# Install dependencies
npm install

# Create upload directory
mkdir -p /tmp/umunhum_uploads

# Run development server (both frontend and backend)
npm run dev
```

Access at: http://11.11.11.12:3002

### 2. Production Build

```bash
# Build frontend
npm run build

# Start production server
npm start
```

### 3. Production with PM2

```bash
# Install PM2 globally
npm install -g pm2
# Start application
cd ~/thirdwave_git/shared/nodejs/umunhum
pm2 start server/index.js --name umunhum
# Save PM2 configuration
pm2 save
# Setup startup script
pm2 startup
# Now you can use pm2 commands:
pm2 restart umunhum
pm2 stop umunhum
pm2 logs umunhum
pm2 status
# Monitor
pm2 monit
```

### 4. Production with Systemd

Create `/etc/systemd/system/umunhum.service`:

```ini
[Unit]
Description=Umunhum Web App
After=network.target

[Service]
Type=simple
User=starwave
WorkingDirectory=/home/starwave/thirdwave_git/shared/nodejs/umunhum
Environment="NODE_ENV=production"
Environment="PATH=/usr/bin:/usr/local/bin"
ExecStart=/usr/bin/node server/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable umunhum
sudo systemctl start umunhum
sudo systemctl status umunhum
```

## Testing

### 1. Test Backend API

```bash
# Health check
curl http://11.11.11.12:3002/api/health

# Test search (with image file)
curl -X POST http://11.11.11.12:3002/api/search/similar \
  -F "image=@/path/to/test/image.jpg"
```

### 2. Test Frontend

Open browser: http://11.11.11.12:3002

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 3002
sudo lsof -i :3002

# Kill the process
sudo kill -9 <PID>
```

### Cannot Connect to Qdrant

```bash
# Test Qdrant connection
curl http://11.11.11.12:6333/health

# Check firewall
sudo ufw status
sudo ufw allow 6333
```

### Upload Directory Permissions

```bash
# Create and set permissions
sudo mkdir -p /tmp/umunhum_uploads
sudo chown -R $USER:$USER /tmp/umunhum_uploads
sudo chmod -R 755 /tmp/umunhum_uploads
```

### Build Errors

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install

# Clear build cache
rm -rf dist .vite
```

## Performance Optimization

### 1. Enable Compression

```javascript
// In server/index.js
const compression = require("compression");
app.use(compression());
```

### 2. Add Caching

```javascript
// Cache static assets
app.use(
  express.static("dist", {
    maxAge: "1d",
    etag: true,
  })
);
```

### 3. Use CDN for Large Files

Configure nginx reverse proxy for static assets.

## Monitoring

### View Logs

```bash
# PM2 logs
pm2 logs umunhum

# Systemd logs
sudo journalctl -u umunhum -f

# Custom logging
tail -f logs/umunhum.log
```

## Local SAM Mode (CPU-Only, No GPU Dependency)

By default, Umunhum uses the Prado API (GPU) to generate embeddings for search queries. If you want to run queries without depending on the GPU server, you can enable local SAM mode which generates embeddings on CPU.

### Prerequisites

1. **Python 3.8+** with pip
2. **SAM model file** (`sam_vit_b_01ec64.pth` - 375MB)
3. **Python packages**: segment-anything, opencv-python, numpy

### Installation Steps

#### 1. Install Python Dependencies

```bash
# Install Python packages
pip3 install segment-anything opencv-python numpy torch torchvision

# Or if using conda
conda install pytorch torchvision -c pytorch
pip3 install segment-anything opencv-python
```

#### 2. Download SAM Model

```bash
# Download the smaller vit_b model (375MB, suitable for CPU)
cd ~
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth

# Verify download
ls -lh ~/sam_vit_b_01ec64.pth
# Should show ~375MB file
```

**Note**: If you need better quality and have more RAM/CPU, you can use the larger `vit_h` model (2.4GB):

```bash
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
```

Then edit `server/services/sam-embedder.py` and change:

```python
SAM_MODEL_PATH = os.path.expanduser("~/sam_vit_h_4b8939.pth")
MODEL_TYPE = "vit_h"
```

#### 3. Make Python Script Executable

```bash
cd ~/thirdwave_git/shared/nodejs/umunhum/server/services
chmod +x sam-embedder.py
```

#### 4. Test SAM Embedder

```bash
# Test with any image
python3 sam-embedder.py /path/to/test/image.jpg

# Should output JSON like:
# {"embedding": [0.123, -0.456, ...], "dimensions": 256, "model": "vit_b"}
```

#### 5. Enable Local Mode

Edit `.env` file:

```bash
# Change EMBED_MODE from 'api' to 'local'
EMBED_MODE=local
```

#### 6. Restart Server

```bash
# If using npm run dev
# Ctrl+C and restart

# If using PM2
pm2 restart umunhum

# If using systemd
sudo systemctl restart umunhum
```

### Performance Comparison

| Mode        | Hardware           | Speed  | Dependency             |
| ----------- | ------------------ | ------ | ---------------------- |
| API (GPU)   | Prado Server GPU   | ~0.5s  | Requires Prado running |
| Local (CPU) | Umunhum Server CPU | ~5-10s | No GPU dependency      |

**Note**: Local mode is slower but makes Umunhum completely independent for queries. Prado is still needed for scanning new images into the database.

### Troubleshooting Local Mode

#### Python Not Found

```bash
# Check Python installation
which python3
python3 --version  # Should be 3.8+

# If not installed, install Python
sudo apt install python3 python3-pip  # Ubuntu/Debian
brew install python3  # macOS
```

#### SAM Model Not Found

```bash
# Check if model exists
ls -lh ~/sam_vit_b_01ec64.pth

# If missing, download again
wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth
mv sam_vit_b_01ec64.pth ~/
```

#### Import Errors

```bash
# Install missing packages
pip3 install segment-anything opencv-python numpy

# If torch not found
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cpu
```

#### Script Permission Denied

```bash
chmod +x ~/thirdwave_git/shared/nodejs/umunhum/server/services/sam-embedder.py
```

#### Check Logs

```bash
# Look for [LOCAL SAM] messages in server logs
pm2 logs umunhum | grep "LOCAL SAM"

# Should see:
# [LOCAL SAM] Generating embedding for: /tmp/umunhum_uploads/...
# [LOCAL SAM] Generated 256D embedding in 5.23s (model: vit_b)
```

## Support

- **React Documentation**: https://react.dev
- **MUI Documentation**: https://mui.com
- **Express Documentation**: https://expressjs.com
- **Qdrant JS Client**: https://github.com/qdrant/qdrant-js
- **SAM Model**: https://github.com/facebookresearch/segment-anything
