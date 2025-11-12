# Umunhum Image Search - Full React Native App

A full native React Native implementation of the Umunhum image similarity search application. This app uses **native React Native components** instead of WebView, providing a true native experience.

## App Information

- **iOS Bundle ID**: com.thirdwavesoft.umunhumri
- **Android Package Name**: com.thirdwavesoft.umunhumra
- **App Name**: Umunhum
- **Backend API**: https://umunhum.thirdwavesoft.com

## Features

### Native UI Components

Unlike the WebView version (umunhumapp), this app uses real native components:

- **View, Text, Image** → UIView, UILabel, UIImageView (iOS) / View, TextView, ImageView (Android)
- **ScrollView** → UIScrollView / ScrollView
- **TouchableOpacity** → Native touch handlers
- **FlatList** → UICollectionView / RecyclerView
- **Modal** → Native modal presentations

### Key Features

- 📷 **Image Upload**: Take photo or select from library using react-native-image-picker
- 🔍 **AI-Powered Search**: Find top 9 similar images using vector similarity
- 📊 **Results Grid**: 3-column native grid with smooth scrolling
- 🎯 **Similarity Scores**: Visual progress bars and percentage indicators
- 📱 **Detail View**: Full-screen native modal with image metadata
- 📷 **EXIF Data**: Display camera info, dimensions, dates, descriptions
- ⚡ **Native Performance**: Fast rendering with native components

## Architecture Comparison

### WebView App (umunhumapp)

```
React Native Container
  └── WebView
        └── HTML/CSS/JS (web app)
              └── DOM elements
```

### Full Native App (umunhum_app)

```
React Native JavaScript
  ├── Bridge (JSON messages)
  └── Native Layer
        ├── iOS: UIKit components
        └── Android: Material components
```

## Project Structure

```
umunhum_app/
├── App.js                    # Main app with search logic
├── components/
│   ├── ImageUpload.js        # Native image picker component
│   └── SearchResults.js      # Native results grid with FlatList
├── config.js                 # API configuration
├── assets/
│   └── icon.png              # App logo (512x512)
├── ios/                      # iOS native code
│   ├── umunhum_app.xcodeproj/
│   ├── umunhum_app/
│   │   ├── AppDelegate.h/mm
│   │   ├── Info.plist
│   │   └── Images.xcassets/  # iOS app icons
│   └── Podfile
├── android/                  # Android native code
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   ├── java/com/thirdwavesoft/umunhumra/
│   │   │   └── res/          # Android app icons
│   │   └── build.gradle
│   └── build.gradle
└── generate-icons.js         # Icon generation script
```

## Native Components Used

### Image Upload (ImageUpload.js)

- **TouchableOpacity** - Native button with iOS/Android touch feedback
- **Image** - Native image renderer (uses UIImageView/ImageView)
- **ActivityIndicator** - Native loading spinner
- **Alert** - Native alert dialogs
- **react-native-image-picker** - Native camera and photo library access

### Search Results (SearchResults.js)

- **FlatList** - Highly optimized native list (UICollectionView/RecyclerView)
- **Modal** - Native modal presentations with animations
- **ScrollView** - Native smooth scrolling
- **Dimensions** - Native device dimensions API

### Styling

- **StyleSheet.create()** - Compiled to native styles
- All styles converted to native platform equivalents
- No CSS - pure React Native styling

## Installation

1. Install Node dependencies:

```bash
npm install
```

2. For iOS, install CocoaPods:

```bash
cd ios
pod install
cd ..
```

## Running the App

### iOS

```bash
npm run ios
```

Or open `ios/umunhum_app.xcworkspace` in Xcode and run.

### Android

```bash
npm run android
```

Or open the `android` folder in Android Studio and run.

## Permissions

### iOS (Info.plist)

- **NSCameraUsageDescription**: Camera access for taking photos
- **NSPhotoLibraryUsageDescription**: Photo library access for selecting images

### Android (AndroidManifest.xml)

- **CAMERA**: Camera access
- **READ_EXTERNAL_STORAGE**: Read photos (Android 12 and below)
- **READ_MEDIA_IMAGES**: Read photos (Android 13+)
- **INTERNET**: API access

## Configuration

Edit `config.js` to change the API endpoint:

```javascript
export const API_URL = 'https://umunhum.thirdwavesoft.com';
// or for local development:
// export const API_URL = 'http://localhost:3002';
```

## API Integration

The app communicates with the backend API:

### Endpoints Used

- `POST /api/search/similar` - Upload image and get similar results
- `GET /api/image?path=...` - Fetch result images
- `GET /api/image/exif?path=...` - Get EXIF metadata

### Request Format

```javascript
const formData = new FormData();
formData.append('image', {
  uri: imageData.uri,
  type: imageData.type,
  name: imageData.fileName,
});
```

## App Icons

Icons are generated from the umunhum source image using `generate-icons.js`:

```bash
node generate-icons.js
```

This creates:

- **iOS**: 9 icon sizes (20pt to 1024pt) in all scales
- **Android**: 5 densities (mdpi to xxxhdpi)
- **Assets**: 512x512 icon for in-app logo

## Building for Release

### iOS

1. Open `ios/umunhum_app.xcworkspace` in Xcode
2. Select "Product" > "Archive"
3. Follow App Store Connect process

### Android

```bash
cd android
./gradlew assembleRelease
```

APK location: `android/app/build/outputs/apk/release/app-release.apk`

## Comparison: WebView vs Full Native

| Feature       | WebView (umunhumapp) | Full Native (umunhum_app) |
| ------------- | -------------------- | ------------------------- |
| UI Components | HTML/CSS in WebView  | Native UIKit/Material     |
| Performance   | Web rendering        | Native rendering          |
| Feel          | Website in app       | True native app           |
| Offline       | Needs internet       | Could work offline\*      |
| Updates       | Update website       | Update & publish app      |
| Development   | Reuse web code       | Separate codebase         |
| Camera        | Limited access       | Full native access        |
| Gestures      | Web touch events     | Native gestures           |
| Animations    | CSS animations       | Native animations         |
| Memory        | Higher (browser)     | Lower (native)            |

\*Offline support would require additional implementation

## Dependencies

- **react-native**: 0.73.0
- **react**: 18.2.0
- **react-native-image-picker**: ^7.1.0 - Native camera and photo library
- **react-native-vector-icons**: ^10.0.3 - Icon fonts
- **axios**: ^1.6.2 - HTTP client

## Educational Value

This project demonstrates:

1. **React Native Components → Native SDK mapping**

   - How `<View>` becomes UIView (iOS) or View (Android)
   - How styling translates to native properties
   - How JavaScript controls native UI

2. **Bridge Architecture**

   - JavaScript runtime separate from native
   - Asynchronous message passing
   - Native module integration

3. **Native APIs**

   - Camera and photo library access
   - Permissions handling
   - File uploads with FormData

4. **Cross-Platform Development**
   - Single JavaScript codebase
   - Platform-specific configurations
   - Native project structure (Xcode/Android Studio)

## Troubleshooting

### iOS

- Clean build: Xcode > Product > Clean Build Folder
- Clear pods: `cd ios && rm -rf Pods && pod install`
- Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
- **Boost Error Fix**

```bash
  vi node_modules/react-native/third-party-podspecs/boost.podspec
  # replace source
  spec.source = { :http => 'https://archives.boost.io/release/1.83.0/source/boost_1_83_0.tar.gz' }
  brew install watchman
```

### Android

- Clean: `cd android && ./gradlew clean`
- Clear cache: `cd android && ./gradlew cleanBuildCache`
- Check Java version: `java -version` (needs Java 17)

### Image Picker

If camera/library doesn't work:

- Check Info.plist (iOS) has permission descriptions
- Check AndroidManifest.xml (Android) has permissions
- Request permissions at runtime if needed

## License

This is an educational project demonstrating full React Native implementation.
