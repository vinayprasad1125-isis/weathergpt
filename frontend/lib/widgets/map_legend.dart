import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapLegend extends StatelessWidget {
  final String layerType;

  const MapLegend({super.key, required this.layerType});

  @override
  Widget build(BuildContext context) {
    if (layerType == 'base' || layerType == 'radar') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getLegendTitle(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ..._buildLegendItems(),
        ],
      ),
    );
  }

  String _getLegendTitle() {
    switch (layerType) {
      case 'temperature': return 'Temperature (°C)';
      case 'rainfall': return 'Rainfall (mm)';
      case 'wind': return 'Wind Speed (km/h)';
      case 'cyclones': return 'Cyclone Risk';
      case 'flood': return 'Flood Risk';
      default: return 'Legend';
    }
  }

  List<Widget> _buildLegendItems() {
    switch (layerType) {
      case 'temperature':
        return [
          _buildItem(Colors.red, '> 35°C (Very Hot)'),
          _buildItem(Colors.orange, '25-35°C (Warm)'),
          _buildItem(Colors.blue, '< 25°C (Cool)'),
        ];
      case 'rainfall':
        return [
          _buildItem(Colors.blue.shade900, 'Heavy Rainfall'),
          _buildItem(Colors.blue.shade600, 'Moderate Rainfall'),
          _buildItem(Colors.blue.shade300, 'Light Rainfall'),
        ];
      case 'wind':
        return [
          _buildItem(Colors.purple, '> 60 km/h (Strong)'),
          _buildItem(Colors.deepPurpleAccent, '30-60 km/h (Moderate)'),
          _buildItem(Colors.lightBlueAccent, '< 30 km/h (Light)'),
        ];
      case 'cyclones':
      case 'flood':
        return [
          _buildItem(Colors.redAccent, 'High Risk / Alert'),
        ];
      default:
        return [];
    }
  }

  Widget _buildItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
