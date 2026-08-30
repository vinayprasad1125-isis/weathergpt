import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_gis_service.dart';
import '../services/api_weather_service.dart';
import '../services/location_store.dart';
import '../services/geojson_helper.dart';
import '../models/models.dart';
import '../widgets/headers.dart';
import '../widgets/map_layer_selector.dart';
import '../widgets/map_legend.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  String _currentLayer = 'base';
  Map<String, dynamic>? _layerData;
  bool _isLoading = false;
  LatLng _currentMapCenter = const LatLng(13.0827, 80.2707); // Default to Chennai
  String? _selectedState;
  List<Polygon> _stateBoundaryPolygons = [];
  WeatherData? _currentLocationWeather;

  final List<String> _layers = ['temperature', 'wind', 'rainfall', 'alerts', 'cyclones', 'flood'];

  final Map<String, LatLng> _indianStates = {
    'Andhra Pradesh': const LatLng(15.9129, 79.7400),
    'Arunachal Pradesh': const LatLng(28.2180, 94.7278),
    'Assam': const LatLng(26.2006, 92.9376),
    'Bihar': const LatLng(25.0961, 85.3131),
    'Chhattisgarh': const LatLng(21.2787, 81.8661),
    'Goa': const LatLng(15.2993, 74.1240),
    'Gujarat': const LatLng(22.2587, 71.1924),
    'Haryana': const LatLng(29.0588, 76.0856),
    'Himachal Pradesh': const LatLng(31.1048, 77.1665),
    'Jharkhand': const LatLng(23.6102, 85.2799),
    'Karnataka': const LatLng(15.3173, 75.7139),
    'Kerala': const LatLng(10.8505, 76.2711),
    'Madhya Pradesh': const LatLng(22.9734, 78.6569),
    'Maharashtra': const LatLng(19.7515, 75.7139),
    'Manipur': const LatLng(24.6637, 93.9063),
    'Meghalaya': const LatLng(25.4670, 91.3662),
    'Mizoram': const LatLng(23.1645, 92.9376),
    'Nagaland': const LatLng(26.1584, 94.5624),
    'Odisha': const LatLng(20.9517, 85.0985),
    'Punjab': const LatLng(31.1471, 75.3412),
    'Rajasthan': const LatLng(27.0238, 74.2179),
    'Sikkim': const LatLng(27.5330, 88.5122),
    'Tamil Nadu': const LatLng(11.1271, 78.6569),
    'Telangana': const LatLng(18.1124, 79.0193),
    'Tripura': const LatLng(23.9408, 91.9882),
    'Uttar Pradesh': const LatLng(26.8467, 80.9462),
    'Uttarakhand': const LatLng(30.0668, 79.0193),
    'West Bengal': const LatLng(22.9868, 87.8550),
  };

  @override
  void initState() {
    super.initState();
    _fetchLayerData();
    _fetchLocationWeather(lat: _currentMapCenter.latitude, lon: _currentMapCenter.longitude);
  }

  Future<void> _fetchLocationWeather({String? city, double? lat, double? lon}) async {
    // Update shared location store so chat uses the same coordinates
    LocationStore.update(city: city, lat: lat, lon: lon);
    try {
      final weather = await ApiWeatherService.getCurrentWeather(city: city, lat: lat, lon: lon);
      if (mounted) {
        setState(() {
          _currentLocationWeather = weather;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch location weather: $e");
    }
  }

  Future<void> _fetchLayerData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiGisService.getGisLayer(_currentLayer, _currentMapCenter.latitude, _currentMapCenter.longitude);
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
    
    if (layer == 'base') {
      setState(() => _layerData = null);
    } else if (layer == 'radar') {
      setState(() => _layerData = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Radar data unavailable')),
      );
    } else {
      _fetchLayerData();
    }
  }
  
  Future<void> _recenter() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locating...')));

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentMapCenter = LatLng(position.latitude, position.longitude);
        _selectedState = null; // Clear state dropdown if we use GPS
      });
      _mapController.move(_currentMapCenter, 12.0);
      if (_currentLayer != 'base' && _currentLayer != 'radar') {
        _fetchLayerData();
      }
      _fetchLocationWeather(lat: position.latitude, lon: position.longitude);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get location.')));
    }
  }

  void _onStateSelected(String? stateName) async {
    if (stateName != null && _indianStates.containsKey(stateName)) {
      setState(() {
        _selectedState = stateName;
        _currentMapCenter = _indianStates[stateName]!;
        _stateBoundaryPolygons = [];
      });
      _mapController.move(_currentMapCenter, 6.0); // Use zoom 6.0 for full state view
      if (_currentLayer != 'base' && _currentLayer != 'radar') {
        _fetchLayerData();
      }
      _fetchLocationWeather(
        city: stateName,
        lat: _currentMapCenter.latitude,
        lon: _currentMapCenter.longitude,
      );
      
      final rings = await GeoJsonHelper.getPolygonsForState(stateName);
      if (mounted && _selectedState == stateName) {
        setState(() {
          _stateBoundaryPolygons = rings.map<Polygon>((ring) => Polygon(
            points: ring,
            color: AppColors.primary.withOpacity(0.15),
            borderColor: AppColors.primary,
            borderStrokeWidth: 2.0,
          )).toList();
        });
      }
    }
  }

  Color _getColorForValue(dynamic value) {
    if (value is! num) return AppColors.primary;
    
    if (_currentLayer == 'temperature') {
      if (value > 35) return Colors.red;
      if (value > 25) return Colors.orange;
      return Colors.blue;
    } else if (_currentLayer == 'wind') {
      if (value > 60) return Colors.purple;
      if (value > 30) return Colors.deepPurpleAccent;
      return Colors.lightBlueAccent;
    } else if (_currentLayer == 'rainfall') {
      if (value > 50) return Colors.blue.shade900;
      if (value > 10) return Colors.blue.shade600;
      return Colors.blue.shade300;
    } else if (_currentLayer == 'alerts' || _currentLayer == 'cyclones' || _currentLayer == 'flood') {
      return Colors.redAccent;
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
        
        Widget markerContent;

        if (_currentLocationWeather != null) {
          markerContent = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniMetric(LucideIcons.thermometer, '${_currentLocationWeather!.currentTemp}°C'),
                const SizedBox(width: 6),
                _buildMiniMetric(LucideIcons.wind, '${_currentLocationWeather!.windSpeed}km/h'),
                const SizedBox(width: 6),
                _buildMiniMetric(LucideIcons.droplets, '${_currentLocationWeather!.humidity}%'),
              ],
            ),
          );
        } else {
          markerContent = Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getColorForValue(val)),
            ),
            child: Text('$val $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          );
        }

        markers.add(Marker(
          point: LatLng(lat, lon),
          width: 180,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              markerContent,
              Icon(LucideIcons.mapPin, color: _getColorForValue(val), size: 28),
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
              initialCenter: _currentMapCenter,
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.imd.weathergpt',
              ),
              if (_stateBoundaryPolygons.isNotEmpty)
                PolygonLayer(polygons: _stateBoundaryPolygons),
              if (_currentLayer != 'base' && _currentLayer != 'radar')
                MarkerLayer(markers: markers),
            ],
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
            
          // Map Layer Selector Dropdown (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: MapLayerSelector(
              selectedLayer: _currentLayer,
              onLayerChanged: _changeLayer,
            ),
          ),
            
          // State Selector Dropdown (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
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
                  hint: const Text('Select State', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _selectedState,
                  icon: const Icon(LucideIcons.chevronDown, size: 20),
                  onChanged: _onStateSelected,
                  items: _indianStates.keys.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
            

          // Map Legend (Bottom Left)
          Positioned(
            bottom: 20,
            left: 16,
            child: MapLegend(layerType: _currentLayer),
          ),
            
          // Recenter Button (Bottom Right)
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

  Widget _buildMiniMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
