import 'package:flutter/material.dart';

class MapLegend extends StatelessWidget {
  final String layerType;
  const MapLegend({super.key, required this.layerType});

  @override
  Widget build(BuildContext context) {
    if (layerType == 'base') return const SizedBox.shrink();

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
      case 'temperature': return 'Temperature (°C)';
      case 'rainfall':    return 'Rainfall (mm)';
      case 'wind':        return 'Wind Speed (km/h)';
      case 'cyclones':    return 'Cyclone Tracking';
      case 'flood':       return 'Flood Risk';
      case 'radar':       return 'Radar Intensity';
      default:            return 'Legend';
    }
  }

  List<Widget> _buildItems() {
    switch (layerType) {
      case 'temperature':
        return [
          _gradientBar(
            colors: [const Color(0xFF0033CC), const Color(0xFF00CCCC), const Color(0xFF88CC00),
                     const Color(0xFFFFDD00), const Color(0xFFFF6600), const Color(0xFF7B0000)],
          ),
          _gradientLabels(['<10', '18', '26', '34', '42+']),
        ];
      case 'rainfall':
        return [
          _gradientBar(
            colors: [const Color(0xFFB0E0E6), const Color(0xFF87CEEB), const Color(0xFF1E90FF),
                     const Color(0xFF0000FF), const Color(0xFF00008B)],
          ),
          _gradientLabels(['0', '1', '5', '10', '20+']),
        ];
      case 'wind':
        return [
          _gradientBar(
            colors: [const Color(0xFF90EE90), const Color(0xFFFFD700), const Color(0xFFFF8C00),
                     const Color(0xFFFF4500), const Color(0xFF9400D3), const Color(0xFF800080)],
          ),
          _gradientLabels(['0', '10', '40', '60', '90+']),
        ];
      case 'cyclones':
        return [
          _item(Colors.red.shade700, 'Active Cyclone / Wind Alert'),
        ];
      case 'flood':
        return [
          _item(Colors.red.shade700, 'Active Flood / Rain Alert'),
        ];
      case 'radar':
        return [
          _gradientBar(
            colors: [Colors.green.shade400, Colors.yellow, Colors.orange, Colors.red, Colors.purple],
          ),
          _gradientLabels(['Light', '', 'Moderate', '', 'Heavy']),
        ];
      default:
        return [];
    }
  }

  Widget _gradientBar({required List<Color> colors}) {
    return Container(
      width: 130,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.map((l) => Text(l, style: const TextStyle(fontSize: 9))).toList(),
      ),
    );
  }

  Widget _item(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
