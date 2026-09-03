import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_weather_service.dart';
import '../services/location_store.dart';
import '../services/geojson_helper.dart';
import '../services/gis_layer_service.dart';
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
  GisLayerResult? _layerResult;
  bool _isLoading = false;
  String? _layerError;
  LatLng _currentMapCenter = const LatLng(22.0, 80.0); // Center of India
  
  String? _selectedState;
  List<Polygon> _selectedStatePolygons = [];
  Map<String, List<List<LatLng>>> _allStatePolygons = {};
  
  WeatherData? _currentLocationWeather;

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
    'Telangana': const LatLng(17.3850, 78.4867),
    'Tripura': const LatLng(23.8315, 91.2868),
    'Uttar Pradesh': const LatLng(26.8467, 80.9462),
    'Uttarakhand': const LatLng(30.3165, 78.0322),
    'West Bengal': const LatLng(22.5726, 88.3639),
  };

  @override
  void initState() {
    super.initState();
    _loadAllPolygons();
    _fetchLocationWeather(lat: _currentMapCenter.latitude, lon: _currentMapCenter.longitude);
  }

  Future<void> _loadAllPolygons() async {
    final polygons = await GeoJsonHelper.getAllStatePolygons();
    if (mounted) setState(() => _allStatePolygons = polygons);
  }

  Future<void> _fetchLocationWeather({String? city, double? lat, double? lon}) async {
    LocationStore.update(city: city, lat: lat, lon: lon);
    try {
      final weather = await ApiWeatherService.getCurrentWeather(city: city, lat: lat, lon: lon);
      if (mounted) setState(() => _currentLocationWeather = weather);
    } catch (e) {
      debugPrint('Failed to fetch location weather: $e');
    }
  }

  Future<void> _fetchLayerData(String layer) async {
    if (layer == 'base' || layer == 'radar') {
      setState(() {
        _layerResult = null;
        _layerError = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _layerError = null;
      _layerResult = null;
    });

    final result = await GisLayerService.fetchRegionalLayer(layer);

    if (!mounted) return;
    setState(() {
      _layerResult = result;
      _layerError = result.errorMessage;
      _isLoading = false;
    });
  }

  void _changeLayer(String layer) {
    setState(() => _currentLayer = layer);
    _fetchLayerData(layer);
  }

  Future<void> _recenter() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions denied.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions permanently denied.')));
      return;
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locating...')));

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentMapCenter = LatLng(position.latitude, position.longitude);
        _selectedState = null;
        _selectedStatePolygons = [];
      });
      _mapController.move(_currentMapCenter, 8.0);
      _fetchLocationWeather(lat: position.latitude, lon: position.longitude);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get location.')));
    }
  }

  void _onStateSelected(String? stateName) async {
    if (stateName == null || !_indianStates.containsKey(stateName)) return;
    setState(() {
      _selectedState = stateName;
      _currentMapCenter = _indianStates[stateName]!;
      _selectedStatePolygons = [];
    });
    _mapController.move(_currentMapCenter, 6.5);
    _fetchLocationWeather(
      city: stateName,
      lat: _currentMapCenter.latitude,
      lon: _currentMapCenter.longitude,
    );
    
    final rings = _allStatePolygons[stateName] ?? [];
    if (mounted && _selectedState == stateName) {
      setState(() {
        _selectedStatePolygons = rings.map<Polygon>((ring) => Polygon(
          points: ring,
          color: AppColors.primary.withOpacity(0.0), // No fill, we just want border
          borderColor: AppColors.primary,
          borderStrokeWidth: 3.0,
        )).toList();
      });
    }
  }

  // ─── Color helpers ────────────────────────────────────────────────────────

  Widget _metric(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.primary),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ],
  );

  // ─── Empty / error state overlay ────────────────────────────────────────────────────────

  Color _temperatureColor(double v) {
    if (v >= 42) return const Color(0xFF4A0000); // Very deep, dark red
    if (v >= 38) return const Color(0xFFB30000); // Dark red
    if (v >= 34) return const Color(0xFFFF0000); // Bright pure red
    if (v >= 30) return const Color(0xFFFF5500); // Vibrant orange
    if (v >= 26) return const Color(0xFFFFCC00); // Bright yellow
    if (v >= 22) return const Color(0xFF99FF00); // Bright yellow-green
    if (v >= 18) return const Color(0xFF00FF44); // Bright green
    if (v >= 14) return const Color(0xFF00FFFF); // Cyan
    if (v >= 10) return const Color(0xFF0066FF); // Bright blue
    return const Color(0xFF000080);              // Deep navy blue
  }

  Color _rainfallColor(double v) {
    if (v >= 20) return const Color(0xFF00008B);
    if (v >= 10) return const Color(0xFF0000FF);
    if (v >= 5)  return const Color(0xFF1E90FF);
    if (v >= 1)  return const Color(0xFF87CEEB);
    return const Color(0xFFB0E0E6);
  }

  Color _windColor(double v) {
    if (v >= 90) return const Color(0xFF800080);
    if (v >= 60) return const Color(0xFF9400D3);
    if (v >= 40) return const Color(0xFFFF4500);
    if (v >= 20) return const Color(0xFFFF8C00);
    if (v >= 10) return const Color(0xFFFFD700);
    return const Color(0xFF90EE90);
  }

  Color _colorForLayer(GisPoint pt) {
    switch (_currentLayer) {
      case 'temperature': return _temperatureColor(pt.value);
      case 'rainfall':    return _rainfallColor(pt.value);
      case 'wind':        return _windColor(pt.value);
      case 'cyclones':
      case 'flood':       return Colors.red.shade700;
      default: return AppColors.primary;
    }
  }

  // ─── Build Choropleth Polygons ───────────────────────────────────────────

  List<Polygon> _buildChoroplethPolygons() {
    final result = _layerResult;
    if (result == null || result.points.isEmpty || _currentLayer == 'base' || _currentLayer == 'radar') {
      return [];
    }

    // Map stateName to GisPoint for O(1) lookup
    final pointsMap = {for (var pt in result.points) pt.stateName: pt};
    List<Polygon> polygons = [];

    // Iterate through all states we parsed from geojson
    for (var entry in _allStatePolygons.entries) {
      final stateName = entry.key;
      final rings = entry.value;
      final pt = pointsMap[stateName];

      Color fillColor = Colors.transparent;
      Color borderColor = Colors.grey.withOpacity(0.5);

      if (pt != null) {
        // If we have data for this state, fill it with the thematic color
        fillColor = _colorForLayer(pt).withOpacity(0.45); // 45% opacity to show basemap clearly
        borderColor = Colors.white.withOpacity(0.3);
      } else {
        // No data for this state
        fillColor = Colors.grey.withOpacity(0.2);
      }

      for (var ring in rings) {
        polygons.add(Polygon(
          points: ring,
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: 1.0,
        ));
      }
    }
    
    // Add the currently selected state highlight border on top if any
    if (_selectedStatePolygons.isNotEmpty) {
      polygons.addAll(_selectedStatePolygons);
    }
    
    return polygons;
  }

  // ─── Empty / error state overlay ─────────────────────────────────────────

  Widget? _buildStatusOverlay() {
    if (_isLoading) {
      return Positioned.fill(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 12),
                Text('Loading $_currentLayer data…', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    if (_layerError != null && _layerResult?.points.isEmpty == true) {
      return Positioned(
        bottom: 90,
        left: 0, right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.70),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _layerError!,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    if (_currentLayer == 'radar') {
      return Positioned(
        bottom: 90,
        left: 0, right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade800.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Radar overlay from RainViewer', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final choroplethPolygons = _buildChoroplethPolygons();
    final statusOverlay = _buildStatusOverlay();

    return Scaffold(
      appBar: const AppHeader(title: 'GIS Map'),
      body: Stack(
        children: [
          // ── Main Map ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentMapCenter,
              initialZoom: 5.0, // Zoomed out to show all of India
              backgroundColor: const Color(0xFF1a1a2e),
            ),
            children: [
              // Dark base map (CartoDB Dark Matter) — shows borders & labels
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.imd.weathergpt',
              ),
              // OpenWeatherMap temperature heatmap overlay
              TileLayer(
                urlTemplate: 'https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=2368d7321df517b74335df5232c7e298',
                userAgentPackageName: 'com.imd.weathergpt',
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.75),
              ),

              // Radar tile overlay
              if (_currentLayer == 'radar')
                TileLayer(
                  urlTemplate: 'https://tilecache.rainviewer.com/v2/radar/0/{z}/{x}/{y}/2/1_1.png',
                  userAgentPackageName: 'com.imd.weathergpt',
                ),

              // Choropleth Polygons
              if (choroplethPolygons.isNotEmpty)
                PolygonLayer(polygons: choroplethPolygons),
                
              // If base map, just show selected state border
              if (_currentLayer == 'base' && _selectedStatePolygons.isNotEmpty)
                PolygonLayer(polygons: _selectedStatePolygons),
                
              // Location marker with attached weather bubble
              if (_currentLocationWeather != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentMapCenter,
                      width: 180,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
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
                                _metric(LucideIcons.thermometer, '${_currentLocationWeather!.currentTemp}°C'),
                                const SizedBox(width: 6),
                                _metric(LucideIcons.wind, '${_currentLocationWeather!.windSpeed}km/h'),
                                const SizedBox(width: 6),
                                _metric(LucideIcons.droplets, '${_currentLocationWeather!.humidity}%'),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 30),
                        ],
                      ),
                    ),
                  ],
                )
              else
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentMapCenter,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 30),
                    ),
                  ],
                ),
            ],
          ),

          // ── Overlays ──────────────────────────────────────────────────────

          // Layer type selector (top left)
          Positioned(
            top: 16,
            left: 16,
            child: MapLayerSelector(
              selectedLayer: _currentLayer,
              onLayerChanged: _changeLayer,
            ),
          ),

          // State selector (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text('Select State', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _selectedState,
                  icon: const Icon(LucideIcons.chevronDown, size: 20),
                  onChanged: _onStateSelected,
                  items: _indianStates.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                ),
              ),
            ),
          ),

          // Legend (bottom left)
          Positioned(
            bottom: 90,
            left: 16,
            child: MapLegend(layerType: _currentLayer),
          ),

          // Status / error overlay
          if (statusOverlay != null) statusOverlay,

          // Recenter button (bottom right)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'recenter',
              backgroundColor: AppColors.surface,
              onPressed: _recenter,
              child: const Icon(LucideIcons.locateFixed, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
