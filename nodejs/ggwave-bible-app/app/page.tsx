'use client';

import { useEffect, useState, useRef } from 'react';

// Localization
const translations = {
  en: {
    start: 'Start',
    stop: 'Stop',
    loop: 'Loop',
    on: 'On',
    off: 'Off',
    line: 'Line',
    of: 'of'
  },
  ko: {
    start: '시작',
    stop: '정지',
    loop: '반복',
    on: '켜짐',
    off: '꺼짐',
    line: '줄',
    of: '/'
  }
};

// Painting images (30 images from IMG_1291.JPG to IMG_1320.JPG)
const paintings = Array.from({ length: 30 }, (_, i) => `/paintings/IMG_${1291 + i}.JPG`);

// Transition effects
const transitionEffects = [
  'fade',
  'slideLeft',
  'slideRight',
  'slideUp',
  'slideDown',
  'zoom',
  'rotate',
  'dissolve'
];

interface Ripple {
  id: number;
  x: number;
  y: number;
  timestamp: number;
}

export default function Home() {
  const [bibleText, setBibleText] = useState<string>('');
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLooping, setIsLooping] = useState(true); // Default on
  const [currentLine, setCurrentLine] = useState(0);
  const [visualData, setVisualData] = useState<number[]>([]);
  const [locale, setLocale] = useState<'en' | 'ko'>('en');
  const [currentPainting, setCurrentPainting] = useState(0);
  const [nextPainting, setNextPainting] = useState(1);
  const [transitionEffect, setTransitionEffect] = useState('fade');
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [ripples, setRipples] = useState<Ripple[]>([]);

  const audioContextRef = useRef<AudioContext | null>(null);
  const oscillatorsRef = useRef<OscillatorNode[]>([]);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationRef = useRef<number | null>(null);
  const isPlayingRef = useRef(false);
  const rippleIdRef = useRef(0);
  const playTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    // Detect browser locale
    const browserLang = navigator.language.toLowerCase();
    if (browserLang.startsWith('ko')) {
      setLocale('ko');
    }

    // Fetch bible text from public folder
    fetch('/bible.txt')
      .then(res => res.text())
      .then(data => setBibleText(data))
      .catch(err => console.error('Error fetching bible text:', err));

    // Transition paintings every 10 seconds when playing
    const transitionInterval = setInterval(() => {
      if (isPlayingRef.current) {
        transitionPainting();
      }
    }, 10000);

    // Clean up old ripples every 100ms
    const rippleCleanup = setInterval(() => {
      const now = Date.now();
      setRipples(prev => prev.filter(r => now - r.timestamp < 1000));
    }, 100);

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
      stopAudio();
      clearInterval(transitionInterval);
      clearInterval(rippleCleanup);
    };
  }, []);

  const t = translations[locale];

  const stopAudio = () => {
    // Clear the scheduled playLine timeout
    if (playTimeoutRef.current) {
      clearTimeout(playTimeoutRef.current);
      playTimeoutRef.current = null;
    }

    oscillatorsRef.current.forEach(osc => {
      try {
        osc.stop();
        osc.disconnect();
      } catch {
        // Already stopped
      }
    });
    oscillatorsRef.current = [];

    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current);
      animationRef.current = null;
    }
    setVisualData([]);
    setRipples([]); // Clear all ripples
    isPlayingRef.current = false;
  };

  // Generate audio tones from text (ggwave-like encoding)
  const textToAudio = (text: string): number[] => {
    const frequencies: number[] = [];
    const baseFreq = 1000; // Start at 1kHz
    const freqStep = 100; // 100Hz steps

    // Convert each character to a frequency
    for (let i = 0; i < text.length; i++) {
      const charCode = text.charCodeAt(i);
      const freq = baseFreq + (charCode % 20) * freqStep;
      frequencies.push(freq);
    }

    return frequencies;
  };

  const playLine = async (lineIndex: number) => {
    if (!bibleText) return;

    const lines = bibleText.split('\n').filter(line => line.trim());
    if (lineIndex >= lines.length) {
      if (isLooping && isPlayingRef.current) {
        setCurrentLine(0);
        playTimeoutRef.current = setTimeout(() => playLine(0), 100);
      } else {
        setIsPlaying(false);
        isPlayingRef.current = false;
        setCurrentLine(0);
      }
      return;
    }

    const line = lines[lineIndex];
    setCurrentLine(lineIndex);

    try {
      // Initialize audio context if needed
      if (!audioContextRef.current) {
        const AudioContextClass = window.AudioContext || (window as typeof window & { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
        audioContextRef.current = new AudioContextClass();
      }

      // Create analyser
      if (!analyserRef.current) {
        analyserRef.current = audioContextRef.current.createAnalyser();
        analyserRef.current.fftSize = 256;
        analyserRef.current.connect(audioContextRef.current.destination);
      }

      // Generate frequencies from text
      const frequencies = textToAudio(line);
      const toneDuration = 0.05; // 50ms per character
      const totalDuration = frequencies.length * toneDuration;

      // Create oscillators for each character
      const startTime = audioContextRef.current.currentTime;
      oscillatorsRef.current = [];

      frequencies.forEach((freq, index) => {
        const oscillator = audioContextRef.current!.createOscillator();
        const gainNode = audioContextRef.current!.createGain();

        oscillator.type = 'sine';
        oscillator.frequency.setValueAtTime(freq, startTime + index * toneDuration);

        // Envelope
        gainNode.gain.setValueAtTime(0, startTime + index * toneDuration);
        gainNode.gain.linearRampToValueAtTime(0.1, startTime + index * toneDuration + 0.01);
        gainNode.gain.linearRampToValueAtTime(0, startTime + index * toneDuration + toneDuration);

        oscillator.connect(gainNode);
        gainNode.connect(analyserRef.current!);

        oscillator.start(startTime + index * toneDuration);
        oscillator.stop(startTime + index * toneDuration + toneDuration);

        oscillatorsRef.current.push(oscillator);
      });

      // Start visualization
      visualize();

      // Schedule next line and store the timeout
      playTimeoutRef.current = setTimeout(() => {
        if (isPlayingRef.current) {
          playLine(lineIndex + 1);
        }
      }, totalDuration * 1000 + 200);

    } catch (err) {
      console.error('Error playing line:', err);
      setIsPlaying(false);
      isPlayingRef.current = false;
    }
  };

  // Transition to next painting with random effect over 3 seconds
  const transitionPainting = () => {
    // Pick random transition effect
    const randomEffect = transitionEffects[Math.floor(Math.random() * transitionEffects.length)];
    setTransitionEffect(randomEffect);

    // Pick random next painting
    const randomPainting = Math.floor(Math.random() * paintings.length);
    setNextPainting(randomPainting);

    setIsTransitioning(true);

    // Complete transition after 3 seconds
    setTimeout(() => {
      setCurrentPainting(randomPainting);
      setIsTransitioning(false);
    }, 3000);
  };

  const visualize = () => {
    if (!analyserRef.current) return;

    const bufferLength = analyserRef.current.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    let lastRippleTime = 0;
    let frameCount = 0;

    const draw = () => {
      if (!analyserRef.current || !isPlayingRef.current) {
        return;
      }

      analyserRef.current.getByteFrequencyData(dataArray);

      // Take only the active frequency range and stretch it across full width
      const activeData = Array.from(dataArray).slice(0, 20);
      const displayData: number[] = [];
      const targetBars = 112;
      for (let i = 0; i < targetBars; i++) {
        const sourceIndex = Math.floor((i * activeData.length) / targetBars);
        displayData.push(activeData[sourceIndex]);
      }
      setVisualData(displayData);

      // Create ripples based on frequency peaks (throttled and limited)
      frameCount++;
      const now = Date.now();
      if (now - lastRippleTime > 200 && frameCount % 3 === 0) { // Create ripple every 200ms max, every 3rd frame
        const maxFreq = Math.max(...activeData);
        if (maxFreq > 30) { // Threshold for creating ripple
          const peakIndex = activeData.indexOf(maxFreq);
          const frequency = 1000 + peakIndex * 100; // Reconstruct frequency

          // Limit total ripples to 5 at once
          setRipples(prev => {
            if (prev.length >= 5) {
              return prev; // Don't add more if already at limit
            }
            const newRipple: Ripple = {
              id: rippleIdRef.current++,
              x: ((peakIndex / activeData.length) * 80 + 10),
              y: ((frequency % 500) / 500) * 80 + 10,
              timestamp: now
            };
            return [...prev, newRipple];
          });

          lastRippleTime = now;
        }
      }

      animationRef.current = requestAnimationFrame(draw);
    };

    draw();
  };

  const handleTogglePlay = () => {
    if (isPlaying) {
      stopAudio();
      setIsPlaying(false);
      setCurrentLine(0);
    } else {
      setIsPlaying(true);
      isPlayingRef.current = true;
      playLine(0);
    }
  };

  const handleToggleLoop = () => {
    setIsLooping(!isLooping);
  };

  const lines = bibleText.split('\n').filter(line => line.trim());

  // Get transition style based on effect type
  const getTransitionStyle = (isNext: boolean) => {
    if (!isTransitioning) {
      return isNext ? { opacity: 0 } : { opacity: 1 };
    }

    const baseStyle = {
      transition: 'all 3s ease-in-out'
    };

    switch (transitionEffect) {
      case 'fade':
        return { ...baseStyle, opacity: isNext ? 1 : 0 };
      case 'slideLeft':
        return { ...baseStyle, opacity: isNext ? 1 : 0, transform: isNext ? 'translateX(0)' : 'translateX(-100%)' };
      case 'slideRight':
        return { ...baseStyle, opacity: isNext ? 1 : 0, transform: isNext ? 'translateX(0)' : 'translateX(100%)' };
      case 'slideUp':
        return { ...baseStyle, opacity: isNext ? 1 : 0, transform: isNext ? 'translateY(0)' : 'translateY(-100%)' };
      case 'slideDown':
        return { ...baseStyle, opacity: isNext ? 1 : 0, transform: isNext ? 'translateY(0)' : 'translateY(100%)' };
      case 'zoom':
        return { ...baseStyle, opacity: isNext ? 1 : 0, transform: isNext ? 'scale(1)' : 'scale(1.5)' };
      case 'rotate':
        return { ...baseStyle, opacity: isNext ? 1 : 0, transform: isNext ? 'rotate(0deg) scale(1)' : 'rotate(90deg) scale(0.5)' };
      case 'dissolve':
        return { ...baseStyle, opacity: isNext ? 1 : 0, filter: isNext ? 'blur(0px)' : 'blur(20px)' };
      default:
        return { ...baseStyle, opacity: isNext ? 1 : 0 };
    }
  };

  return (
    <div className="min-h-screen relative overflow-hidden flex flex-col items-center justify-center p-8">
      {/* Background Paintings with Purple Overlay */}
      <div className="absolute inset-0 z-0">
        {/* Current Painting */}
        <div
          className="absolute inset-0"
          style={getTransitionStyle(false)}
        >
          <img
            src={paintings[currentPainting]}
            alt="Background painting"
            className="w-full h-full object-cover"
          />
        </div>

        {/* Next Painting (during transition) */}
        {isTransitioning && (
          <div
            className="absolute inset-0"
            style={getTransitionStyle(true)}
          >
            <img
              src={paintings[nextPainting]}
              alt="Background painting"
              className="w-full h-full object-cover"
            />
          </div>
        )}

        {/* Purple Overlay - toned down to show paintings more */}
        <div className="absolute inset-0 bg-purple-900/30 backdrop-blur-sm"></div>

        {/* Ripple Effects */}
        {ripples.map(ripple => (
          <div
            key={ripple.id}
            className="absolute pointer-events-none"
            style={{
              left: `${ripple.x}%`,
              top: `${ripple.y}%`,
              transform: 'translate(-50%, -50%)',
            }}
          >
            <div
              className="absolute rounded-full border-4 border-white/40 animate-ping"
              style={{
                width: '100px',
                height: '100px',
                animationDuration: '1s',
              }}
            ></div>
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="w-full max-w-4xl relative z-10">
        {/* Visualization */}
        <div className="mb-8 h-48 flex items-end justify-start w-full overflow-hidden">
          {visualData.map((value, index) => {
            const height = (value / 255) * 100;
            const hue = (index / visualData.length) * 360;
            return (
              <div
                key={index}
                className="flex-1 min-w-0 transition-all duration-75"
                style={{
                  height: `${height}%`,
                  backgroundColor: `hsla(${hue}, 70%, 60%, 0.6)`,
                  boxShadow: `0 0 10px hsla(${hue}, 70%, 60%, 0.6)`,
                  minHeight: '4px',
                }}
              />
            );
          })}
        </div>

        {/* Text Display */}
        <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 mb-8 shadow-2xl min-h-[300px] flex items-center justify-center">
          {lines.length > 0 && (
            <p className="text-white text-2xl text-center leading-relaxed font-light">
              {lines[currentLine] || lines[0]}
            </p>
          )}
        </div>

        {/* Controls */}
        <div className="flex justify-center gap-4 items-center">
          {/* Play/Stop Button */}
          <button
            onClick={handleTogglePlay}
            className={`p-4 rounded-full text-white transition-all transform hover:scale-110 shadow-lg ${
              isPlaying
                ? 'bg-red-500 hover:bg-red-600'
                : 'bg-green-500 hover:bg-green-600'
            }`}
            aria-label={isPlaying ? t.stop : t.start}
            title={isPlaying ? t.stop : t.start}
          >
            {isPlaying ? (
              // Stop icon (square)
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect x="6" y="6" width="12" height="12" fill="currentColor" />
              </svg>
            ) : (
              // Play icon (triangle)
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M8 5v14l11-7z" fill="currentColor" />
              </svg>
            )}
          </button>

          {/* Loop Button */}
          <button
            onClick={handleToggleLoop}
            className={`p-3 rounded-full text-white transition-all transform hover:scale-110 shadow-lg ${
              isLooping
                ? 'bg-blue-600 hover:bg-blue-700'
                : 'bg-gray-500 hover:bg-gray-600'
            }`}
            aria-label={`${t.loop} ${isLooping ? t.on : t.off}`}
            title={`${t.loop} ${isLooping ? t.on : t.off}`}
          >
            {/* Loop icon (circular arrows) */}
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M17 2L21 6L17 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M3 11V9C3 7.93913 3.42143 6.92172 4.17157 6.17157C4.92172 5.42143 5.93913 5 7 5H21" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M7 22L3 18L7 14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M21 13V15C21 16.0609 20.5786 17.0783 19.8284 17.8284C19.0783 18.5786 18.0609 19 17 19H3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>

        {/* Progress Indicator */}
        <div className="mt-6 text-center text-white/70">
          {currentLine + 1} {t.of} {lines.length}
        </div>
      </div>
    </div>
  );
}
