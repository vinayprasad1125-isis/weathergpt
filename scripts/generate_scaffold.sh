#!/bin/bash
mkdir -p src/types src/services src/theme src/components/common src/components/weather src/components/forecast src/components/alerts src/components/chat src/components/advisory src/screens src/navigation src/constants

cat << 'INNER_EOF' > src/types/index.ts
export interface Location {
  id: string;
  city: string;
  state?: string;
  country: string;
  latitude: number;
  longitude: number;
  isCurrentLocation?: boolean;
}

export interface WeatherData {
  location: Location;
  currentTemp: number;
  feelsLike: number;
  condition: string;
  humidity: number;
  windSpeed: number;
  windDirection: string;
  visibility: number;
  pressure: number;
  uvIndex: number;
  sunrise: string;
  sunset: string;
  cloudCoverage: number;
  precipitationProb: number;
  icon: string;
}

export interface ForecastData {
  hourly: {
    time: string;
    temp: number;
    condition: string;
    icon: string;
    precipitationProb: number;
  }[];
  daily: {
    day: string;
    date: string;
    minTemp: number;
    maxTemp: number;
    condition: string;
    icon: string;
    precipitationProb: number;
  }[];
}

export interface WeatherAlert {
  id: string;
  severity: 'Extreme' | 'Severe' | 'Moderate' | 'Minor';
  type: string;
  location: string;
  time: string;
  description: string;
  recommendedAction: string;
  source: string;
  status: 'Active' | 'Resolved';
}

export interface Advisory {
  id: string;
  category: 'Agriculture' | 'Aviation' | 'Marine' | 'Urban' | 'Disaster';
  location: string;
  title: string;
  details: string;
  rainProbability: number;
  tempRange: string;
}

export interface ClimateData {
  historicalTemp: number[];
  historicalRainfall: number[];
  labels: string[];
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
  type: 'text' | 'weather_card' | 'alert_card' | 'forecast_card' | 'advisory_card';
  data?: any;
}
INNER_EOF

cat << 'INNER_EOF' > src/theme/index.ts
export const colors = {
  primary: '#0ea5e9',
  primaryDark: '#0284c7',
  secondary: '#38bdf8',
  background: '#f8fafc',
  card: '#ffffff',
  text: '#0f172a',
  textSecondary: '#64748b',
  border: '#e2e8f0',
  error: '#ef4444',
  warning: '#f59e0b',
  success: '#22c55e',
  info: '#3b82f6',
  surface: '#ffffff',
  alertExtreme: '#dc2626',
  alertSevere: '#ea580c',
  alertModerate: '#d97706',
  alertMinor: '#ca8a04',
};

export const typography = {
  h1: { fontSize: 32, fontWeight: 'bold' as const },
  h2: { fontSize: 24, fontWeight: 'bold' as const },
  h3: { fontSize: 20, fontWeight: '600' as const },
  body1: { fontSize: 16, fontWeight: '400' as const },
  body2: { fontSize: 14, fontWeight: '400' as const },
  caption: { fontSize: 12, fontWeight: '400' as const },
};

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const globalStyles = {
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: spacing.md,
    marginVertical: spacing.sm,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
};
INNER_EOF

cat << 'INNER_EOF' > src/services/MockData.ts
import { WeatherData, ForecastData, WeatherAlert, Advisory, ClimateData, Location } from '../types';

export const mockLocation: Location = {
  id: 'loc-1',
  city: 'Chennai',
  state: 'Tamil Nadu',
  country: 'India',
  latitude: 13.0827,
  longitude: 80.2707,
  isCurrentLocation: true
};

export const mockWeatherData: WeatherData = {
  location: mockLocation,
  currentTemp: 31,
  feelsLike: 34,
  condition: 'Partly Cloudy',
  humidity: 72,
  windSpeed: 14,
  windDirection: 'SE',
  visibility: 8,
  pressure: 1008,
  uvIndex: 6,
  sunrise: '05:58 AM',
  sunset: '06:22 PM',
  cloudCoverage: 40,
  precipitationProb: 20,
  icon: 'cloud-sun'
};

export const mockForecastData: ForecastData = {
  hourly: [
    { time: 'Now', temp: 31, condition: 'Partly Cloudy', icon: 'cloud-sun', precipitationProb: 10 },
    { time: '16:00', temp: 31, condition: 'Partly Cloudy', icon: 'cloud-sun', precipitationProb: 20 },
    { time: '17:00', temp: 30, condition: 'Light Rain', icon: 'cloud-rain', precipitationProb: 60 },
    { time: '18:00', temp: 29, condition: 'Light Rain', icon: 'cloud-rain', precipitationProb: 70 },
    { time: '19:00', temp: 28, condition: 'Cloudy', icon: 'cloud', precipitationProb: 40 },
  ],
  daily: [
    { day: 'Today', date: 'Oct 12', minTemp: 27, maxTemp: 31, condition: 'Rain Showers', icon: 'cloud-rain', precipitationProb: 70 },
    { day: 'Tomorrow', date: 'Oct 13', minTemp: 27, maxTemp: 32, condition: 'Partly Cloudy', icon: 'cloud-sun', precipitationProb: 30 },
    { day: 'Saturday', date: 'Oct 14', minTemp: 26, maxTemp: 30, condition: 'Scattered Thunderstorms', icon: 'cloud-lightning', precipitationProb: 80 },
    { day: 'Sunday', date: 'Oct 15', minTemp: 26, maxTemp: 29, condition: 'Rain Showers', icon: 'cloud-rain', precipitationProb: 90 },
    { day: 'Monday', date: 'Oct 16', minTemp: 25, maxTemp: 28, condition: 'Cloudy', icon: 'cloud', precipitationProb: 50 },
  ]
};

export const mockAlerts: WeatherAlert[] = [
  {
    id: 'alert-1',
    severity: 'Severe',
    type: 'Heavy Rainfall',
    location: 'Chennai and Kanchipuram Districts',
    time: 'Valid until 23:00 IST',
    description: 'Heavy rainfall is possible during the next few hours. Localized flooding of roads, waterlogging in low-lying areas, and closure of underpasses mainly in urban areas of the above region.',
    recommendedAction: 'Avoid low-lying areas and unnecessary travel. Check traffic conditions before leaving your destination. Follow traffic advisories issued in this regard.',
    source: 'Regional Meteorological Centre (IMD mock)',
    status: 'Active'
  },
  {
    id: 'alert-2',
    severity: 'Moderate',
    type: 'Strong Wind',
    location: 'Coastal Tamil Nadu',
    time: 'Valid until Tomorrow 06:00 IST',
    description: 'Squally weather with wind speed reaching 40-45 kmph gusting to 55 kmph is likely to prevail over coastal areas.',
    recommendedAction: 'Fishermen are advised not to venture into these sea areas.',
    source: 'Regional Meteorological Centre (IMD mock)',
    status: 'Active'
  }
];

export const mockAdvisories: Advisory[] = [
  {
    id: 'adv-1',
    category: 'Agriculture',
    location: 'Chennai District',
    title: 'Crop Irrigation Advisory',
    details: 'Heavy rainfall expected later today. Consider postponing irrigation and fertilizer application. Ensure proper drainage in fields to prevent water stagnation, especially for newly planted paddy.',
    rainProbability: 70,
    tempRange: '27-32°C'
  },
  {
    id: 'adv-2',
    category: 'Marine',
    location: 'Chennai Coast',
    title: 'Fishermen Warning',
    details: 'Strong winds expected tonight. Fishermen are advised not to venture into the sea off the Tamil Nadu coast.',
    rainProbability: 60,
    tempRange: '26-29°C'
  }
];

export const mockClimateData: ClimateData = {
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  historicalTemp: [29, 31, 33, 35, 38, 37, 35, 34, 34, 32, 30, 29],
  historicalRainfall: [20, 10, 5, 15, 40, 50, 100, 130, 150, 300, 350, 150]
};
INNER_EOF

cat << 'INNER_EOF' > src/services/WeatherService.ts
import { mockWeatherData, mockForecastData, mockLocation } from './MockData';
import { WeatherData, ForecastData, Location } from '../types';

export class WeatherService {
  static async getCurrentWeather(locationId?: string): Promise<WeatherData> {
    return new Promise((resolve) => setTimeout(() => resolve(mockWeatherData), 500));
  }
  
  static async getForecast(locationId?: string): Promise<ForecastData> {
    return new Promise((resolve) => setTimeout(() => resolve(mockForecastData), 500));
  }

  static async searchLocations(query: string): Promise<Location[]> {
    return new Promise((resolve) => setTimeout(() => resolve([mockLocation]), 500));
  }
}
INNER_EOF

cat << 'INNER_EOF' > src/services/AlertService.ts
import { mockAlerts } from './MockData';
import { WeatherAlert } from '../types';

export class AlertService {
  static async getActiveAlerts(locationId?: string): Promise<WeatherAlert[]> {
    return new Promise((resolve) => setTimeout(() => resolve(mockAlerts), 500));
  }
}
INNER_EOF

cat << 'INNER_EOF' > src/services/AdvisoryService.ts
import { mockAdvisories } from './MockData';
import { Advisory } from '../types';

export class AdvisoryService {
  static async getAdvisories(locationId?: string): Promise<Advisory[]> {
    return new Promise((resolve) => setTimeout(() => resolve(mockAdvisories), 500));
  }
  
  static async getAdvisoryByCategory(category: string, locationId?: string): Promise<Advisory | undefined> {
    return new Promise((resolve) => setTimeout(() => resolve(mockAdvisories.find(a => a.category === category)), 500));
  }
}
INNER_EOF

cat << 'INNER_EOF' > src/services/ClimateService.ts
import { mockClimateData } from './MockData';
import { ClimateData } from '../types';

export class ClimateService {
  static async getClimateTrends(locationId?: string): Promise<ClimateData> {
    return new Promise((resolve) => setTimeout(() => resolve(mockClimateData), 500));
  }
}
INNER_EOF

cat << 'INNER_EOF' > src/services/ChatService.ts
import { ChatMessage } from '../types';
import { mockWeatherData, mockForecastData, mockAlerts } from './MockData';

export class ChatService {
  static async sendMessage(message: string): Promise<ChatMessage[]> {
    return new Promise((resolve) => {
      setTimeout(() => {
        let responses: ChatMessage[] = [];
        const lowerMsg = message.toLowerCase();
        
        if (lowerMsg.includes('rain') || lowerMsg.includes('forecast')) {
          responses.push({
            id: Date.now().toString() + '1',
            role: 'assistant',
            content: 'Based on the current forecast, there is a high probability of rain later today in Chennai. Here is the daily forecast:',
            timestamp: new Date().toISOString(),
            type: 'text'
          });
          responses.push({
            id: Date.now().toString() + '2',
            role: 'assistant',
            content: '',
            timestamp: new Date().toISOString(),
            type: 'forecast_card',
            data: mockForecastData.daily.slice(0, 3)
          });
        } else if (lowerMsg.includes('alert') || lowerMsg.includes('cyclone') || lowerMsg.includes('warning')) {
          responses.push({
            id: Date.now().toString() + '1',
            role: 'assistant',
            content: 'There is currently a Severe Weather Alert active for your region.',
            timestamp: new Date().toISOString(),
            type: 'text'
          });
          responses.push({
            id: Date.now().toString() + '2',
            role: 'assistant',
            content: '',
            timestamp: new Date().toISOString(),
            type: 'alert_card',
            data: mockAlerts[0]
          });
        } else {
          responses.push({
            id: Date.now().toString() + '1',
            role: 'assistant',
            content: `I'm your WeatherGPT assistant. I can provide real-time weather, extreme weather warnings, and crop/marine advisories for India. Try asking me "Will it rain tomorrow?" or "Are there any active alerts?"`,
            timestamp: new Date().toISOString(),
            type: 'text'
          });
        }
        resolve(responses);
      }, 1000);
    });
  }
}
INNER_EOF

chmod +x generate_scaffold.sh
./generate_scaffold.sh
rm generate_scaffold.sh
