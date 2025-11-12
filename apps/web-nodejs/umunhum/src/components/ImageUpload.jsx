import React, { useState, useRef } from 'react';
import {
  Box,
  Button,
  Card,
  CardMedia,
  Typography,
  CircularProgress
} from '@mui/material';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import DeleteIcon from '@mui/icons-material/Delete';
import SearchIcon from '@mui/icons-material/Search';

export default function ImageUpload({ onUpload, loading }) {
  const [selectedImage, setSelectedImage] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const dragCounterRef = useRef(0);
  const fileInputRef = useRef(null);

  const processFile = (file) => {
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file');
      return;
    }

    // Validate file size (10MB max)
    if (file.size > 10 * 1024 * 1024) {
      alert('File size must be less than 10MB');
      return;
    }

    setSelectedImage(file);

    // Create preview URL
    const reader = new FileReader();
    reader.onloadend = () => {
      setPreviewUrl(reader.result);
    };
    reader.readAsDataURL(file);
  };

  const handleFileSelect = (event) => {
    const file = event.target.files[0];
    processFile(file);
  };

  const handleDragEnter = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current++;
    if (e.dataTransfer.items && e.dataTransfer.items.length > 0) {
      setIsDragOver(true);
    }
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current--;
    if (dragCounterRef.current === 0) {
      setIsDragOver(false);
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounterRef.current = 0;
    setIsDragOver(false);

    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
      processFile(files[0]);
    }
  };

  const handleClear = () => {
    setSelectedImage(null);
    setPreviewUrl(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleSearch = () => {
    if (selectedImage && onUpload) {
      onUpload(selectedImage);
    }
  };

  return (
    <Box sx={{ width: '100%' }}>
      {/* File input (hidden) */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        style={{ display: 'none' }}
        onChange={handleFileSelect}
      />

      {/* Upload area */}
      {!previewUrl ? (
        <Box
          onClick={() => fileInputRef.current?.click()}
          onDragEnter={handleDragEnter}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          sx={{
            border: isDragOver ? '2px solid' : '2px dashed',
            borderColor: isDragOver ? 'primary.main' : '#ccc',
            borderRadius: 2,
            p: 6,
            textAlign: 'center',
            cursor: 'pointer',
            transition: 'all 0.3s',
            bgcolor: isDragOver ? 'primary.main' : 'transparent',
            color: isDragOver ? 'primary.contrastText' : 'inherit',
            '&:hover': {
              borderColor: 'primary.main',
              bgcolor: isDragOver ? 'primary.main' : 'action.hover'
            }
          }}
        >
          <CloudUploadIcon
            sx={{
              fontSize: 64,
              color: isDragOver ? 'primary.contrastText' : 'text.secondary',
              mb: 2
            }}
          />
          <Typography variant="h6" gutterBottom sx={{ color: isDragOver ? 'primary.contrastText' : 'inherit' }}>
            {isDragOver ? 'Drop image here' : 'Click to upload or drag & drop'}
          </Typography>
          <Typography variant="body2" sx={{ color: isDragOver ? 'primary.contrastText' : 'text.secondary' }}>
            Supported formats: JPG, PNG, BMP, WEBP, GIF
          </Typography>
          <Typography variant="body2" sx={{ color: isDragOver ? 'primary.contrastText' : 'text.secondary' }}>
            Maximum size: 10MB
          </Typography>
        </Box>
      ) : (
        <Box>
          {/* Image preview with drag & drop to replace */}
          <Card
            sx={{ maxWidth: 600, mx: 'auto', mb: 2, position: 'relative' }}
            onDragEnter={handleDragEnter}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
          >
            {/* Drag overlay */}
            {isDragOver && (
              <Box
                sx={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  bgcolor: 'primary.main',
                  opacity: 0.95,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  zIndex: 10,
                  borderRadius: 1,
                  pointerEvents: 'none'
                }}
              >
                <Box sx={{ textAlign: 'center', pointerEvents: 'none' }}>
                  <CloudUploadIcon sx={{ fontSize: 64, color: 'primary.contrastText', mb: 1 }} />
                  <Typography variant="h6" sx={{ color: 'primary.contrastText' }}>
                    Drop to replace image
                  </Typography>
                </Box>
              </Box>
            )}
            <CardMedia
              component="img"
              image={previewUrl}
              alt="Selected image"
              sx={{
                maxHeight: 400,
                objectFit: 'contain',
                bgcolor: '#f5f5f5',
                cursor: isDragOver ? 'copy' : 'default'
              }}
            />
          </Card>

          {/* Action buttons */}
          <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center' }}>
            <Button
              variant="outlined"
              startIcon={<DeleteIcon />}
              onClick={handleClear}
              disabled={loading}
            >
              Clear
            </Button>
            <Button
              variant="contained"
              startIcon={loading ? <CircularProgress size={20} /> : <SearchIcon />}
              onClick={handleSearch}
              disabled={loading}
              size="large"
            >
              {loading ? 'Searching...' : 'Search Similar Images'}
            </Button>
          </Box>

          {selectedImage && (
            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ display: 'block', textAlign: 'center', mt: 2 }}
            >
              {selectedImage.name} ({(selectedImage.size / 1024).toFixed(2)} KB)
            </Typography>
          )}
        </Box>
      )}
    </Box>
  );
}
