import '../models/models.dart';

final mockLocation = Location(
  id: 'loc-1',
  city: 'Chennai',
  state: 'Tamil Nadu',
  country: 'India',
  latitude: 13.0827,
  longitude: 80.2707,
  isCurrentLocation: true,
);

final mockWeatherData = WeatherData(
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
  icon: 'cloud-sun',
);

final mockForecastData = ForecastData(
  hourly: [
    HourlyForecast(time: 'Now', temp: 31, condition: 'Partly Cloudy', icon: 'cloud-sun', precipitationProb: 10),
    HourlyForecast(time: '16:00', temp: 31, condition: 'Partly Cloudy', icon: 'cloud-sun', precipitationProb: 20),
    HourlyForecast(time: '17:00', temp: 30, condition: 'Light Rain', icon: 'cloud-rain', precipitationProb: 60),
    HourlyForecast(time: '18:00', temp: 29, condition: 'Light Rain', icon: 'cloud-rain', precipitationProb: 70),
    HourlyForecast(time: '19:00', temp: 28, condition: 'Cloudy', icon: 'cloud', precipitationProb: 40),
  ],
  daily: [
    DailyForecast(day: 'Today', date: 'Oct 12', minTemp: 27, maxTemp: 31, condition: 'Rain Showers', icon: 'cloud-rain', precipitationProb: 70),
    DailyForecast(day: 'Tomorrow', date: 'Oct 13', minTemp: 27, maxTemp: 32, condition: 'Partly Cloudy', icon: 'cloud-sun', precipitationProb: 30),
    DailyForecast(day: 'Saturday', date: 'Oct 14', minTemp: 26, maxTemp: 30, condition: 'Scattered Thunderstorms', icon: 'cloud-lightning', precipitationProb: 80),
    DailyForecast(day: 'Sunday', date: 'Oct 15', minTemp: 26, maxTemp: 29, condition: 'Rain Showers', icon: 'cloud-rain', precipitationProb: 90),
    DailyForecast(day: 'Monday', date: 'Oct 16', minTemp: 25, maxTemp: 28, condition: 'Cloudy', icon: 'cloud', precipitationProb: 50),
  ],
);

final mockAlerts = [
  WeatherAlert(
    id: 'alert-1',
    severity: 'Severe',
    type: 'Heavy Rainfall',
    location: 'Chennai and Kanchipuram Districts',
    time: 'Valid until 23:00 IST',
    description: 'Heavy rainfall is possible during the next few hours. Localized flooding of roads, waterlogging in low-lying areas, and closure of underpasses mainly in urban areas of the above region.',
    recommendedAction: 'Avoid low-lying areas and unnecessary travel. Check traffic conditions before leaving your destination. Follow traffic advisories issued in this regard.',
    source: 'Regional Meteorological Centre (IMD mock)',
    status: 'Active',
  ),
  WeatherAlert(
    id: 'alert-2',
    severity: 'Moderate',
    type: 'Strong Wind',
    location: 'Coastal Tamil Nadu',
    time: 'Valid until Tomorrow 06:00 IST',
    description: 'Squally weather with wind speed reaching 40-45 kmph gusting to 55 kmph is likely to prevail over coastal areas.',
    recommendedAction: 'Fishermen are advised not to venture into these sea areas.',
    source: 'Regional Meteorological Centre (IMD mock)',
    status: 'Active',
  ),
];

final mockAdvisories = [
  Advisory(
    id: 'adv-1',
    category: 'Agriculture',
    location: 'Chennai District',
    title: 'Crop Irrigation Advisory',
    details: 'Heavy rainfall expected later today. Consider postponing irrigation and fertilizer application. Ensure proper drainage in fields to prevent water stagnation, especially for newly planted paddy.',
    rainProbability: 70,
    tempRange: '27-32°C',
  ),
  Advisory(
    id: 'adv-2',
    category: 'Marine',
    location: 'Chennai Coast',
    title: 'Fishermen Warning',
    details: 'Strong winds expected tonight. Fishermen are advised not to venture into the sea off the Tamil Nadu coast.',
    rainProbability: 60,
    tempRange: '26-29°C',
  ),
];

final mockClimateData = ClimateData(
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  historicalTemp: [29, 31, 33, 35, 38, 37, 35, 34, 34, 32, 30, 29],
  historicalRainfall: [20, 10, 5, 15, 40, 50, 100, 130, 150, 300, 350, 150],
);
