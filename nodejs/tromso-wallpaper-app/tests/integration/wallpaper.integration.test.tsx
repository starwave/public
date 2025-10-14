// tests/integration/wallpaper.integration.test.tsx
import React from 'react';
import { render, screen, fireEvent, waitFor } from '../utils/testUtils';
import WallpaperApp from '../../src/WallpaperApp';
import { mockFetch, mockThemeLibrary, waitForMs } from '../utils/helpers';

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
    it('should handle complete wallpaper viewing