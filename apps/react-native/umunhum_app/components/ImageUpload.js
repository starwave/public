import React, {useState} from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Image,
  StyleSheet,
  Alert,
  ActivityIndicator,
} from 'react-native';
import {launchImageLibrary, launchCamera} from 'react-native-image-picker';

const ImageUpload = ({onUpload, loading}) => {
  const [selectedImage, setSelectedImage] = useState(null);

  const showImagePicker = () => {
    Alert.alert('Select Image', 'Choose an option', [
      {
        text: 'Take Photo',
        onPress: () => openCamera(),
      },
      {
        text: 'Choose from Library',
        onPress: () => openImageLibrary(),
      },
      {
        text: 'Cancel',
        style: 'cancel',
      },
    ]);
  };

  const openCamera = () => {
    const options = {
      mediaType: 'photo',
      quality: 0.8,
      maxWidth: 2048,
      maxHeight: 2048,
    };

    launchCamera(options, response => {
      handleImageResponse(response);
    });
  };

  const openImageLibrary = () => {
    const options = {
      mediaType: 'photo',
      quality: 0.8,
      maxWidth: 2048,
      maxHeight: 2048,
    };

    launchImageLibrary(options, response => {
      handleImageResponse(response);
    });
  };

  const handleImageResponse = response => {
    if (response.didCancel) {
      return;
    }

    if (response.errorCode) {
      Alert.alert('Error', response.errorMessage || 'Failed to select image');
      return;
    }

    if (response.assets && response.assets.length > 0) {
      const asset = response.assets[0];

      // Validate file size (10MB max)
      if (asset.fileSize && asset.fileSize > 10 * 1024 * 1024) {
        Alert.alert('Error', 'File size must be less than 10MB');
        return;
      }

      setSelectedImage(asset);
    }
  };

  const handleClear = () => {
    setSelectedImage(null);
  };

  const handleSearch = () => {
    if (selectedImage && onUpload) {
      onUpload(selectedImage);
    }
  };

  return (
    <View style={styles.container}>
      {!selectedImage ? (
        // Upload button
        <TouchableOpacity
          style={styles.uploadArea}
          onPress={showImagePicker}
          disabled={loading}>
          <View style={styles.uploadContent}>
            <Text style={styles.uploadIcon}>☁️</Text>
            <Text style={styles.uploadTitle}>Tap to Upload Image</Text>
            <Text style={styles.uploadSubtitle}>
              Supported formats: JPG, PNG, BMP, WEBP, GIF
            </Text>
            <Text style={styles.uploadSubtitle}>Maximum size: 10MB</Text>
          </View>
        </TouchableOpacity>
      ) : (
        // Image preview and actions
        <View>
          <View style={styles.previewContainer}>
            <Image
              source={{uri: selectedImage.uri}}
              style={styles.previewImage}
              resizeMode="contain"
            />
          </View>

          {selectedImage.fileName && (
            <Text style={styles.fileName}>
              {selectedImage.fileName}
              {selectedImage.fileSize &&
                ` (${(selectedImage.fileSize / 1024).toFixed(2)} KB)`}
            </Text>
          )}

          <View style={styles.buttonContainer}>
            <TouchableOpacity
              style={[styles.button, styles.clearButton]}
              onPress={handleClear}
              disabled={loading}>
              <Text style={styles.clearButtonText}>Clear</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.button,
                styles.searchButton,
                loading && styles.buttonDisabled,
              ]}
              onPress={handleSearch}
              disabled={loading}>
              {loading ? (
                <ActivityIndicator size="small" color="#ffffff" />
              ) : (
                <Text style={styles.searchButtonText}>
                  🔍 Search Similar Images
                </Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  uploadArea: {
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: '#ccc',
    borderRadius: 12,
    padding: 48,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  uploadContent: {
    alignItems: 'center',
  },
  uploadIcon: {
    fontSize: 64,
    marginBottom: 16,
  },
  uploadTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  uploadSubtitle: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  previewContainer: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  previewImage: {
    width: '100%',
    height: 300,
    backgroundColor: '#f5f5f5',
  },
  fileName: {
    fontSize: 12,
    color: '#ffffff',
    textAlign: 'center',
    marginBottom: 16,
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'center',
  },
  button: {
    flex: 1,
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  clearButton: {
    backgroundColor: '#ffffff',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  clearButtonText: {
    color: '#333',
    fontSize: 16,
    fontWeight: '600',
  },
  searchButton: {
    backgroundColor: '#1976d2',
  },
  searchButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonDisabled: {
    opacity: 0.6,
  },
});

export default ImageUpload;
