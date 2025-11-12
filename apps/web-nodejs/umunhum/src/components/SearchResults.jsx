import React, { useState, useEffect } from 'react';
import {
  Grid,
  Card,
  CardMedia,
  CardContent,
  Typography,
  Box,
  Chip,
  Paper,
  Dialog,
  DialogContent,
  DialogActions,
  Button,
  IconButton
} from '@mui/material';
import ImageIcon from '@mui/icons-material/Image';
import CloseIcon from '@mui/icons-material/Close';

export default function SearchResults({ results }) {
  const [exifData, setExifData] = useState({});
  const [selectedImage, setSelectedImage] = useState(null);

  // Fetch EXIF data for all results
  useEffect(() => {
    const fetchExifData = async () => {
      const apiUrl = import.meta.env.VITE_API_URL || '';
      const newExifData = {};

      for (const result of results) {
        try {
          const response = await fetch(
            `${apiUrl}/api/image/exif?path=${encodeURIComponent(result.path)}`
          );
          if (response.ok) {
            const data = await response.json();
            newExifData[result.id] = data;
          }
        } catch (error) {
          console.error(`Failed to fetch EXIF for ${result.path}:`, error);
        }
      }

      setExifData(newExifData);
    };

    if (results && results.length > 0) {
      fetchExifData();
    }
  }, [results]);

  if (!results || results.length === 0) {
    return null;
  }

  // Function to get image URL
  const getImageUrl = (path) => {
    const apiUrl = import.meta.env.VITE_API_URL || '';
    return `${apiUrl}/api/image?path=${encodeURIComponent(path)}`;
  };

  const getSimilarityPercentage = (score) => {
    return (score * 100).toFixed(1);
  };

  const getSimilarityColor = (score) => {
    if (score >= 0.9) return 'success';
    if (score >= 0.7) return 'primary';
    if (score >= 0.5) return 'warning';
    return 'default';
  };

  return (
    <>
      {/* 3-Column Thumbnail Grid */}
      <Grid container spacing={1}>
        {results.map((result, index) => (
          <Grid item xs={4} key={result.id || index}>
            <Card
              elevation={2}
              onClick={() => setSelectedImage({ ...result, index })}
              sx={{
                cursor: 'pointer',
                transition: 'transform 0.2s, box-shadow 0.2s',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  boxShadow: 4
                }
              }}
            >
              {/* Image Container with Badges */}
              <Box sx={{ position: 'relative' }}>
                {/* Rank badge */}
                <Chip
                  label={`#${index + 1}`}
                  size="small"
                  color="primary"
                  sx={{
                    position: 'absolute',
                    top: 6,
                    left: 6,
                    zIndex: 1,
                    fontWeight: 'bold',
                    fontSize: '0.7rem',
                    height: 20
                  }}
                />

                {/* Similarity score */}
                <Chip
                  label={`${getSimilarityPercentage(result.score)}%`}
                  size="small"
                  color={getSimilarityColor(result.score)}
                  sx={{
                    position: 'absolute',
                    top: 6,
                    right: 6,
                    zIndex: 1,
                    fontWeight: 'bold',
                    fontSize: '0.7rem',
                    height: 20
                  }}
                />

                {/* Thumbnail Image */}
                <CardMedia
                  component="img"
                  sx={{
                    aspectRatio: '1',
                    objectFit: 'cover',
                    bgcolor: '#f5f5f5'
                  }}
                  image={getImageUrl(result.path)}
                  alt={result.path}
                  onError={(e) => {
                    e.target.style.display = 'none';
                    e.target.nextSibling.style.display = 'flex';
                  }}
                />
                <Paper
                  sx={{
                    aspectRatio: '1',
                    display: 'none',
                    alignItems: 'center',
                    justifyContent: 'center',
                    bgcolor: '#f5f5f5'
                  }}
                >
                  <ImageIcon sx={{ fontSize: 48, color: 'text.secondary' }} />
                </Paper>
              </Box>

              {/* Compact Card Content */}
              <CardContent sx={{ p: 1, pb: '8px !important' }}>
                {/* Show EXIF description if available */}
                {exifData[result.id]?.description && (
                  <Typography
                    variant="caption"
                    sx={{
                      display: 'block',
                      mb: 0.5,
                      px: 0.5,
                      py: 0.25,
                      bgcolor: '#e3f2fd',
                      borderRadius: 0.5,
                      fontStyle: 'italic',
                      fontSize: '0.7rem',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap'
                    }}
                  >
                    "{exifData[result.id].description}"
                  </Typography>
                )}

                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{
                    display: 'block',
                    fontSize: '0.65rem',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                    mb: 0.5
                  }}
                >
                  {result.path}
                </Typography>

                {/* Progress Bar */}
                <Box
                  sx={{
                    width: '100%',
                    height: 4,
                    bgcolor: 'grey.200',
                    borderRadius: 0.5,
                    overflow: 'hidden'
                  }}
                >
                  <Box
                    sx={{
                      width: `${getSimilarityPercentage(result.score)}%`,
                      height: '100%',
                      bgcolor: getSimilarityColor(result.score) + '.main'
                    }}
                  />
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Detail Modal Dialog */}
      <Dialog
        open={!!selectedImage}
        onClose={() => setSelectedImage(null)}
        maxWidth="md"
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 2
          }
        }}
      >
        {selectedImage && (
          <>
            {/* Close Button */}
            <IconButton
              onClick={() => setSelectedImage(null)}
              sx={{
                position: 'absolute',
                right: 8,
                top: 8,
                zIndex: 1,
                bgcolor: 'rgba(255, 255, 255, 0.9)',
                '&:hover': {
                  bgcolor: 'rgba(255, 255, 255, 1)'
                }
              }}
            >
              <CloseIcon />
            </IconButton>

            <DialogContent sx={{ p: 0, pt: 2 }}>
              {/* Full Image */}
              <Box
                sx={{
                  width: '100%',
                  height: 400,
                  bgcolor: '#f5f5f5',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  px: 2
                }}
              >
                <CardMedia
                  component="img"
                  image={getImageUrl(selectedImage.path)}
                  alt={selectedImage.path}
                  sx={{
                    maxWidth: '100%',
                    maxHeight: '100%',
                    objectFit: 'contain'
                  }}
                />
              </Box>

              {/* Details */}
              <Box sx={{ p: 3 }}>
                <Typography variant="h6" gutterBottom>
                  Image #{selectedImage.index + 1}
                </Typography>

                {exifData[selectedImage.id]?.description && (
                  <Paper
                    elevation={0}
                    sx={{
                      p: 1.5,
                      mb: 2,
                      bgcolor: '#e3f2fd',
                      borderLeft: 3,
                      borderColor: 'primary.main'
                    }}
                  >
                    <Typography variant="body2" sx={{ fontStyle: 'italic' }}>
                      {exifData[selectedImage.id].description}
                    </Typography>
                  </Paper>
                )}

                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  <Box sx={{ display: 'flex' }}>
                    <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                      Similarity:
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {getSimilarityPercentage(selectedImage.score)}%
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex' }}>
                    <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                      Path:
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ wordBreak: 'break-all' }}>
                      {selectedImage.path}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex' }}>
                    <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                      ID:
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {selectedImage.pid || selectedImage.id}
                    </Typography>
                  </Box>

                  {exifData[selectedImage.id]?.make && exifData[selectedImage.id]?.model && (
                    <Box sx={{ display: 'flex' }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                        Camera:
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {exifData[selectedImage.id].make} {exifData[selectedImage.id].model}
                      </Typography>
                    </Box>
                  )}

                  {exifData[selectedImage.id]?.dateTime && (
                    <Box sx={{ display: 'flex' }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                        Taken:
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {new Date(exifData[selectedImage.id].dateTime).toLocaleString()}
                      </Typography>
                    </Box>
                  )}

                  {exifData[selectedImage.id]?.width && exifData[selectedImage.id]?.height && (
                    <Box sx={{ display: 'flex' }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                        Dimensions:
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {exifData[selectedImage.id].width} × {exifData[selectedImage.id].height}
                      </Typography>
                    </Box>
                  )}

                  {selectedImage.payload?.size && (
                    <Box sx={{ display: 'flex' }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                        Size:
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {(selectedImage.payload.size / 1024 / 1024).toFixed(2)} MB
                      </Typography>
                    </Box>
                  )}

                  {selectedImage.payload?.mdate && (
                    <Box sx={{ display: 'flex' }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, width: 120, flexShrink: 0 }}>
                        Modified:
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {new Date(selectedImage.payload.mdate).toLocaleString()}
                      </Typography>
                    </Box>
                  )}
                </Box>
              </Box>
            </DialogContent>

            <DialogActions sx={{ p: 2 }}>
              <Button onClick={() => setSelectedImage(null)} variant="contained">
                Close
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </>
  );
}
