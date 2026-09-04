import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../services/api_weather_service.dart';
import '../services/location_store.dart';
import '../services/geojson_helper.dart';
import '../services/gis_layer_service.dart';
import '../models/models.dart';
import '../widgets/headers.dart';
import '../widgets/map_layer_selector.dart';
import '../widgets/map_legend.dart';
import '../core/constants.dart';
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
  LatLng _currentMapCenter = const LatLng(22.0, 80.0);

  String? _selectedState;
  List<Polygon> _selectedStatePolygons = [];
  Map<String, List<List<LatLng>>> _allStatePolygons = {};

  WeatherData? _currentLocationWeather;

  // RainViewer — fetched live from API
  String? _radarTileUrl;
  bool _radarLoading = false;

  // OWM tile overlay — only shown for temperature
  bool _showOwmOverlay = false;

  // ─── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAllPolygons();
    _fetchLocationWeather(lat: _currentMapCenter.latitude, lon: _currentMapCenter.longitude);
    _fetchRadarTileUrl(); // pre-fetch so radar is instant when selected
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

  // ─── RainViewer live API ───────────────────────────────────────────────────

  Future<void> _fetchRadarTileUrl() async {
    if (_radarLoading) return;
    setState(() => _radarLoading = true);
    try {
      final resp = await http.get(Uri.parse(Config.rainviewerApiUrl))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final past = (data['radar']['past'] as List?) ?? [];
        if (past.isNotEmpty) {
          final path = past.last['path'] as String;
          // Use color scheme 4 (green->yellow->red) to match legend
          final url = 'https://tilecache.rainviewer.com$path/256/{z}/{x}/{y}/4/1_1.png';
          if (mounted) {
            setState(() {
              _radarTileUrl = url;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('RainViewer fetch error: $e');
    } finally {
      if (mounted) setState(() => _radarLoading = false);
    }
  }

  // ─── Layer data fetching ───────────────────────────────────────────────────

  Future<void> _fetchLayerData(String layer) async {
    // Layers that use raster tiles only — no choropleth fetch needed
    final rasterOnly = {'base', 'satellite', 'radar', 'temperature'};
    if (rasterOnly.contains(layer)) {
      setState(() {
        _layerResult = null;
        _layerError = null;
        _isLoading = false;
        _showOwmOverlay = layer == 'temperature';
      });
      if (layer == 'radar' && _radarTileUrl == null) {
        _fetchRadarTileUrl();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _layerError = null;
      _layerResult = null;
      _showOwmOverlay = false;
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

  // ─── Location ─────────────────────────────────────────────────────────────

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
    if (stateName == null || !AppConstants.indianStates.containsKey(stateName)) return;
    setState(() {
      _selectedState = stateName;
      _currentMapCenter = AppConstants.indianStates[stateName]!;
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
          color: AppColors.primary.withOpacity(0.0),
          borderColor: AppColors.primary,
          borderStrokeWidth: 3.0,
        )).toList();
      });
    }
  }

  // ─── Color helpers ─────────────────────────────────────────────────────────

  Color _temperatureColor(double v) {
    if (v >= 42) return const Color(0xFF4A0000);
    if (v >= 38) return const Color(0xFFB30000);
    if (v >= 34) return const Color(0xFFFF0000);
    if (v >= 30) return const Color(0xFFFF5500);
    if (v >= 26) return const Color(0xFFFFCC00);
    if (v >= 22) return const Color(0xFF99FF00);
    if (v >= 18) return const Color(0xFF00FF44);
    if (v >= 14) return const Color(0xFF00FFFF);
    if (v >= 10) return const Color(0xFF0066FF);
    return const Color(0xFF000080);
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

  Color _humidityColor(double v) {
    if (v >= 90) return const Color(0xFF00008B);
    if (v >= 75) return const Color(0xFF0000FF);
    if (v >= 50) return const Color(0xFF00BFFF);
    if (v >= 25) return const Color(0xFF90EE90);
    return const Color(0xFFFFFACD);
  }

  Color _pressureColor(double v) {
    if (v >= 1030) return const Color(0xFF00008B);
    if (v >= 1020) return const Color(0xFF00BFFF);
    if (v >= 1010) return const Color(0xFFFFD700);
    if (v >= 1000) return const Color(0xFFFF8C00);
    return const Color(0xFF8B0000);
  }

  Color _uvColor(double v) {
    if (v >= 11) return const Color(0xFF9400D3);
    if (v >= 8)  return const Color(0xFFFF0000);
    if (v >= 6)  return const Color(0xFFFF8C00);
    if (v >= 3)  return const Color(0xFFFFFF00);
    return const Color(0xFF00CC00);
  }

  Color _cloudColor(double v) {
    if (v >= 90) return const Color(0xFF2F2F3F);
    if (v >= 70) return const Color(0xFF505060);
    if (v >= 50) return const Color(0xFF708090);
    if (v >= 25) return const Color(0xFFB0C4DE);
    return const Color(0xFF87CEEB);
  }

  Color _colorForLayer(GisPoint pt) {
    switch (_currentLayer) {
      case 'temperature':   return _temperatureColor(pt.value);
      case 'rainfall':
      case 'precipitation': return _rainfallColor(pt.value);
      case 'wind':          return _windColor(pt.value);
      case 'humidity':      return _humidityColor(pt.value);
      case 'pressure':      return _pressureColor(pt.value);
      case 'uv_index':      return _uvColor(pt.value);
      case 'cloud_cover':   return _cloudColor(pt.value);
      case 'cyclones':
      case 'flood':         return Colors.red.shade700;
      default:              return AppColors.primary;
    }
  }

  // ─── Build base tile URL ───────────────────────────────────────────────────

  String get _baseTileUrl {
    switch (_currentLayer) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'base':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      default:
        // Highly subdued dark gray map for all weather visualizations
        // This ensures the meteorological data is the dominant visual element
        return 'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
    }
  }

  // ─── Choropleth ───────────────────────────────────────────────────────────

  List<Polygon> _buildChoroplethPolygons() {
    final result = _layerResult;
    final noChoro = {'base', 'satellite', 'radar', 'temperature'};
    if (result == null || result.points.isEmpty || noChoro.contains(_currentLayer)) {
      return _selectedStatePolygons;
    }

    final pointsMap = {for (var pt in result.points) pt.stateName: pt};
    List<Polygon> polygons = [];

    for (var entry in _allStatePolygons.entries) {
      final stateName = entry.key;
      final rings = entry.value;
      final pt = pointsMap[stateName];

      Color fillColor = Colors.grey.withOpacity(0.2);
      Color borderColor = Colors.grey.withOpacity(0.4);

      if (pt != null) {
        fillColor = _colorForLayer(pt).withOpacity(0.55);
        borderColor = Colors.white.withOpacity(0.25);
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

    // Selected state highlight on top
    if (_selectedStatePolygons.isNotEmpty) {
      polygons.addAll(_selectedStatePolygons);
    }

    return polygons;
  }

  // ─── Status overlay ────────────────────────────────────────────────────────

  Widget? _buildStatusOverlay() {
    if (_isLoading || _radarLoading) {
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
                Text(
                  _radarLoading ? 'Fetching radar…' : 'Loading ${_currentLayer.replaceAll('_', ' ')} data…',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
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
            child: Text(_layerError!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    if (_currentLayer == 'radar' && _radarTileUrl != null) {
      return Positioned(
        bottom: 100,
        left: 0, right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade800.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar, color: Colors.white, size: 15),
                const SizedBox(width: 7),
                const Text('Live radar · RainViewer', style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _fetchRadarTileUrl,
                  child: const Text('↻ Refresh', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentLayer == 'satellite') {
      return Positioned(
        bottom: 100,
        left: 0, right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🛰 ESRI World Imagery satellite', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      );
    }

    return null;
  }

  // ─── Weather bubble ────────────────────────────────────────────────────────

  Widget _metric(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.primary),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ],
  );

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final choroplethPolygons = _buildChoroplethPolygons();
    final statusOverlay = _buildStatusOverlay();

    return Scaffold(
      appBar: const AppHeader(title: 'Weather Map'),
      body: Stack(
        children: [
          // ── Main Map ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentMapCenter,
              initialZoom: 5.0,
              backgroundColor: const Color(0xFF1a1a2e),
            ),
            children: [
              // Base tile — switches by layer
              // Base tile — switches by layer
              TileLayer(
                urlTemplate: _baseTileUrl,
                userAgentPackageName: 'com.imd.weathergpt',
                tileDisplay: const TileDisplay.instantaneous(),
              ),

              // OWM temperature heatmap raster overlay (only for temperature layer)
              if (_showOwmOverlay && Config.owmApiKey.isNotEmpty)
                TileLayer(
                  urlTemplate: 'https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=${Config.owmApiKey}',
                  userAgentPackageName: 'com.imd.weathergpt',
                  tileDisplay: const TileDisplay.instantaneous(opacity: 1.0),
                  maxNativeZoom: 10, // Prevent 404s/broken tiles when zooming in closely
                ),


              // RainViewer radar overlay (only for radar layer, live URL)
              if (_currentLayer == 'radar' && _radarTileUrl != null)
                TileLayer(
                  urlTemplate: _radarTileUrl!,
                  userAgentPackageName: 'com.imd.weathergpt',
                  tileDisplay: const TileDisplay.instantaneous(opacity: 1.0),
                  maxNativeZoom: 7, // RainViewer only serves radar tiles up to zoom 7
                ),

              // Reference Label Map (Borders, States, Cities) — rendered ON TOP of weather layers
              if (_currentLayer != 'base' && _currentLayer != 'satellite')
                TileLayer(
                  urlTemplate: 'https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.imd.weathergpt',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),

              // Choropleth polygons
              if (choroplethPolygons.isNotEmpty)
                PolygonLayer(polygons: choroplethPolygons),

              // Base / satellite — just show selected state border if any
              if ((_currentLayer == 'base' || _currentLayer == 'satellite') &&
                  _selectedStatePolygons.isNotEmpty)
                PolygonLayer(polygons: _selectedStatePolygons),

              // Weather marker bubble
              if (_currentLocationWeather != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentMapCenter,
                      width: 190,
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
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
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

          // Layer selector (top left)
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
                  items: AppConstants.indianStates.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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

          // Status overlay
          if (statusOverlay != null) statusOverlay,

          // Recenter FAB (bottom right)
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
