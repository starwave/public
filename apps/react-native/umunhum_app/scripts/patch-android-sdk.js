#!/usr/bin/env node

/**
 * Patch react-native-image-picker to use Android SDK 34 instead of 35
 * This avoids jlink transformation errors during release builds
 */

const fs = require('fs');
const path = require('path');

const buildGradlePath = path.join(
  __dirname,
  '../node_modules/react-native-image-picker/android/build.gradle'
);

if (fs.existsSync(buildGradlePath)) {
  let content = fs.readFileSync(buildGradlePath, 'utf8');

  // Replace compileSdkVersion 35 with 34
  if (content.includes('compileSdkVersion 35')) {
    content = content.replace('compileSdkVersion 35', 'compileSdkVersion 34');
    fs.writeFileSync(buildGradlePath, content, 'utf8');
    console.log('✓ Patched react-native-image-picker to use Android SDK 34');
  } else if (content.includes('compileSdkVersion 34')) {
    console.log('✓ react-native-image-picker already using Android SDK 34');
  } else {
    console.log('⚠ Could not find compileSdkVersion in react-native-image-picker build.gradle');
  }
} else {
  console.log('⚠ react-native-image-picker build.gradle not found - skipping patch');
}
