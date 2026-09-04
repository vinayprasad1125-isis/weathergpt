import { mockWeatherData, mockForecastData, mockAlerts, mockAdvisories, mockClimateData, mockLocation } from '../data/mockData';
import type { WeatherData, ForecastData, WeatherAlert, Advisory, ClimateData, Location } from '../types/models';

const IS_MOCK = import.meta.env.VITE_DATA_MODE !== 'api';
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

async function fetchApi<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });
  if (!response.ok) {
    throw new Error(`API error: ${response.status} ${response.statusText}`);
  }
  return response.json();
}

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export const WeatherService = {
  async getCurrentWeather(city?: string, lat?: number, lon?: number): Promise<WeatherData> {
    if (IS_MOCK) {
      await delay(600);
      return mockWeatherData;
    }
    const params = new URLSearchParams();
    if (city) params.append('city', city);
    if (lat && lon) {
      params.append('lat', lat.toString());
      params.append('lon', lon.toString());
    }
    return fetchApi<WeatherData>(`/api/v1/weather/current?${params.toString()}`);
  },

  async getForecast(city?: string): Promise<ForecastData> {
    if (IS_MOCK) {
      await delay(800);
      return mockForecastData;
    }
    const params = new URLSearchParams();
    if (city) params.append('city', city);
    return fetchApi<ForecastData>(`/api/v1/weather/forecast?${params.toString()}`);
  }
};

export const AlertService = {
  async getAlerts(lat?: number, lon?: number): Promise<WeatherAlert[]> {
    if (IS_MOCK) {
      await delay(500);
      return mockAlerts;
    }
    const params = new URLSearchParams();
    if (lat && lon) {
      params.append('lat', lat.toString());
      params.append('lon', lon.toString());
    }
    return fetchApi<WeatherAlert[]>(`/api/v1/alerts?${params.toString()}`);
  }
};

export const AdvisoryService = {
  async getAdvisories(): Promise<Advisory[]> {
    if (IS_MOCK) {
      await delay(700);
      return mockAdvisories;
    }
    // API mock expects POST for some reason in the prompt: POST /api/v1/advisory
    return fetchApi<Advisory[]>(`/api/v1/advisory`, { method: 'POST', body: JSON.stringify({}) });
  }
};

export const ClimateService = {
  async getClimateTrends(): Promise<ClimateData> {
    if (IS_MOCK) {
      await delay(1000);
      return mockClimateData;
    }
    return fetchApi<ClimateData>(`/api/v1/climate/analyze`, { method: 'POST', body: JSON.stringify({}) });
  }
};

export const LocationService = {
  async searchLocation(query: string): Promise<Location[]> {
    if (IS_MOCK) {
      await delay(400);
      return [mockLocation];
    }
    return fetchApi<Location[]>(`/api/v1/location/search?q=${encodeURIComponent(query)}`);
  }
};

// Aviation is explicitly requested to be mock-only for now
export const AviationService = {
  async getMETAR(icao: string): Promise<any> {
    await delay(600);
    if (icao.toUpperCase() !== 'VOMM' && icao.toUpperCase() !== 'VABB' && icao.toUpperCase() !== 'VIDP' && icao.toUpperCase() !== 'VOBL') {
      throw new Error("No data for this ICAO");
    }
    return {
      rawText: `${icao.toUpperCase()} 120530Z 12008KT 4000 HZ SCT020 SCT040 31/24 Q1008 NOSIG`,
      observationTime: 'Today 11:00 IST',
      temperature: 31,
      dewpoint: 24,
      wind: '120° at 8 knots',
      visibility: '4.0 km',
      altimeter: '1008 hPa',
      clouds: 'Scattered at 2000ft, Scattered at 4000ft'
    };
  },
  async getTAF(icao: string): Promise<any> {
    await delay(700);
    return {
      rawText: `TAF ${icao.toUpperCase()} 120500Z 1206/1312 11010KT 6000 FEW020 BECMG 1208/1210 13015KT SCT025`,
      issueTime: 'Today 10:30 IST',
      validTime: '1206/1312',
    };
  }
};
