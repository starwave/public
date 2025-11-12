const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SOURCE_IMAGE = path.join(__dirname, '../../../nodejs/umunhum/public/omunhum.png');

// iOS icon sizes
const iosIcons = [
  { size: 20, scale: 2, idiom: 'iphone' },
  { size: 20, scale: 3, idiom: 'iphone' },
  { size: 29, scale: 2, idiom: 'iphone' },
  { size: 29, scale: 3, idiom: 'iphone' },
  { size: 40, scale: 2, idiom: 'iphone' },
  { size: 40, scale: 3, idiom: 'iphone' },
  { size: 60, scale: 2, idiom: 'iphone' },
  { size: 60, scale: 3, idiom: 'iphone' },
  { size: 1024, scale: 1, idiom: 'ios-marketing' }
];

// Android icon sizes
const androidIcons = [
  { folder: 'mipmap-mdpi', size: 48 },
  { folder: 'mipmap-hdpi', size: 72 },
  { folder: 'mipmap-xhdpi', size: 96 },
  { folder: 'mipmap-xxhdpi', size: 144 },
  { folder: 'mipmap-xxxhdpi', size: 192 }
];

console.log('Generating app icons from:', SOURCE_IMAGE);

// Check if magick or sips is available
let converter = 'sips'; // Default for macOS
try {
  execSync('which magick', { stdio: 'ignore' });
  converter = 'magick';
} catch (e) {
  try {
    execSync('which sips', { stdio: 'ignore' });
    converter = 'sips';
  } catch (e) {
    console.error('Error: Neither ImageMagick (magick) nor sips found.');
    console.error('Please install ImageMagick: brew install imagemagick');
    process.exit(1);
  }
}

console.log('Using converter:', converter);

// Generate iOS icons
const iosIconsDir = path.join(__dirname, 'ios/umunhum_app/Images.xcassets/AppIcon.appiconset');
fs.mkdirSync(iosIconsDir, { recursive: true });

const iosContents = {
  images: [],
  info: {
    version: 1,
    author: 'xcode'
  }
};

iosIcons.forEach(icon => {
  const actualSize = icon.size * icon.scale;
  const filename = `icon-${icon.size}@${icon.scale}x.png`;
  const outputPath = path.join(iosIconsDir, filename);

  if (converter === 'magick') {
    execSync(`magick "${SOURCE_IMAGE}" -resize ${actualSize}x${actualSize} "${outputPath}"`);
  } else {
    execSync(`sips -z ${actualSize} ${actualSize} "${SOURCE_IMAGE}" --out "${outputPath}"`);
  }

  iosContents.images.push({
    size: `${icon.size}x${icon.size}`,
    idiom: icon.idiom,
    filename: filename,
    scale: `${icon.scale}x`
  });

  console.log(`Generated iOS icon: ${filename} (${actualSize}x${actualSize})`);
});

fs.writeFileSync(
  path.join(iosIconsDir, 'Contents.json'),
  JSON.stringify(iosContents, null, 2)
);

// Generate Android icons
androidIcons.forEach(icon => {
  const androidIconDir = path.join(__dirname, `android/app/src/main/res/${icon.folder}`);
  fs.mkdirSync(androidIconDir, { recursive: true });

  const outputPath = path.join(androidIconDir, 'ic_launcher.png');
  const roundOutputPath = path.join(androidIconDir, 'ic_launcher_round.png');

  if (converter === 'magick') {
    execSync(`magick "${SOURCE_IMAGE}" -resize ${icon.size}x${icon.size} "${outputPath}"`);
    execSync(`magick "${SOURCE_IMAGE}" -resize ${icon.size}x${icon.size} "${roundOutputPath}"`);
  } else {
    execSync(`sips -z ${icon.size} ${icon.size} "${SOURCE_IMAGE}" --out "${outputPath}"`);
    execSync(`sips -z ${icon.size} ${icon.size} "${SOURCE_IMAGE}" --out "${roundOutputPath}"`);
  }

  console.log(`Generated Android icon: ${icon.folder}/ic_launcher.png (${icon.size}x${icon.size})`);
});

// Generate assets/icon.png for the app logo (used in App.js)
const assetsDir = path.join(__dirname, 'assets');
fs.mkdirSync(assetsDir, { recursive: true });
const assetIconPath = path.join(assetsDir, 'icon.png');

if (converter === 'magick') {
  execSync(`magick "${SOURCE_IMAGE}" -resize 512x512 "${assetIconPath}"`);
} else {
  execSync(`sips -z 512 512 "${SOURCE_IMAGE}" --out "${assetIconPath}"`);
}

console.log('Generated assets/icon.png (512x512)');
console.log('All icons generated successfully!');
