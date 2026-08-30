import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class MapLayerSelector extends StatelessWidget {
  final String selectedLayer;
  final Function(String) onLayerChanged;

  const MapLayerSelector({
    super.key,
    required this.selectedLayer,
    required this.onLayerChanged,
  });

  static const Map<String, String> layers = {
    'base': 'Base Map',
    'temperature': 'Temperature',
    'rainfall': 'Rainfall / Precipitation',
    'radar': 'Weather Radar',
    'cyclones': 'Cyclone Tracking',
    'flood': 'Flood Risk',
    'wind': 'Wind',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLayer,
          icon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(LucideIcons.layers, size: 20),
          ),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onLayerChanged(newValue);
            }
          },
          items: layers.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
