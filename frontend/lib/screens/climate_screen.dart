import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_climate_service.dart';
import '../widgets/headers.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  Map<String, dynamic>? _trendData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiClimateService.getClimateTrend(13.0827, 80.2707);
      setState(() {
        _trendData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppHeader(title: l10n.get('climate')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trendData == null
              ? const Center(child: Text("Data unavailable"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${l10n.get('climate')} - Temperature (Last 10 Years)",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Trend: ${_trendData!['trend']['direction'].toString().toUpperCase()} (${_trendData!['trend']['slope']} ${_trendData!['trend']['unit']})",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _trendData!['trend']['direction'] == 'increasing' ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: (_trendData!['historical_series'] as List).asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble());
                                }).toList(),
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
