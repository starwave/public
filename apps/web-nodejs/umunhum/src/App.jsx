import React, { useState } from 'react';
import {
    Container,
    Box,
    Typography,
    Paper,
    ThemeProvider,
    createTheme,
    CssBaseline,
    Alert
} from '@mui/material';
import ImageUpload from './components/ImageUpload';
import SearchResults from './components/SearchResults';
import './App.css';

const theme = createTheme({
    palette: {
        mode: 'light',
        primary: {
            main: '#1976d2',
        },
        secondary: {
            main: '#dc004e',
        },
    },
});

function App() {
    const [results, setResults] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleSearch = async (file) => {
        setLoading(true);
        setError(null);
        setResults([]);

        try {
            const formData = new FormData();
            formData.append('image', file);

            const apiUrl = import.meta.env.VITE_API_URL || '';
            const response = await fetch(`${apiUrl}/api/search/similar`, {
                method: 'POST',
                body: formData
            });

            if (!response.ok) {
                const errorData = await response.json();
                if (response.status === 503 && errorData.scanning) {
                    throw new Error(errorData.message || 'A scan is in progress. Please try again later.');
                }
                throw new Error(errorData.message || 'Search failed');
            }

            const data = await response.json();

            if (data.success && data.results) {
                setResults(data.results);
                if (data.results.length === 0) {
                    setError('No similar images found');
                }
            } else {
                throw new Error('Invalid response from server');
            }

        } catch (err) {
            console.error('Search error:', err);
            setError(err.message || 'Failed to search for similar images');
        } finally {
            setLoading(false);
        }
    };

    return (
        <ThemeProvider theme={theme}>
            <CssBaseline />
            <Box
                sx={{
                    minHeight: '100vh',
                    background: 'linear-gradient(135deg, #212e72 0%, #29d5e9 100%)',
                    py: 4
                }}
            >
                <Container maxWidth="lg">
                    <Paper elevation={3} sx={{ p: 4, borderRadius: 2 }}>
                        <Box sx={{ mb: 4, justifyContent: 'center', textAlign: 'center' }}>
                            <Box
                                component="img"
                                src="/omunhum.png"
                                alt="Umunhum"
                                sx={{
                                    width: 100,
                                    height: 100,
                                    mb: 2,
                                    borderRadius: 2,
                                    boxShadow: 2
                                }}
                            />
                            <Typography
                                variant="h3"
                                component="h1"
                                gutterBottom
                                sx={(theme) => ({
                                    fontSize: `${parseFloat(theme.typography.h3.fontSize) * 1.0}rem`,
                                    fontWeight: 'bold',
                                    background: 'linear-gradient(135deg, #212e72 0%, #29d5e9 100%)',
                                    WebkitBackgroundClip: 'text',
                                    WebkitTextFillColor: 'transparent'
                                })}
                            >
                                Umunhum
                            </Typography>
                            <Typography variant="subtitle1" color="text.secondary">
                                Upload to find the similar images
                            </Typography>
                        </Box>

                        {error && (
                            <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
                                {error}
                            </Alert>
                        )}

                        <ImageUpload onUpload={handleSearch} loading={loading} />

                        {results.length > 0 && (
                            <Box sx={{ mt: 4 }}>
                                <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
                                    Similar Images Found
                                </Typography>
                                <SearchResults results={results} />
                            </Box>
                        )}

                        {loading && (
                            <Box sx={{ mt: 4, textAlign: 'center' }}>
                                <Typography color="text.secondary">
                                    Analyzing image and searching for similar images...
                                </Typography>
                            </Box>
                        )}
                    </Paper>
                </Container>
            </Box>
        </ThemeProvider >
    );
}

export default App;
