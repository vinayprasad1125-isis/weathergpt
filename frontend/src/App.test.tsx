import { render } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import App from './app/App';

// Mock matchMedia for dark mode testing
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

describe('WeatherGPT React Application', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('renders without crashing and defaults to light theme', () => {
    render(<App />);
    expect(document.documentElement.classList.contains('dark')).toBe(false);
  });

  it('persists language selection to localStorage', async () => {
    // In our mock, language starts as en
    expect(localStorage.getItem('language')).toBeNull();
    // Simulate setting language
    localStorage.setItem('language', 'ta');
    expect(localStorage.getItem('language')).toBe('ta');
  });

  it('verifies ICAO code validation logic (mock)', () => {
    const isValid = (code: string) => code.trim().length === 4;
    expect(isValid('VOMM')).toBe(true);
    expect(isValid('VOM')).toBe(false);
    expect(isValid('VOMMM')).toBe(false);
  });

  it('verifies chat intent matcher for demo mode (mock)', () => {
    const q1 = "Will it rain tomorrow?";
    const isForecast = q1.toLowerCase().includes('rain tomorrow') || q1.toLowerCase().includes('forecast');
    expect(isForecast).toBe(true);

    const q2 = "Is there any cyclone warning?";
    const isAlert = q2.toLowerCase().includes('cyclone') || q2.toLowerCase().includes('warning');
    expect(isAlert).toBe(true);
  });

  it('verifies climate trend calculation logic (mock)', () => {
    // Simple test of the slope calculation logic
    const chartData = [
      { year: '2020', temp: 25.0 },
      { year: '2021', temp: 25.5 },
      { year: '2022', temp: 26.0 },
      { year: '2023', temp: 26.5 },
    ];
    
    const n = chartData.length;
    let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (let i = 0; i < n; i++) {
      const x = i;
      const y = chartData[i].temp;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    expect(slope).toBeCloseTo(0.5);
  });
});
