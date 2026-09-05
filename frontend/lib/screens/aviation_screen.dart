import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_aviation_service.dart';
import '../widgets/headers.dart';
import '../theme/app_theme.dart';

class AviationScreen extends StatefulWidget {
  const AviationScreen({super.key});

  @override
  State<AviationScreen> createState() => _AviationScreenState();
}

class _AviationScreenState extends State<AviationScreen> {
  final TextEditingController _stationController = TextEditingController(text: 'VOMM');
  
  bool _isLoading = false;
  String _error = '';
  List<dynamic>? _metarData;
  List<dynamic>? _tafData;

  @override
  void initState() {
    super.initState();
    _fetchAviationData();
  }

  Future<void> _fetchAviationData() async {
    final station = _stationController.text.trim().toUpperCase();
    if (station.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _metarData = null;
      _tafData = null;
    });

    try {
      final metar = await ApiAviationService.getMetar(station);
      final taf = await ApiAviationService.getTaf(station);
      
      setState(() {
        _metarData = metar;
        _tafData = taf;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch data for $station. Ensure it is a valid ICAO code.';
        _isLoading = false;
      });
    }
  }

  Widget _buildMetarCard() {
    if (_metarData == null || _metarData!.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No METAR data available.")));
    }
    
    final metar = _metarData![0]; // latest observation
    
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
                Icon(LucideIcons.planeTakeoff, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Current METAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow("Raw Text:", metar['rawOb'] ?? 'N/A'),
            const SizedBox(height: 12),
            _infoRow("Time:", metar['obsTime']?.toString() ?? 'N/A'),
            _infoRow("Temp / Dewpoint:", "${metar['temp']}°C / ${metar['dewp']}°C"),
            _infoRow("Wind:", "${metar['wdir']}° at ${metar['wspd']} kts"),
            _infoRow("Visibility:", "${metar['visib']} sm"),
            _infoRow("Altimeter:", "${metar['altim']} inHg"),
            if (metar['clouds'] != null)
              _infoRow("Clouds:", (metar['clouds'] as List).map((c) => "${c['cover']} at ${c['base'] ?? 'surface'} ft").join(", ")),
          ],
        ),
      ),
    );
  }

  Widget _buildTafCard() {
    if (_tafData == null || _tafData!.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No TAF data available.")));
    }
    
    final taf = _tafData![0]; // latest forecast
    
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
                Icon(LucideIcons.calendarClock, color: AppColors.primary),
                SizedBox(width: 8),
                Text("TAF Forecast", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow("Raw Text:", taf['rawTAF'] ?? 'N/A'),
            const SizedBox(height: 12),
            _infoRow("Issue Time:", taf['issueTime'] ?? 'N/A'),
            _infoRow("Valid Time:", "${taf['validTimeFrom']} to ${taf['validTimeTo']}"),
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
            width: 120,
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
    return Scaffold(
      appBar: const AppHeader(title: 'Aviation Weather'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stationController,
                    decoration: InputDecoration(
                      labelText: 'Airport ICAO Code (e.g. VOMM)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(LucideIcons.search),
                    ),
                    onSubmitted: (_) => _fetchAviationData(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _fetchAviationData,
                  child: const Text("Search", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                  ? Center(child: Text(_error, style: TextStyle(color: AppColors.error)))
                  : ListView(
                      children: [
                        _buildMetarCard(),
                        const SizedBox(height: 16),
                        _buildTafCard(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
