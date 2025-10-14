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

export default function Home() {
  const [bibleText, setBibleText] = useState<string>('');
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLooping, setIsLooping] = useState(false);
  const [currentLine, setCurrentLine] = useState(0);
  const [visualData, setVisualData] = useState<number[]>([]);
  const [locale, setLocale] = useState<'en' | 'ko'>('en');

  const audioContextRef = useRef<AudioContext | null>(null);
  const oscillatorsRef = useRef<OscillatorNode[]>([]);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationRef = useRef<number | null>(null);
  const isPlayingRef = useRef(false);

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

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
      stopAudio();
    };
  }, []);

  const t = translations[locale];

  const stopAudio = () => {
    oscillatorsRef.current.forEach(osc => {
      try {
        osc.stop();
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
        setTimeout(() => playLine(0), 100);
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

      // Schedule next line
      setTimeout(() => {
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

  const visualize = () => {
    if (!analyserRef.current) return;

    const bufferLength = analyserRef.current.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const draw = () => {
      if (!analyserRef.current || !isPlayingRef.current) return;

      analyserRef.current.getByteFrequencyData(dataArray);
      // setVisualData(Array.from(dataArray));
      // Take only the active frequency range and stretch it across full width
      const activeData = Array.from(dataArray).slice(0, 20); // Only first 40 bins have audio data
      const displayData: number[] = [];
      const targetBars = 112;
      for (let i = 0; i < targetBars; i++) {
        const sourceIndex = Math.floor((i * activeData.length) / targetBars);
        displayData.push(activeData[sourceIndex]);
      }
      setVisualData(displayData);

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

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex flex-col items-center justify-center p-8">
      <div className="w-full max-w-4xl">
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
                  backgroundColor: `hsl(${hue}, 70%, 60%)`,
                  boxShadow: `0 0 10px hsl(${hue}, 70%, 60%)`,
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
        <div className="flex justify-center gap-4">
          <button
            onClick={handleTogglePlay}
            className={`px-8 py-4 rounded-full font-semibold text-white text-lg transition-all transform hover:scale-105 shadow-lg ${
              isPlaying
                ? 'bg-red-500 hover:bg-red-600'
                : 'bg-green-500 hover:bg-green-600'
            }`}
          >
            {isPlaying ? t.stop : t.start}
          </button>

          <button
            onClick={handleToggleLoop}
            className={`px-8 py-4 rounded-full font-semibold text-white text-lg transition-all transform hover:scale-105 shadow-lg ${
              isLooping
                ? 'bg-blue-600 hover:bg-blue-700'
                : 'bg-gray-500 hover:bg-gray-600'
            }`}
          >
            {t.loop} {isLooping ? t.on : t.off}
          </button>
        </div>

        {/* Progress Indicator */}
        <div className="mt-6 text-center text-white/70">
          {t.line} {currentLine + 1} {t.of} {lines.length}
        </div>
      </div>
    </div>
  );
}
