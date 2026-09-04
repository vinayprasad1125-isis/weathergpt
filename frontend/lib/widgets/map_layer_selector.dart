import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WeatherLayerInfo {
  final String key;
  final String label;
  final String emoji;
  final IconData icon;

  const WeatherLayerInfo({
    required this.key,
    required this.label,
    required this.emoji,
    required this.icon,
  });
}

class MapLayerSelector extends StatelessWidget {
  final String selectedLayer;
  final Function(String) onLayerChanged;

  const MapLayerSelector({
    super.key,
    required this.selectedLayer,
    required this.onLayerChanged,
  });

  static final List<WeatherLayerInfo> layers = [
    WeatherLayerInfo(key: 'base',          label: 'Standard Map',   emoji: '🗺',  icon: LucideIcons.map),
    WeatherLayerInfo(key: 'satellite',     label: 'Satellite',      emoji: '🛰',  icon: LucideIcons.satellite),
    WeatherLayerInfo(key: 'temperature',   label: 'Temperature',    emoji: '🌡',  icon: LucideIcons.thermometer),
    WeatherLayerInfo(key: 'radar',         label: 'Rain Radar',     emoji: '🌧',  icon: LucideIcons.radar),
    WeatherLayerInfo(key: 'precipitation', label: 'Precipitation',  emoji: '💧',  icon: LucideIcons.droplets),
    WeatherLayerInfo(key: 'wind',          label: 'Wind',           emoji: '💨',  icon: LucideIcons.wind),
    WeatherLayerInfo(key: 'cloud_cover',   label: 'Cloud Cover',    emoji: '☁',   icon: LucideIcons.cloud),
    WeatherLayerInfo(key: 'pressure',      label: 'Pressure',       emoji: '📊',  icon: LucideIcons.gauge),
    WeatherLayerInfo(key: 'humidity',      label: 'Humidity',       emoji: '💦',  icon: LucideIcons.droplets),
    WeatherLayerInfo(key: 'uv_index',      label: 'UV Index',       emoji: '☀',   icon: LucideIcons.sun),
  ];

  static WeatherLayerInfo? infoFor(String key) {
    try {
      return layers.firstWhere((l) => l.key == key);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLayer,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6.0),
            child: Icon(LucideIcons.layers, size: 18),
          ),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) onLayerChanged(newValue);
          },
          items: layers.map((layer) {
            return DropdownMenuItem<String>(
              value: layer.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(layer.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Text(layer.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
