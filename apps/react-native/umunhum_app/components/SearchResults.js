import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  Image,
  StyleSheet,
  FlatList,
  Dimensions,
  TouchableOpacity,
  Modal,
  ScrollView,
} from 'react-native';
import {API_URL} from '../config';

const {width} = Dimensions.get('window');
const COLUMN_COUNT = 3;
const CARD_MARGIN = 8;
const CARD_WIDTH = (width - 32 - CARD_MARGIN * (COLUMN_COUNT - 1) * 2) / COLUMN_COUNT;

const SearchResults = ({results}) => {
  const [selectedImage, setSelectedImage] = useState(null);
  const [exifData, setExifData] = useState({});

  // Fetch EXIF data for all results
  useEffect(() => {
    const fetchExifData = async () => {
      const newExifData = {};

      for (const result of results) {
        try {
          const response = await fetch(
            `${API_URL}/api/image/exif?path=${encodeURIComponent(result.path)}`,
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

  const getImageUrl = path => {
    return `${API_URL}/api/image?path=${encodeURIComponent(path)}`;
  };

  const getSimilarityPercentage = score => {
    return (score * 100).toFixed(1);
  };

  const getSimilarityColor = score => {
    if (score >= 0.9) return '#4caf50';
    if (score >= 0.7) return '#2196f3';
    if (score >= 0.5) return '#ff9800';
    return '#9e9e9e';
  };

  const renderItem = ({item, index}) => {
    const similarityPercent = getSimilarityPercentage(item.score);
    const similarityColor = getSimilarityColor(item.score);

    return (
      <TouchableOpacity
        style={styles.card}
        onPress={() => setSelectedImage({...item, index})}>
        <View style={styles.imageContainer}>
          {/* Rank Badge */}
          <View style={[styles.badge, styles.rankBadge]}>
            <Text style={styles.badgeText}>#{index + 1}</Text>
          </View>

          {/* Similarity Badge */}
          <View
            style={[
              styles.badge,
              styles.similarityBadge,
              {backgroundColor: similarityColor},
            ]}>
            <Text style={styles.badgeText}>{similarityPercent}%</Text>
          </View>

          {/* Image */}
          <Image
            source={{uri: getImageUrl(item.path)}}
            style={styles.cardImage}
            resizeMode="cover"
          />
        </View>

        {/* Card Content */}
        <View style={styles.cardContent}>
          {exifData[item.id]?.description && (
            <Text style={styles.description} numberOfLines={2}>
              "{exifData[item.id].description}"
            </Text>
          )}

          <Text style={styles.pathText} numberOfLines={1}>
            {item.path}
          </Text>

          {/* Progress Bar */}
          <View style={styles.progressContainer}>
            <View style={styles.progressBackground}>
              <View
                style={[
                  styles.progressBar,
                  {
                    width: `${similarityPercent}%`,
                    backgroundColor: similarityColor,
                  },
                ]}
              />
            </View>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const renderDetailModal = () => {
    if (!selectedImage) return null;

    const exif = exifData[selectedImage.id];
    const similarityPercent = getSimilarityPercentage(selectedImage.score);

    return (
      <Modal
        visible={!!selectedImage}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setSelectedImage(null)}>
        <View style={styles.modalContainer}>
          <View style={styles.modalContent}>
            <ScrollView contentContainerStyle={styles.scrollContent}>
              {/* Image */}
              <Image
                source={{uri: getImageUrl(selectedImage.path)}}
                style={styles.modalImage}
                resizeMode="contain"
              />

              {/* Details */}
              <View style={styles.detailsContainer}>
                <Text style={styles.modalTitle}>
                  Image #{selectedImage.index + 1}
                </Text>

                {exif?.description && (
                  <View style={styles.descriptionBox}>
                    <Text style={styles.descriptionText}>
                      {exif.description}
                    </Text>
                  </View>
                )}

                <View style={styles.detailRow}>
                  <Text style={styles.detailLabel}>Similarity:</Text>
                  <Text style={styles.detailValue}>{similarityPercent}%</Text>
                </View>

                <View style={styles.detailRow}>
                  <Text style={styles.detailLabel}>Path:</Text>
                  <Text style={styles.detailValue} numberOfLines={2}>
                    {selectedImage.path}
                  </Text>
                </View>

                <View style={styles.detailRow}>
                  <Text style={styles.detailLabel}>ID:</Text>
                  <Text style={styles.detailValue}>
                    {selectedImage.pid || selectedImage.id}
                  </Text>
                </View>

                {exif?.make && exif?.model && (
                  <View style={styles.detailRow}>
                    <Text style={styles.detailLabel}>Camera:</Text>
                    <Text style={styles.detailValue}>
                      {exif.make} {exif.model}
                    </Text>
                  </View>
                )}

                {exif?.dateTime && (
                  <View style={styles.detailRow}>
                    <Text style={styles.detailLabel}>Taken:</Text>
                    <Text style={styles.detailValue}>
                      {new Date(exif.dateTime).toLocaleString()}
                    </Text>
                  </View>
                )}

                {exif?.width && exif?.height && (
                  <View style={styles.detailRow}>
                    <Text style={styles.detailLabel}>Dimensions:</Text>
                    <Text style={styles.detailValue}>
                      {exif.width} × {exif.height}
                    </Text>
                  </View>
                )}

                {selectedImage.payload?.size && (
                  <View style={styles.detailRow}>
                    <Text style={styles.detailLabel}>Size:</Text>
                    <Text style={styles.detailValue}>
                      {(selectedImage.payload.size / 1024 / 1024).toFixed(2)} MB
                    </Text>
                  </View>
                )}

                {selectedImage.payload?.mdate && (
                  <View style={styles.detailRow}>
                    <Text style={styles.detailLabel}>Modified:</Text>
                    <Text style={styles.detailValue}>
                      {new Date(selectedImage.payload.mdate).toLocaleString()}
                    </Text>
                  </View>
                )}
              </View>

              {/* Close Button */}
              <TouchableOpacity
                style={styles.closeButton}
                onPress={() => setSelectedImage(null)}>
                <Text style={styles.closeButtonText}>Close</Text>
              </TouchableOpacity>
            </ScrollView>
          </View>
        </View>
      </Modal>
    );
  };

  if (!results || results.length === 0) {
    return null;
  }

  return (
    <View>
      <FlatList
        data={results}
        renderItem={renderItem}
        keyExtractor={(item, index) => item.id?.toString() || index.toString()}
        numColumns={COLUMN_COUNT}
        columnWrapperStyle={styles.row}
        scrollEnabled={false}
      />
      {renderDetailModal()}
    </View>
  );
};

const styles = StyleSheet.create({
  row: {
    justifyContent: 'space-between',
    marginBottom: CARD_MARGIN,
  },
  card: {
    width: CARD_WIDTH,
    backgroundColor: '#ffffff',
    borderRadius: 8,
    overflow: 'hidden',
    marginHorizontal: CARD_MARGIN / 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  imageContainer: {
    position: 'relative',
  },
  cardImage: {
    width: '100%',
    height: CARD_WIDTH,
    backgroundColor: '#f5f5f5',
  },
  badge: {
    position: 'absolute',
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 4,
    zIndex: 1,
  },
  rankBadge: {
    top: 6,
    left: 6,
    backgroundColor: '#2196f3',
  },
  similarityBadge: {
    top: 6,
    right: 6,
  },
  badgeText: {
    color: '#ffffff',
    fontSize: 10,
    fontWeight: 'bold',
  },
  cardContent: {
    padding: 8,
  },
  description: {
    fontSize: 11,
    fontStyle: 'italic',
    color: '#1976d2',
    marginBottom: 4,
    backgroundColor: '#e3f2fd',
    padding: 4,
    borderRadius: 4,
  },
  pathText: {
    fontSize: 10,
    color: '#666',
    marginBottom: 6,
  },
  progressContainer: {
    marginTop: 4,
  },
  progressBackground: {
    height: 4,
    backgroundColor: '#e0e0e0',
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    borderRadius: 2,
  },
  modalContainer: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: width - 32,
    maxHeight: '90%',
    backgroundColor: '#ffffff',
    borderRadius: 12,
    overflow: 'hidden',
  },
  scrollContent: {
    paddingTop: 16,
    paddingHorizontal: 8,
  },
  modalImage: {
    width: '100%',
    height: 300,
    backgroundColor: '#f5f5f5',
  },
  detailsContainer: {
    padding: 16,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  descriptionBox: {
    backgroundColor: '#e3f2fd',
    padding: 12,
    borderRadius: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#2196f3',
    marginBottom: 12,
  },
  descriptionText: {
    fontSize: 14,
    fontStyle: 'italic',
    color: '#1976d2',
  },
  detailRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  detailLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
    width: 100,
  },
  detailValue: {
    fontSize: 14,
    color: '#333',
    flex: 1,
  },
  closeButton: {
    backgroundColor: '#2196f3',
    padding: 16,
    alignItems: 'center',
    margin: 16,
    borderRadius: 8,
  },
  closeButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default SearchResults;
