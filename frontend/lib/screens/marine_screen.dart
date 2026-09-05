import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_weather_service.dart';
import '../services/location_store.dart';
import '../widgets/headers.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class MarineScreen extends StatefulWidget {
  const MarineScreen({super.key});

  @override
  State<MarineScreen> createState() => _MarineScreenState();
}

class _MarineScreenState extends State<MarineScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _marineData;

  final List<Map<String, dynamic>> _marineLocations = [
    {"name": "Bay of Bengal", "lat": 15.0, "lon": 88.0},
    {"name": "Arabian Sea", "lat": 15.0, "lon": 65.0},
    {"name": "Indian Ocean", "lat": -10.0, "lon": 75.0},
    {"name": "Pacific Ocean", "lat": 0.0, "lon": -140.0},
    {"name": "Atlantic Ocean", "lat": 0.0, "lon": -30.0},
    {"name": "Mediterranean Sea", "lat": 35.0, "lon": 18.0},
    {"name": "Current Location", "lat": null, "lon": null},
  ];

  String _selectedLocation = "Bay of Bengal";

  @override
  void initState() {
    super.initState();
    _fetchMarineData();
  }

  Future<void> _fetchMarineData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      double lat = 15.0; // default to Bay of Bengal
      double lon = 88.0;

      if (_selectedLocation == "Current Location") {
        lat = LocationStore.currentLat ?? 13.0827;
        lon = LocationStore.currentLon ?? 80.2707;
      } else {
        final loc = _marineLocations.firstWhere((element) => element["name"] == _selectedLocation);
        lat = loc["lat"];
        lon = loc["lon"];
      }

      final data = await ApiWeatherService.getMarineWeather(lat, lon);
      setState(() {
        _marineData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildCurrentCard(Map<String, dynamic> current) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.waves, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text("Current Marine Conditions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow("Wave Height:", current['wave_height'] != null ? "${current['wave_height']} m" : "N/A (Inland)"),
            _infoRow("Wave Direction:", current['wave_direction'] != null ? "${current['wave_direction']}°" : "N/A"),
            _infoRow("Wave Period:", current['wave_period'] != null ? "${current['wave_period']} s" : "N/A"),
            _infoRow("Ocean Current Vel:", current['ocean_current_velocity'] != null ? "${current['ocean_current_velocity']} km/h" : "N/A"),
            _infoRow("Ocean Current Dir:", current['ocean_current_direction'] != null ? "${current['ocean_current_direction']}°" : "N/A"),
            _infoRow("Sea Surface Temp:", current['sea_surface_temperature'] != null ? "${current['sea_surface_temperature']} °C" : "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppHeader(title: l10n.get('marine')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error, style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMarineData,
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMarineData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLocation,
                            isExpanded: true,
                            icon: const Icon(LucideIcons.chevronDown),
                            items: _marineLocations.map((loc) {
                              return DropdownMenuItem<String>(
                                value: loc["name"],
                                child: Text(loc["name"], style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedLocation = val;
                                });
                                _fetchMarineData();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_marineData?['current'] != null && _marineData!['current'].isNotEmpty)
                        _buildCurrentCard(_marineData!['current'])
                      else
                        const Center(child: Text("No marine data available for this location.")),
                    ],
                  ),
                ),
    );
  }
}
