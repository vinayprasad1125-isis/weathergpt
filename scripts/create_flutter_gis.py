import os
import re

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# 1. api_gis_service.dart
gis_service_file = os.path.join(base_dir, 'lib/services/api_gis_service.dart')
gis_service_content = '''import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiGisService {
  static Future<Map<String, dynamic>> getGisLayer(String layer, double lat, double lon) async {
    try {
      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/gis/layers/$layer?lat=$lat&lon=$lon');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('GIS API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load GIS data');
      }
    } catch (e) {
      debugPrint('Error fetching GIS layer: $e');
      rethrow;
    }
  }
}
'''
with open(gis_service_file, 'w') as f:
    f.write(gis_service_content)

# 2. map_screen.dart
map_screen_file = os.path.join(base_dir, 'lib/screens/map_screen.dart')
map_screen_content = '''import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_gis_service.dart';
import '../widgets/headers.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  String _currentLayer = 'temperature';
  Map<String, dynamic>? _layerData;
  bool _isLoading = false;
  final LatLng _defaultLocation = const LatLng(13.0827, 80.2707); # Chennai

  final List<String> _layers = ['temperature', 'wind', 'rainfall', 'alerts', 'cyclones', 'flood'];

  @override
  void initState() {
    super.initState();
    _fetchLayerData();
  }

  Future<void> _fetchLayerData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiGisService.getGisLayer(_currentLayer, _defaultLocation.latitude, _defaultLocation.longitude);
      setState(() {
        _layerData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _changeLayer(String layer) {
    setState(() {
      _currentLayer = layer;
    });
    _fetchLayerData();
  }
  
  void _recenter() {
    _mapController.move(_defaultLocation, 10.0);
  }

  Color _getColorForValue(dynamic value) {
    if (_currentLayer == 'temperature') {
      if (value is num) {
        if (value > 35) return Colors.red;
        if (value > 25) return Colors.orange;
        return Colors.blue;
      }
    } else if (_currentLayer == 'alerts' || _currentLayer == 'cyclones' || _currentLayer == 'flood') {
      return Colors.redAccent;
    } else if (_currentLayer == 'rainfall') {
      return Colors.blueAccent;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    
    if (_layerData != null && _layerData!['features'] != null) {
      for (var feature in _layerData!['features']) {
        final lat = feature['latitude'];
        final lon = feature['longitude'];
        final val = feature['value'];
        final unit = feature['unit'] ?? '';
        
        markers.add(Marker(
          point: LatLng(lat, lon),
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getColorForValue(val)),
                ),
                child: Text('$val $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(LucideIcons.mapPin, color: _getColorForValue(val), size: 24),
            ],
          )
        ));
      }
    }

    return Scaffold(
      appBar: const AppHeader(title: 'GIS Map'),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.imd.weathergpt',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
            
          // Layer Selection
          Positioned(
            bottom: 20,
            left: 20,
            right: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _layers.map((layer) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(layer.toUpperCase()),
                    selected: _currentLayer == layer,
                    onSelected: (selected) {
                      if (selected) _changeLayer(layer);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _currentLayer == layer ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
          
          // Recenter Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'recenter',
              backgroundColor: AppColors.surface,
              onPressed: _recenter,
              child: const Icon(LucideIcons.locateFixed, color: AppColors.primary),
            ),
          )
        ],
      ),
    );
  }
}
'''
with open(map_screen_file, 'w') as f:
    f.write(map_screen_content)

# 3. Update main.dart
main_file = os.path.join(base_dir, 'lib/main.dart')
with open(main_file, 'r') as f:
    main_content = f.read()

if 'import \'screens/map_screen.dart\';' not in main_content:
    main_content = main_content.replace(
        'import \'screens/climate_screen.dart\';',
        'import \'screens/climate_screen.dart\';\\nimport \'screens/map_screen.dart\';'
    ).replace(
        'page = const PlaceholderScreen(title: \'Maps\');',
        'page = const MapScreen();'
    )
    with open(main_file, 'w') as f:
        f.write(main_content)

print("Flutter GIS Screen added.")
