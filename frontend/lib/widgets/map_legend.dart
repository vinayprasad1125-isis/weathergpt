import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  final String layerType;
  const MapLegend({super.key, required this.layerType});

  @override
  Widget build(BuildContext context) {
    if (layerType == 'base' || layerType == 'satellite') return const SizedBox.shrink();

    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 6),
          ...items,
        ],
      ),
    );
  }

  String _title() {
    switch (layerType) {
      case 'temperature':   return '🌡 Temperature (°C)';
      case 'rainfall':      return '🌧 Rainfall (mm)';
      case 'precipitation': return '💧 Precipitation (mm/h)';
      case 'wind':          return '💨 Wind Speed (km/h)';
      case 'cloud_cover':   return '☁ Cloud Cover (%)';
      case 'pressure':      return '📊 Pressure (hPa)';
      case 'humidity':      return '💦 Humidity (%)';
      case 'uv_index':      return '☀ UV Index';
      case 'cyclones':      return 'Cyclone Tracking';
      case 'flood':         return 'Flood Risk';
      case 'radar':         return '🌧 Radar Intensity';
      default:              return 'Legend';
    }
  }

  List<Widget> _buildItems() {
    switch (layerType) {
      case 'temperature':
        return [
          _gradientBar(colors: [
            const Color(0xFF000080), const Color(0xFF0066FF), const Color(0xFF00FFFF),
            const Color(0xFF99FF00), const Color(0xFFFFCC00), const Color(0xFFFF5500),
            const Color(0xFFB30000),
          ]),
          _gradientLabels(['<0°', '10°', '18°', '26°', '34°', '42°+']),
        ];
      case 'rainfall':
      case 'precipitation':
        return [
          _gradientBar(colors: [
            const Color(0xFFB0E0E6), const Color(0xFF87CEEB), const Color(0xFF1E90FF),
            const Color(0xFF0000FF), const Color(0xFF00008B),
          ]),
          _gradientLabels(['0', '1', '5', '10', '20+']),
        ];
      case 'wind':
        return [
          _gradientBar(colors: [
            const Color(0xFF90EE90), const Color(0xFFFFD700), const Color(0xFFFF8C00),
            const Color(0xFFFF4500), const Color(0xFF9400D3), const Color(0xFF800080),
          ]),
          _gradientLabels(['0', '10', '40', '60', '90+']),
        ];
      case 'cloud_cover':
        return [
          _gradientBar(colors: [
            const Color(0xFF87CEEB), const Color(0xFFB0C4DE), const Color(0xFF708090),
            const Color(0xFF505060), const Color(0xFF2F2F3F),
          ]),
          _gradientLabels(['0%', '25%', '50%', '75%', '100%']),
        ];
      case 'pressure':
        return [
          _gradientBar(colors: [
            const Color(0xFF8B0000), const Color(0xFFFF4500), const Color(0xFFFFD700),
            const Color(0xFF00BFFF), const Color(0xFF00008B),
          ]),
          _gradientLabels(['980', '995', '1010', '1025', '1040']),
        ];
      case 'humidity':
        return [
          _gradientBar(colors: [
            const Color(0xFFFFF8DC), const Color(0xFF90EE90), const Color(0xFF00BFFF),
            const Color(0xFF0000FF), const Color(0xFF00008B),
          ]),
          _gradientLabels(['0%', '25%', '50%', '75%', '100%']),
        ];
      case 'uv_index':
        return [
          _gradientBar(colors: [
            const Color(0xFF00CC00), const Color(0xFFFFFF00), const Color(0xFFFF8C00),
            const Color(0xFFFF0000), const Color(0xFF9400D3),
          ]),
          _gradientLabels(['0', '3', '6', '8', '11+']),
          const SizedBox(height: 4),
          _uvCategories(),
        ];
      case 'cyclones':
        return [_item(Colors.red.shade700, 'Active Cyclone / Wind Alert')];
      case 'flood':
        return [_item(Colors.red.shade700, 'Active Flood / Rain Alert')];
      case 'radar':
        return [
          _gradientBar(colors: [
            Colors.green.shade400, Colors.yellow, Colors.orange, Colors.red, Colors.purple,
          ]),
          _gradientLabels(['Light', '', 'Moderate', '', 'Heavy']),
        ];
      default:
        return [];
    }
  }

  Widget _uvCategories() {
    final cats = [
      (_uvColor(1), 'Low (0-2)'),
      (_uvColor(4), 'Moderate (3-5)'),
      (_uvColor(7), 'High (6-7)'),
      (_uvColor(9), 'Very High (8-10)'),
      (_uvColor(12), 'Extreme (11+)'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cats.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c.$1, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(c.$2, style: const TextStyle(fontSize: 9)),
        ]),
      )).toList(),
    );
  }

  Color _uvColor(double v) {
    if (v >= 11) return const Color(0xFF9400D3);
    if (v >= 8)  return const Color(0xFFFF0000);
    if (v >= 6)  return const Color(0xFFFF8C00);
    if (v >= 3)  return const Color(0xFFFFFF00);
    return const Color(0xFF00CC00);
  }

  Widget _gradientBar({required List<Color> colors}) {
    return Container(
      width: 140,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(colors: colors),
      ),
    );
  }

  Widget _gradientLabels(List<String> labels) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: SizedBox(
        width: 140,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(l, style: const TextStyle(fontSize: 9))).toList(),
        ),
      ),
    );
  }

  Widget _item(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
