import React, { useState } from 'react';
import {
    SafeAreaView,
    ScrollView,
    StatusBar,
    StyleSheet,
    Text,
    View,
    Image,
    Alert,
    ActivityIndicator,
} from 'react-native';
import ImageUpload from './components/ImageUpload';
import SearchResults from './components/SearchResults';
import { API_URL } from './config';

const App = () => {
    const [results, setResults] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleSearch = async imageData => {
        setLoading(true);
        setError(null);
        setResults([]);

        try {
            const formData = new FormData();
            formData.append('image', {
                uri: imageData.uri,
                type: imageData.type || 'image/jpeg',
                name: imageData.fileName || 'photo.jpg',
            });

            const response = await fetch(`${API_URL}/api/search/similar`, {
                method: 'POST',
                body: formData,
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            });

            const data = await response.json();

            if (!response.ok) {
                if (response.status === 503 && data.scanning) {
                    throw new Error(
                        data.message || 'A scan is in progress. Please try again later.',
                    );
                }
                throw new Error(data.message || 'Search failed');
            }

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
            const errorMessage = err.message || 'Failed to search for similar images';
            setError(errorMessage);
            Alert.alert('Search Error', errorMessage);
        } finally {
            setLoading(false);
        }
    };

    return (
        <SafeAreaView style={styles.container}>
            <StatusBar barStyle="light-content" backgroundColor="#667eea" />
            <ScrollView
                style={styles.scrollView}
                contentContainerStyle={styles.scrollContent}>
                <View style={styles.gradient}>
                    {/* Header */}
                    <View style={styles.header}>
                        <Image
                            source={require('./assets/icon.png')}
                            style={styles.logo}
                            resizeMode="contain"
                        />
                        <Text style={styles.title}>Umunhum</Text>
                        <Text style={styles.subtitle}>
                            Upload to find the similar images
                        </Text>
                    </View>

                    {/* Error Message */}
                    {error && (
                        <View style={styles.errorContainer}>
                            <Text style={styles.errorText}>{error}</Text>
                        </View>
                    )}

                    {/* Upload Component */}
                    <ImageUpload onUpload={handleSearch} loading={loading} />

                    {/* Loading Indicator */}
                    {loading && (
                        <View style={styles.loadingContainer}>
                            <ActivityIndicator size="large" color="#667eea" />
                            <Text style={styles.loadingText}>
                                Analyzing image and searching for similar images...
                            </Text>
                        </View>
                    )}

                    {/* Results */}
                    {results.length > 0 && (
                        <View style={styles.resultsContainer}>
                            <Text style={styles.resultsTitle}>Similar Images Found</Text>
                            <SearchResults results={results} />
                        </View>
                    )}
                </View>
            </ScrollView>
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#667eea',
    },
    scrollView: {
        flex: 1,
    },
    scrollContent: {
        flexGrow: 1,
    },
    gradient: {
        flex: 1,
        backgroundColor: '#667eea',
        paddingHorizontal: 16,
        paddingVertical: 20,
    },
    header: {
        alignItems: 'center',
        marginBottom: 24,
        backgroundColor: '#ffffff',
        borderRadius: 12,
        padding: 24,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 4,
    },
    logo: {
        width: 80,
        height: 80,
        marginBottom: 16,
        borderRadius: 12,
    },
    title: {
        fontSize: 28,
        fontWeight: 'bold',
        color: '#667eea',
        marginBottom: 8,
        textAlign: 'center',
    },
    subtitle: {
        fontSize: 14,
        color: '#666',
        textAlign: 'center',
    },
    errorContainer: {
        backgroundColor: '#ffebee',
        borderRadius: 8,
        padding: 12,
        marginBottom: 16,
        borderLeftWidth: 4,
        borderLeftColor: '#f44336',
    },
    errorText: {
        color: '#c62828',
        fontSize: 14,
    },
    loadingContainer: {
        alignItems: 'center',
        marginTop: 24,
        backgroundColor: '#ffffff',
        borderRadius: 12,
        padding: 24,
    },
    loadingText: {
        marginTop: 12,
        color: '#666',
        fontSize: 14,
        textAlign: 'center',
    },
    resultsContainer: {
        marginTop: 24,
    },
    resultsTitle: {
        fontSize: 20,
        fontWeight: 'bold',
        color: '#ffffff',
        marginBottom: 16,
    },
});

export default App;
