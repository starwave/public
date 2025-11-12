#!/usr/bin/env python3
"""
Minimal SAM embedding generator for CPU
Generates 256D embeddings compatible with Prado's SAM embeddings
"""
import sys
import json
import os
import numpy as np
import cv2
from segment_anything import sam_model_registry, SamPredictor

# Configuration
SAM_MODEL_PATH = os.path.expanduser("~/sam_vit_b_01ec64.pth")
MODEL_TYPE = "vit_b"
TARGET_DIM = 256

def load_sam_model():
    """Load SAM model once"""
    if not os.path.exists(SAM_MODEL_PATH):
        print(json.dumps({
            "error": f"SAM model not found at {SAM_MODEL_PATH}",
            "download_url": "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth"
        }), file=sys.stderr)
        sys.exit(1)

    try:
        sam = sam_model_registry[MODEL_TYPE](checkpoint=SAM_MODEL_PATH)
        sam.to(device="cpu")
        predictor = SamPredictor(sam)
        return predictor
    except Exception as e:
        print(json.dumps({"error": f"Failed to load SAM model: {str(e)}"}), file=sys.stderr)
        sys.exit(1)

def generate_embedding(predictor, image_path):
    """Generate 256D SAM embedding for an image"""
    try:
        # Load image
        image = cv2.imread(image_path)
        if image is None:
            return {"error": f"Failed to load image: {image_path}"}

        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Generate SAM embedding
        predictor.set_image(image_rgb)
        image_embedding = predictor.get_image_embedding()

        # Convert to numpy and flatten
        embedding_np = image_embedding.cpu().numpy().flatten()

        # Reduce to 256D using average pooling (same as Prado)
        if len(embedding_np) > TARGET_DIM:
            pool_size = len(embedding_np) // TARGET_DIM
            embedding_reduced = []
            for i in range(TARGET_DIM):
                start_idx = i * pool_size
                end_idx = start_idx + pool_size
                embedding_reduced.append(float(np.mean(embedding_np[start_idx:end_idx])))
            embedding_vector = embedding_reduced
        else:
            embedding_vector = embedding_np.tolist()[:TARGET_DIM]

        # Normalize to unit vector
        embedding_array = np.array(embedding_vector)
        norm = np.linalg.norm(embedding_array)
        if norm > 0:
            embedding_vector = (embedding_array / norm).tolist()

        return {
            "embedding": embedding_vector,
            "dimensions": len(embedding_vector),
            "model": MODEL_TYPE
        }

    except Exception as e:
        return {"error": f"Failed to generate embedding: {str(e)}"}

def main():
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Usage: sam-embedder.py <image_path>"}), file=sys.stderr)
        sys.exit(1)

    image_path = sys.argv[1]

    if not os.path.exists(image_path):
        print(json.dumps({"error": f"Image file not found: {image_path}"}), file=sys.stderr)
        sys.exit(1)

    # Load model
    predictor = load_sam_model()

    # Generate embedding
    result = generate_embedding(predictor, image_path)

    # Output JSON result
    print(json.dumps(result))

    if "error" in result:
        sys.exit(1)

if __name__ == "__main__":
    main()
