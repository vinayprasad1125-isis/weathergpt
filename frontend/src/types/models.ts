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

export interface HourlyForecast {
  time: string;
  temp: number;
  condition: string;
  icon: string;
  precipitationProb: number;
}

export interface DailyForecast {
  day: string;
  date: string;
  minTemp: number;
  maxTemp: number;
  condition: string;
  icon: string;
  precipitationProb: number;
}

export interface ForecastData {
  hourly: HourlyForecast[];
  daily: DailyForecast[];
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
