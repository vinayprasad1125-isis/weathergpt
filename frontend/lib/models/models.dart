class Location {
  final String id;
  final String city;
  final String? state;
  final String country;
  final double latitude;
  final double longitude;
  final bool? isCurrentLocation;

  Location({
    required this.id,
    required this.city,
    this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.isCurrentLocation,
  });
}

class WeatherData {
  final Location location;
  final int currentTemp;
  final int feelsLike;
  final String condition;
  final int humidity;
  final int windSpeed;
  final String windDirection;
  final int visibility;
  final int pressure;
  final int uvIndex;
  final String sunrise;
  final String sunset;
  final int cloudCoverage;
  final int precipitationProb;
  final String icon;

  WeatherData({
    required this.location,
    required this.currentTemp,
    required this.feelsLike,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.pressure,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.cloudCoverage,
    required this.precipitationProb,
    required this.icon,
  });
}

class HourlyForecast {
  final String time;
  final int temp;
  final String condition;
  final String icon;
  final int precipitationProb;

  HourlyForecast({
    required this.time,
    required this.temp,
    required this.condition,
    required this.icon,
    required this.precipitationProb,
  });
}

class DailyForecast {
  final String day;
  final String date;
  final int minTemp;
  final int maxTemp;
  final String condition;
  final String icon;
  final int precipitationProb;

  DailyForecast({
    required this.day,
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.icon,
    required this.precipitationProb,
  });
}

class ForecastData {
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  ForecastData({
    required this.hourly,
    required this.daily,
  });
}

class WeatherAlert {
  final String id;
  final String severity; // 'Extreme' | 'Severe' | 'Moderate' | 'Minor'
  final String type;
  final String location;
  final String time;
  final String description;
  final String recommendedAction;
  final String source;
  final String status; // 'Active' | 'Resolved'
  final bool isDemo;

  WeatherAlert({
    required this.id,
    required this.severity,
    required this.type,
    required this.location,
    required this.time,
    required this.description,
    required this.recommendedAction,
    required this.source,
    required this.status,
    this.isDemo = false,
  });
}

class Advisory {
  final String id;
  final String category; // 'Agriculture' | 'Aviation' | 'Marine' | 'Urban' | 'Disaster'
  final String location;
  final String title;
  final String details;
  final int rainProbability;
  final String tempRange;

  Advisory({
    required this.id,
    required this.category,
    required this.location,
    required this.title,
    required this.details,
    required this.rainProbability,
    required this.tempRange,
  });
}

class ClimateData {
  final List<int> historicalTemp;
  final List<int> historicalRainfall;
  final List<String> labels;

  ClimateData({
    required this.historicalTemp,
    required this.historicalRainfall,
    required this.labels,
  });
}

class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final String timestamp;
  final String type; // 'text' | 'weather_card' | 'alert_card' | 'forecast_card' | 'advisory_card'
  final dynamic data;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.type,
    this.data,
  });
}
