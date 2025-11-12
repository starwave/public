# Umunhum App - Setup Guide

Complete setup instructions for the full React Native implementation of Umunhum Image Search.

## Prerequisites

### Required Software

- **Node.js**: v18 or higher
- **npm** or **yarn**
- **Git**

### iOS Development

- **macOS**: Required for iOS development
- **Xcode**: Latest version from App Store
- **CocoaPods**: Dependency manager for iOS

### Android Development

- **Android Studio**: Latest version
- **JDK**: Java Development Kit 17
- **Android SDK**: API Level 34

## Installation Steps

### 1. Clone and Navigate to Project

```bash
cd /Users/starwave/thirdwave_git/shared/react/native/umunhum_app
```

### 2. Install Node Dependencies

```bash
npm install
```

### 3. Install CocoaPods (iOS only)

CocoaPods is required to manage iOS native dependencies.

#### Check if CocoaPods is installed:

```bash
pod --version
```

#### If not installed, install using one of these methods:

**Option 1: Using Homebrew (Recommended)**

```bash
brew install cocoapods
```

# in case xcode-select is pointing at /Library/Developer/CommandLineTools, pod is not working

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcode-select -p
pod cache clean --all
rm -rf Pods Podfile.lock
pod repo update
```

**Option 2: Using gem**

```bash
sudo gem install cocoapods
```

**Option 3: Without sudo (if you have permission issues)**

```bash
gem install cocoapods
```

#### If you need to update Ruby gems first:

```bash
sudo gem update --system
sudo gem install cocoapods
```

#### Verify installation:

```bash
pod --version
```

### 4. Install iOS Pods

```bash
cd ios
pod install
cd ..
```

**Important**: After running `pod install`, always use the `.xcworkspace` file (not `.xcodeproj`) when opening in Xcode.

### 5. Verify Android Setup (Android only)

Check that Java 17 is installed:

```bash
java -version
```

Should show: `openjdk version "17"` or similar.

If not installed:

```bash
brew install openjdk@17
```

## Running the App

### iOS

**Option 1: Using CLI**

```bash
npm run ios
```

**Option 2: Using Xcode**

```bash
open ios/umunhum_app.xcworkspace
```

Then press the "Run" button in Xcode.

**Run on specific simulator:**

```bash
npm run ios -- --simulator="iPhone 15 Pro"
```

### Android

**Option 1: Using CLI**

```bash
npm run android
```

**Option 2: Using Android Studio**

1. Open Android Studio
2. Select "Open an Existing Project"
3. Navigate to `android` folder
4. Click "Run" button

**Run on specific device:**

```bash
adb devices  # List connected devices
npm run android -- --deviceId=<device-id>
```

### Start Metro Bundler Separately

If you want to start the Metro bundler in a separate terminal:

```bash
npm start
```

## Configuration

### Change API Endpoint

Edit `config.js`:

```javascript
export const API_URL = 'https://umunhum.thirdwavesoft.com';

// For local development:
// export const API_URL = 'http://localhost:3002';
```

**Note**: For local development on iOS simulator, use `http://localhost`.
For Android emulator, use `http://10.0.2.2` instead of `localhost`.

### Regenerate App Icons

If you update the source icon:

```bash
node generate-icons.js
```

This requires either ImageMagick or macOS `sips` command.

**Install ImageMagick (if needed):**

```bash
brew install imagemagick
```

## Troubleshooting

### iOS Issues

**Problem: "pod: command not found"**

```bash
# Install CocoaPods (see step 3 above)
brew install cocoapods
```

**Problem: Build fails with module errors**

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

**Problem: Xcode build fails**

```bash
# Clean build folder in Xcode:
# Product > Clean Build Folder (Cmd+Shift+K)

# Or from terminal:
cd ios
xcodebuild clean
cd ..
```

**Problem: "Could not find iPhone X simulator"**

```bash
# List available simulators:
xcrun simctl list devices

# Then run with specific device:
npm run ios -- --simulator="iPhone 15"
```

**Problem: Derived data issues**

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Android Issues

**Problem: "SDK location not found"**

Create `android/local.properties`:

```
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
```

**Problem: Gradle build fails**

```bash
cd android
./gradlew clean
cd ..
```

**Problem: "Unable to load script"**

```bash
# Make sure Metro bundler is running:
npm start

# In another terminal:
npm run android
```

**Problem: Java version mismatch**

```bash
# Check Java version:
java -version

# Install Java 17 if needed:
brew install openjdk@17

# Set JAVA_HOME:
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

**Problem: Port 8081 already in use**

```bash
# Kill process on port 8081:
lsof -ti:8081 | xargs kill -9

# Then restart:
npm start
```

### Image Picker Issues

**Problem: Camera/Photo Library not working**

**iOS:**

- Check that `ios/umunhum_app/Info.plist` contains:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
- Reinstall pods: `cd ios && pod install && cd ..`

**Android:**

- Check that `android/app/src/main/AndroidManifest.xml` contains permissions:
  - `android.permission.CAMERA`
  - `android.permission.READ_EXTERNAL_STORAGE`
  - `android.permission.READ_MEDIA_IMAGES`
- Verify permissions are granted in device settings

### Network Issues

**Problem: API requests failing**

**iOS Simulator:**

```javascript
// Use localhost:
export const API_URL = 'http://localhost:3002';
```

**Android Emulator:**

```javascript
// Use 10.0.2.2 instead of localhost:
export const API_URL = 'http://10.0.2.2:3002';
```

**Real Device:**

```javascript
// Use your computer's IP address:
export const API_URL = 'http://192.168.1.XXX:3002';
```

**Problem: HTTPS/SSL issues**

For development with self-signed certificates, you may need to disable certificate validation (not recommended for production).

## Development Tips

### Hot Reloading

React Native supports hot reloading:

- **iOS/Android**: Shake device or press `Cmd+D` (iOS) / `Cmd+M` (Android) to open developer menu
- Enable "Fast Refresh" in developer menu

### Debugging

**Open React Native Debugger:**

- Shake device → "Debug"
- Or press `Cmd+D` (iOS) / `Cmd+M` (Android) → "Debug"

**View Logs:**

```bash
# iOS:
npx react-native log-ios

# Android:
npx react-native log-android
```

**Chrome DevTools:**

- Open developer menu → "Debug"
- Open Chrome and navigate to `chrome://inspect`

### Clear Cache

If you encounter weird issues:

```bash
# Clear Metro cache:
npm start -- --reset-cache

# Clear all caches:
watchman watch-del-all
rm -rf node_modules
rm -rf ios/Pods
rm -rf ios/build
rm -rf android/build
rm -rf android/app/build
npm install
cd ios && pod install && cd ..
```

## Building for Release

### iOS

1. Open Xcode:

   ```bash
   open ios/umunhum_app.xcworkspace
   ```

2. Select "Any iOS Device" as target

3. Product → Archive

4. Follow App Store Connect upload wizard

**Generate IPA manually:**

```bash
cd ios
xcodebuild -workspace umunhum_app.xcworkspace \
  -scheme umunhum_app \
  -configuration Release \
  -archivePath build/umunhum_app.xcarchive \
  archive
```

### Android

**Generate Release APK:**

```bash
cd android
./gradlew assembleRelease
```

APK location: `android/app/build/outputs/apk/release/app-release.apk`

**Generate AAB (for Play Store):**

```bash
cd android
./gradlew bundleRelease
```

AAB location: `android/app/build/outputs/bundle/release/app-release.aab`

**Sign the release (production):**

1. Generate keystore:

   ```bash
   keytool -genkeypair -v -storetype PKCS12 \
     -keystore my-release-key.keystore \
     -alias my-key-alias \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Add to `android/gradle.properties`:

   ```
   MYAPP_RELEASE_STORE_FILE=my-release-key.keystore
   MYAPP_RELEASE_KEY_ALIAS=my-key-alias
   MYAPP_RELEASE_STORE_PASSWORD=****
   MYAPP_RELEASE_KEY_PASSWORD=****
   ```

3. Build signed release:
   ```bash
   cd android
   ./gradlew assembleRelease
   ```

## App Information

- **App Name**: Umunhum
- **iOS Bundle ID**: com.thirdwavesoft.umunhumri
- **Android Package**: com.thirdwavesoft.umunhumra
- **Version**: 1.0.0

## Project Structure

```
umunhum_app/
├── App.js                    # Main application
├── config.js                 # API configuration
├── components/               # React Native components
├── assets/                   # Images and resources
├── ios/                      # iOS native project
├── android/                  # Android native project
└── node_modules/             # Dependencies
```

## Getting Help

- **React Native Docs**: https://reactnative.dev/docs/getting-started
- **CocoaPods**: https://cocoapods.org/
- **Android Studio**: https://developer.android.com/studio

## Next Steps

After setup is complete:

1. Run the app on iOS/Android
2. Test image upload functionality
3. Verify API connection to backend
4. Test search results display
5. Try the detail modal view

Happy coding! 🚀
