# CPU-Only Embedding Mode

Umunhum now supports local CPU-based image embedding, eliminating the need for the GPU box (Prado API) during searches.

## When to use CPU mode?

- ✅ **After your vector database is fully built**
- ✅ **When you want to run searches without GPU dependency**
- ✅ **For deployments without access to the Prado API**

## Performance Comparison

| Mode            | Speed           | Requirements                          |
| --------------- | --------------- | ------------------------------------- |
| **API** (GPU)   | ~0.5s per image | Requires Prado API @ 11.11.11.11:3003 |
| **Local** (CPU) | ~1-3s per image | No external dependencies              |

## How to Enable

Edit `.env` and change:

```bash
# Use Prado API with GPU (default, faster)
EMBED_MODE=api

# OR use local CPU (no GPU needed, slower)
EMBED_MODE=local
```

Then restart the server.

## First Run

On first run with `EMBED_MODE=local`, the CLIP model (~400MB) will be downloaded and cached:

```
Loading CLIP model (this may take a while on first run)...
CLIP model loaded in 12.34s
```

Subsequent runs will use the cached model and be much faster.

## Technical Details

- **Model**: OpenAI CLIP ViT-B/32 (same as Prado uses)
- **Library**: transformers.js (pure JavaScript)
- **Output**: 512-dimensional embedding vector (normalized for cosine similarity)
- **Cache**: Models stored in `~/.cache/huggingface/`

## Notes

- Building the initial vector database still requires GPU (Prado scanning)
- Only query-time embedding runs on CPU
- CPU mode is single-threaded (one query at a time)
- Perfect for low-traffic personal use
