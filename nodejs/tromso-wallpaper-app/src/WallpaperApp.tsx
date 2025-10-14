import React, { useState, useEffect, useCallback, useRef } from 'react';

interface ThemeConfig {
  Label: string;
  Config: string;
}

interface TouchPosition {
  xDown: number | null;
  yDown: number | null;
  xUp: number | null;
  yUp: number | null;
}

const WallpaperApp: React.FC = () => {
  const [pause, setPause] = useState(false);
  const [theme, setTheme] = useState('default2');
  const [dimension, setDimension] = useState('1920x1080');
  const [customConfigString, setCustomConfigString] = useState('/;;#sn#|#nd#');
  const [showConfig, setShowConfig] = useState(false);
  const [saver, setSaver] = useState(true);
  const [themeLibs, setThemeLibs] = useState<ThemeConfig[]>([]);
  const [showSplash, setShowSplash] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [currentImageSrc, setCurrentImageSrc] = useState<string>('');

  const cacheRef = useRef<HTMLImageElement[]>([]);
  const indexRef = useRef(-1);
  const intervalTimerRef = useRef<NodeJS.Timeout | null>(null);
  const saverTimerRef = useRef<NodeJS.Timeout | null>(null);
  const touchPosRef = useRef<TouchPosition>({
    xDown: null,
    yDown: null,
    xUp: null,
    yUp: null
  });

  const API_BASE = 'http://192.168.1.111:8080';
  const INTERVAL = 7000;
  const SAVER_TIME = 5000;

  // Calculate dimension based on screen size
  const adjustDimension = useCallback(() => {
    const screenWidth = window.innerWidth;
    const screenHeight = window.innerHeight;
    const ratio = (screenWidth * 1000) / screenHeight;

    let newDimension = '1920x1080';

    if (ratio > 1150 && ratio <= 1550) {
      newDimension = '2732x2048';
    } else if (ratio > 1550 && ratio <= 1950) {
      newDimension = screenWidth > 1920 ? '3840x2160' : '1920x1080';
    } else if (ratio > 1950 && ratio <= 2350) {
      newDimension = '2688x1242';
    } else if (ratio > 600 && ratio <= 900) {
      newDimension = '2048x2732';
    } else if (ratio > 300 && ratio <= 700) {
      newDimension = '1080x2280';
    } else {
      newDimension = `${screenWidth}x${screenHeight}`;
    }

    setDimension(newDimension);
  }, []);

  // Get option string for custom theme
  const getOptionString = useCallback(() => {
    if (theme === 'custom') {
      const optionData = ` -c '${customConfigString}'`;
      return `&o=${encodeURIComponent(optionData)}`;
    }
    return '';
  }, [theme, customConfigString]);

  // Reset cache
  const resetCache = useCallback(() => {
    cacheRef.current = [];
    indexRef.current = -1;
  }, []);

  // Navigate wallpaper
  const navigateWallpaper = useCallback((offset: number) => {
    console.log('navigateWallpaper called with offset:', offset);
    const cache = cacheRef.current;
    const index = indexRef.current;
    console.log('Current cache length:', cache.length, 'Current index:', index);

    if (offset === 1) {
      if (index === cache.length - 1) {
        console.log('Creating new image...');
        const newImage = new Image();
        const optionString = getOptionString();
        const imageUrl = `${API_BASE}/ngorongoro?a=tweb&d=${dimension}&t=${theme}${optionString}&${new Date().getTime()}`;
        console.log('Image URL:', imageUrl);

        newImage.src = imageUrl;

        // Add load handler to update display
        newImage.onload = () => {
          console.log('✅ Image loaded successfully:', newImage.src);
          setCurrentImageSrc(newImage.src);
        };

        newImage.onerror = (error) => {
          console.error('❌ Failed to load image:', newImage.src, error);
        };

        if (cache.length > 20) {
          cache.shift();
        } else {
          indexRef.current++;
        }
        cache.push(newImage);
        console.log('New cache length:', cache.length, 'New index:', indexRef.current);
      } else {
        console.log('Using cached image at index:', index + 1);
        indexRef.current++;
        const img = cache[indexRef.current];
        if (img) {
          console.log('Setting image from cache:', img.src);
          setCurrentImageSrc(img.src);
        }
      }
    } else {
      if (index > 0) {
        console.log('Going back to index:', index - 1);
        indexRef.current--;
        const img = cache[indexRef.current];
        if (img) {
          console.log('Setting previous image:', img.src);
          setCurrentImageSrc(img.src);
        }
      }
    }
  }, [dimension, theme, getOptionString]);

  // Switch wallpaper automatically
  const switchWallpaper = useCallback(() => {
    if (!pause) {
      navigateWallpaper(1);
    }
  }, [pause, navigateWallpaper]);

  // Reset saver timer
  const resetSaverTimer = useCallback(() => {
    if (saverTimerRef.current) {
      clearTimeout(saverTimerRef.current);
    }
    if (saver && !pause) {
      saverTimerRef.current = setTimeout(() => {
        setPause(true);
      }, SAVER_TIME * 60);
    }
  }, [saver, pause]);

  // Restart interval timer
  const restartTimer = useCallback(() => {
    if (intervalTimerRef.current) {
      clearInterval(intervalTimerRef.current);
    }
    intervalTimerRef.current = setInterval(switchWallpaper, INTERVAL);
    resetSaverTimer();
  }, [switchWallpaper, resetSaverTimer]);

  // Handle theme change
  const handleThemeChange = useCallback((newTheme: string) => {
    setTheme(newTheme);
    if (newTheme !== 'all') {
      resetCache();
    }
    localStorage.setItem('theme', newTheme);
    resetSaverTimer();
  }, [resetCache, resetSaverTimer]);

  // Handle custom config update
  const updateCustomConfig = useCallback((config: string) => {
    resetCache();
    setCustomConfigString(config);
    localStorage.setItem('customConfigString', config);
  }, [resetCache]);

  // Show custom config dialog
  const showCustomConfig = useCallback(() => {
    setPause(true);
    setShowConfig(true);

    fetch(`${API_BASE}/maramboi?a=g`)
      .then(res => res.json())
      .then((data: ThemeConfig[]) => {
        const libs = [
          { Label: 'Current', Config: customConfigString },
          { Label: 'Default', Config: '/;;#sn#|#nd#' },
          ...data
        ];
        setThemeLibs(libs);
      })
      .catch(console.error);
  }, [customConfigString]);

  // Handle fullscreen toggle
  const toggleFullscreen = useCallback(() => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen();
      setIsFullscreen(true);
    } else {
      document.exitFullscreen();
      setIsFullscreen(false);
    }
    resetSaverTimer();
  }, [resetSaverTimer]);

  // Touch handlers for swipe gestures
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    const touch = e.touches[0];
    touchPosRef.current.xDown = touch.clientX;
    touchPosRef.current.yDown = touch.clientY;
  }, []);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    const touch = e.touches[0];
    touchPosRef.current.xUp = touch.clientX;
    touchPosRef.current.yUp = touch.clientY;
  }, []);

  const handleTouchEnd = useCallback(() => {
    const { xDown, yDown, xUp, yUp } = touchPosRef.current;

    if (!xDown || !yDown || !xUp || !yUp) return;

    const xDiff = xDown - xUp;
    const yDiff = yDown - yUp;

    if (Math.abs(xDiff) > Math.abs(yDiff)) {
      if (Math.abs(xDiff) < 100) return;

      if (xDiff > 0) {
        navigateWallpaper(1);
      } else {
        navigateWallpaper(-1);
      }
    } else {
      if (Math.abs(yDiff) < 100) return;

      const themes = ['default1', 'default2', 'custom', 'photo', 'recent', 'wallpaper', 'landscape', 'movie1', 'movie2', 'special1', 'special2', 'all'];
      const currentIndex = themes.indexOf(theme);

      if (yDiff > 0) {
        const newIndex = currentIndex > 0 ? currentIndex - 1 : themes.length - 1;
        handleThemeChange(themes[newIndex]);
      } else {
        const newIndex = currentIndex < themes.length - 1 ? currentIndex + 1 : 0;
        handleThemeChange(themes[newIndex]);
      }
    }

    touchPosRef.current = { xDown: null, yDown: null, xUp: null, yUp: null };
  }, [theme, handleThemeChange, navigateWallpaper]);

  // Handle double click to show config
  const handleDoubleClick = useCallback((e: React.MouseEvent) => {
    const x = e.clientX;
    const y = e.clientY;
    const centerX = window.innerWidth / 2;
    const centerY = window.innerHeight / 2;

    if (Math.abs(x - centerX) < 200 && Math.abs(y - centerY) < 200) {
      showCustomConfig();
    }
  }, [showCustomConfig]);

  // Initialize on mount
  useEffect(() => {
    adjustDimension();

    const savedTheme = localStorage.getItem('theme') || 'default2';
    const savedConfig = localStorage.getItem('customConfigString') || '/;;#sn#|#nd#';

    setTheme(savedTheme);
    setCustomConfigString(savedConfig);

    setTimeout(() => setShowSplash(false), 4000);

    window.addEventListener('resize', adjustDimension);
    return () => window.removeEventListener('resize', adjustDimension);
  }, [adjustDimension]);

  // Load first image after component is ready
  useEffect(() => {
    // Small delay to ensure everything is initialized
    const timer = setTimeout(() => {
      console.log('Loading initial wallpaper...');
      navigateWallpaper(1);
    }, 500);

    return () => clearTimeout(timer);
  }, [navigateWallpaper]);

  // Setup timer
  useEffect(() => {
    restartTimer();
    return () => {
      if (intervalTimerRef.current) clearInterval(intervalTimerRef.current);
      if (saverTimerRef.current) clearTimeout(saverTimerRef.current);
    };
  }, [restartTimer]);

  return (
    <div
      className="relative w-screen h-screen bg-black overflow-hidden"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      onDoubleClick={handleDoubleClick}
    >
      {/* Wallpaper Image */}
      <div className="absolute inset-0 flex items-center justify-center">
        {currentImageSrc ? (
          <img
            src={currentImageSrc}
            alt="Wallpaper"
            className="max-w-full max-h-full object-contain"
          />
        ) : (
          <div className="text-white text-2xl">Loading...</div>
        )}
      </div>

      {/* Theme Selector */}
      <select
        value={theme}
        onChange={(e) => handleThemeChange(e.target.value)}
        className="absolute right-[5%] top-[7%] bg-gray-700 text-white px-5 py-3 rounded opacity-10 hover:opacity-100 hover:bg-black transition-opacity"
      >
        <option value="default1">Default</option>
        <option value="default2">Default+</option>
        <option value="custom">Custom</option>
        <option value="photo">Photo</option>
        <option value="recent">Recent</option>
        <option value="wallpaper">Wallpaper</option>
        <option value="landscape">Landscape</option>
        <option value="movie1">Movie</option>
        <option value="movie2">* Movie+ *</option>
        <option value="special1">* Special *</option>
        <option value="special2">* Special+ *</option>
        <option value="all">* All *</option>
      </select>

      {/* Control Buttons */}
      <button
        onClick={toggleFullscreen}
        className="absolute left-[5%] top-[7%] bg-gray-700 text-white px-5 py-3 rounded opacity-10 hover:opacity-100 hover:bg-black transition-opacity"
      >
        {isFullscreen ? 'Normal' : 'Full'}
      </button>

      <button
        onClick={() => { restartTimer(); navigateWallpaper(-1); }}
        className="absolute left-[3%] top-[48%] bg-gray-700 text-white px-5 py-3 rounded opacity-10 hover:opacity-100 hover:bg-black transition-opacity"
      >
        ⏮
      </button>

      <button
        onClick={() => { restartTimer(); navigateWallpaper(1); }}
        className="absolute right-[5%] top-[48%] bg-gray-700 text-white px-5 py-3 rounded opacity-10 hover:opacity-100 hover:bg-black transition-opacity"
      >
        ⏭
      </button>

      <button
        onClick={() => { setPause(!pause); resetSaverTimer(); }}
        className="absolute right-[5%] bottom-[5%] bg-gray-700 text-white px-5 py-3 rounded opacity-10 hover:opacity-100 hover:bg-black transition-opacity"
      >
        {pause ? '▶' : '⏸'}
      </button>

      {/* Config Dialog */}
      {showConfig && (
        <div className="fixed inset-0 flex items-center justify-center z-50 bg-black bg-opacity-50">
          <div className="bg-white p-6 rounded-lg w-[500px] max-h-[740px] overflow-auto">
            <div className="flex gap-4 mb-4">
              <button
                onClick={() => {
                  updateCustomConfig(customConfigString);
                  setShowConfig(false);
                  setPause(false);
                  resetSaverTimer();
                }}
                className="px-6 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 w-[150px]"
              >
                OK
              </button>
              <button
                onClick={() => {
                  setShowConfig(false);
                  setPause(false);
                  resetSaverTimer();
                }}
                className="px-6 py-2 bg-gray-500 text-white rounded hover:bg-gray-600 w-[150px]"
              >
                Cancel
              </button>
            </div>

            <div className="mb-4">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={saver}
                  onChange={(e) => setSaver(e.target.checked)}
                />
                <span>Saver</span>
              </label>
            </div>

            <textarea
              value={customConfigString}
              onChange={(e) => setCustomConfigString(e.target.value)}
              rows={4}
              className="w-full p-2 border border-gray-300 rounded mb-4"
            />

            <div className="border border-gray-300">
              <table className="w-full">
                <tbody className="block max-h-[400px] overflow-y-auto">
                  {themeLibs.map((lib, idx) => (
                    <tr key={idx} className="border-b">
                      <td className="p-2 w-[270px]">{lib.Label}</td>
                      <td className="p-2">
                        <button
                          onClick={() => setCustomConfigString(lib.Config)}
                          className="px-4 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
                        >
                          Set
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Splash Screen */}
      {showSplash && (
        <div className="fixed inset-0 flex items-center justify-center z-[1002] bg-white animate-fade-out">
          <div className="border-8 border-cyan-400 p-4">
            <img src="/tromso.png" alt="Tromso" width={450} height={450} />
          </div>
        </div>
      )}
    </div>
  );
};

export default WallpaperApp;