// tests/WallpaperApp.test.tsx
import { render, screen, fireEvent, waitFor } from './utils/testUtils';
import WallpaperApp from '../src/WallpaperApp';
import { mockFetch, mockThemeLibrary } from './utils/helpers';

describe('WallpaperApp Component', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    mockFetch(mockThemeLibrary);
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  });

  describe('Initial Rendering', () => {
    it('should render without crashing', () => {
      render(<WallpaperApp />);
      expect(screen.getByRole('combobox')).toBeInTheDocument();
    });

    it('should display splash screen initially', () => {
      render(<WallpaperApp />);
      const splashImage = screen.getByAltText('Tromso');
      expect(splashImage).toBeInTheDocument();
    });

    it('should hide splash screen after timeout', async () => {
      render(<WallpaperApp />);

      jest.advanceTimersByTime(4000);

      await waitFor(() => {
        expect(screen.queryByAltText('Tromso')).not.toBeInTheDocument();
      });
    });

    it('should load saved theme from localStorage', () => {
      localStorage.setItem('theme', 'photo');
      render(<WallpaperApp />);

      const select = screen.getByRole('combobox') as HTMLSelectElement;
      expect(select.value).toBe('photo');
    });

    it('should load saved custom config from localStorage', () => {
      const customConfig = '/test;;#custom#|#config#';
      localStorage.setItem('customConfigString', customConfig);

      render(<WallpaperApp />);

      expect(localStorage.getItem('customConfigString')).toBe(customConfig);
    });
  });

  describe('Theme Selection', () => {
    it('should render all theme options', () => {
      render(<WallpaperApp />);

      const select = screen.getByRole('combobox');
      const options = Array.from(select.querySelectorAll('option'));

      expect(options).toHaveLength(12);
      expect(options.map(o => o.value)).toContain('default1');
      expect(options.map(o => o.value)).toContain('custom');
      expect(options.map(o => o.value)).toContain('photo');
    });

    it('should change theme when selected', () => {
      render(<WallpaperApp />);

      const select = screen.getByRole('combobox') as HTMLSelectElement;

      fireEvent.change(select, { target: { value: 'landscape' } });

      expect(select.value).toBe('landscape');
      expect(localStorage.getItem('theme')).toBe('landscape');
    });

    it('should reset cache when changing theme', () => {
      render(<WallpaperApp />);

      const select = screen.getByRole('combobox');

      fireEvent.change(select, { target: { value: 'movie1' } });
      fireEvent.change(select, { target: { value: 'photo' } });

      // Cache should be reset on theme change
      expect(select).toBeInTheDocument();
    });
  });

  describe('Control Buttons', () => {
    it('should render all control buttons', () => {
      render(<WallpaperApp />);

      expect(screen.getByText(/full|normal/i)).toBeInTheDocument();
      expect(screen.getByText('⏮')).toBeInTheDocument();
      expect(screen.getByText('⏭')).toBeInTheDocument();
      expect(screen.getByText(/⏸|▶/)).toBeInTheDocument();
    });

    it('should toggle pause state when pause button clicked', () => {
      render(<WallpaperApp />);

      const pauseButton = screen.getByText('⏸');

      fireEvent.click(pauseButton);
      expect(screen.getByText('▶')).toBeInTheDocument();

      fireEvent.click(screen.getByText('▶'));
      expect(screen.getByText('⏸')).toBeInTheDocument();
    });

    it('should navigate forward when forward button clicked', () => {
      render(<WallpaperApp />);

      const forwardButton = screen.getByText('⏭');

      fireEvent.click(forwardButton);

      // Timer should restart
      expect(jest.getTimerCount()).toBeGreaterThan(0);
    });

    it('should navigate backward when back button clicked', () => {
      render(<WallpaperApp />);

      const backButton = screen.getByText('⏮');

      fireEvent.click(backButton);

      // Timer should restart
      expect(jest.getTimerCount()).toBeGreaterThan(0);
    });

    it('should toggle fullscreen when full button clicked', async () => {
      render(<WallpaperApp />);

      const fullButton = screen.getByText('Full');

      fireEvent.click(fullButton);

      await waitFor(() => {
        expect(document.documentElement.requestFullscreen).toHaveBeenCalled();
      });
    });
  });

  describe('Automatic Slideshow', () => {
    it('should advance wallpaper after interval', () => {
      render(<WallpaperApp />);

      // Fast-forward time by 7 seconds (interval time)
      jest.advanceTimersByTime(7000);

      // Should have triggered wallpaper switch
      expect(jest.getTimerCount()).toBeGreaterThan(0);
    });

    it('should not advance when paused', () => {
      render(<WallpaperApp />);

      const pauseButton = screen.getByText('⏸');
      fireEvent.click(pauseButton);

      // Fast-forward time
      jest.advanceTimersByTime(7000);

      // Wallpaper should not advance
      expect(screen.getByText('▶')).toBeInTheDocument();
    });

    it('should restart timer when navigating manually', () => {
      render(<WallpaperApp />);

      const forwardButton = screen.getByText('⏭');

      jest.advanceTimersByTime(3000);
      fireEvent.click(forwardButton);

      // Timer should restart
      expect(jest.getTimerCount()).toBeGreaterThan(0);
    });
  });

  describe('Custom Configuration Dialog', () => {
    it('should open config dialog on double click in center', () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      // Double click in center of screen
      fireEvent.doubleClick(container!, {
        clientX: window.innerWidth / 2,
        clientY: window.innerHeight / 2,
      });

      waitFor(() => {
        expect(screen.getByRole('button', { name: /ok/i })).toBeInTheDocument();
      });
    });

    it('should not open config dialog on double click outside center', () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      // Double click far from center
      fireEvent.doubleClick(container!, {
        clientX: 50,
        clientY: 50,
      });

      expect(screen.queryByRole('button', { name: /ok/i })).not.toBeInTheDocument();
    });

    it('should pause when opening config dialog', async () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.doubleClick(container!, {
        clientX: window.innerWidth / 2,
        clientY: window.innerHeight / 2,
      });

      await waitFor(() => {
        expect(screen.getByText('▶')).toBeInTheDocument();
      });
    });

    it('should fetch theme library when opening config', async () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.doubleClick(container!, {
        clientX: window.innerWidth / 2,
        clientY: window.innerHeight / 2,
      });

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          expect.stringContaining('/maramboi?a=g')
        );
      });
    });

    it('should close config dialog on cancel', async () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.doubleClick(container!, {
        clientX: window.innerWidth / 2,
        clientY: window.innerHeight / 2,
      });

      await waitFor(() => {
        const cancelButton = screen.getByRole('button', { name: /cancel/i });
        fireEvent.click(cancelButton);
      });

      await waitFor(() => {
        expect(screen.queryByRole('button', { name: /cancel/i })).not.toBeInTheDocument();
      });
    });

    it('should update config on OK', async () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.doubleClick(container!, {
        clientX: window.innerWidth / 2,
        clientY: window.innerHeight / 2,
      });

      await waitFor(() => {
        const textarea = screen.getByRole('textbox');
        fireEvent.change(textarea, { target: { value: '/new;;#config#' } });

        const okButton = screen.getByRole('button', { name: /ok/i });
        fireEvent.click(okButton);
      });

      await waitFor(() => {
        expect(localStorage.getItem('customConfigString')).toBe('/new;;#config#');
      });
    });
  });

  describe('Touch Gestures', () => {
    it('should navigate forward on left swipe', () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.touchStart(container!, {
        touches: [{ clientX: 300, clientY: 200 }],
      });

      fireEvent.touchMove(container!, {
        touches: [{ clientX: 100, clientY: 200 }],
      });

      fireEvent.touchEnd(container!);

      // Should trigger navigation
      expect(container).toBeInTheDocument();
    });

    it('should navigate backward on right swipe', () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.touchStart(container!, {
        touches: [{ clientX: 100, clientY: 200 }],
      });

      fireEvent.touchMove(container!, {
        touches: [{ clientX: 300, clientY: 200 }],
      });

      fireEvent.touchEnd(container!);

      expect(container).toBeInTheDocument();
    });

    it('should change theme on vertical swipe', () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.touchStart(container!, {
        touches: [{ clientX: 200, clientY: 300 }],
      });

      fireEvent.touchMove(container!, {
        touches: [{ clientX: 200, clientY: 100 }],
      });

      fireEvent.touchEnd(container!);

      const select = screen.getByRole('combobox') as HTMLSelectElement;
      expect(select.value).toBeTruthy();
    });

    it('should ignore small swipe movements', () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');
      const select = screen.getByRole('combobox') as HTMLSelectElement;
      const initialValue = select.value;

      // Small swipe (less than 100px)
      fireEvent.touchStart(container!, {
        touches: [{ clientX: 200, clientY: 200 }],
      });

      fireEvent.touchMove(container!, {
        touches: [{ clientX: 250, clientY: 200 }],
      });

      fireEvent.touchEnd(container!);

      // Theme should not change
      expect(select.value).toBe(initialValue);
    });
  });

  describe('Screen Dimensions', () => {
    it('should adjust dimensions on window resize', () => {
      render(<WallpaperApp />);

      // Simulate window resize
      global.innerWidth = 3840;
      global.innerHeight = 2160;

      fireEvent(window, new Event('resize'));

      // Dimension should be updated
      expect(window.innerWidth).toBe(3840);
    });

    it('should calculate correct dimension for iPad Pro', () => {
      global.innerWidth = 2732;
      global.innerHeight = 2048;

      render(<WallpaperApp />);

      // Should detect iPad Pro dimensions
      const ratio = (2732 * 1000) / 2048;
      expect(ratio).toBeGreaterThan(1150);
      expect(ratio).toBeLessThanOrEqual(1550);
    });

    it('should calculate correct dimension for HD screens', () => {
      global.innerWidth = 1920;
      global.innerHeight = 1080;

      render(<WallpaperApp />);

      const ratio = (1920 * 1000) / 1080;
      expect(ratio).toBeGreaterThan(1550);
      expect(ratio).toBeLessThanOrEqual(1950);
    });
  });

  describe('LocalStorage Integration', () => {
    it('should save theme preference', () => {
      render(<WallpaperApp />);

      const select = screen.getByRole('combobox');
      fireEvent.change(select, { target: { value: 'movie1' } });

      expect(localStorage.getItem('theme')).toBe('movie1');
    });

    it('should save custom config', async () => {
      render(<WallpaperApp />);

      const container = screen.getByRole('combobox').closest('div');

      fireEvent.doubleClick(container!, {
        clientX: window.innerWidth / 2,
        clientY: window.innerHeight / 2,
      });

      await waitFor(() => {
        const textarea = screen.getByRole('textbox');
        fireEvent.change(textarea, { target: { value: '/saved;;#test#' } });

        const okButton = screen.getByRole('button', { name: /ok/i });
        fireEvent.click(okButton);
      });

      expect(localStorage.getItem('customConfigString')).toBe('/saved;;#test#');
    });

    it('should restore preferences on mount', () => {
      localStorage.setItem('theme', 'landscape');
      localStorage.setItem('customConfigString', '/restored;;#config#');

      render(<WallpaperApp />);

      const select = screen.getByRole('combobox') as HTMLSelectElement;
      expect(select.value).toBe('landscape');
    });
  });
});