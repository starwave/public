// tests/integration/wallpaper.integration.test.tsx
import { render, screen, fireEvent, waitFor } from '../utils/testUtils';
import WallpaperApp from '../../src/WallpaperApp';
import { mockFetch, mockThemeLibrary } from '../utils/helpers';

describe('WallpaperApp Integration Tests', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    mockFetch(mockThemeLibrary);
    localStorage.clear();
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  });

  describe('Complete User Flow', () => {
    it('should handle complete wallpaper viewing session', async () => {
      render(<WallpaperApp />);

      // Wait for splash screen to disappear
      jest.advanceTimersByTime(4000);

      await waitFor(() => {
        expect(screen.queryByAltText('Tromso')).not.toBeInTheDocument();
      });

      // Select a theme
      const select = screen.getByRole('combobox');
      fireEvent.change(select, { target: { value: 'landscape' } });

      // Navigate through wallpapers
      const forwardButton = screen.getByText('⏭');
      fireEvent.click(forwardButton);

      jest.advanceTimersByTime(7000);

      // Pause
      const pauseButton = screen.getByText('⏸');
      fireEvent.click(pauseButton);
      expect(screen.getByText('▶')).toBeInTheDocument();

      // Verify localStorage was updated
      expect(localStorage.getItem('theme')).toBe('landscape');
    });
  });
});