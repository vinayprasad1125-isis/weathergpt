import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';
import '../widgets/headers.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  List<dynamic> _fullData = [];
  List<dynamic> _displayData = [];
  bool _isLoading = true;
  bool _showLast50Years = true;
  String _trendDirection = '';
  double _trendSlope = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/india_temperature_1901_2025.json');
      final data = json.decode(jsonString) as List<dynamic>;
      
      setState(() {
        _fullData = data;
        _isLoading = false;
        _updateDisplayData();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateDisplayData() {
    if (_showLast50Years) {
      // Last 50 years: 1975 to 2025
      _displayData = _fullData.where((item) => item['year'] >= 1975).toList();
    } else {
      _displayData = List.from(_fullData);
    }
    _calculateTrend();
  }
  
  void _calculateTrend() {
    if (_displayData.isEmpty) return;
    
    int n = _displayData.length;
    List<double> x = _displayData.map((e) => (e['year'] as num).toDouble()).toList();
    List<double> y = _displayData.map((e) => (e['annual_temp'] as num).toDouble()).toList();
    
    double meanX = x.reduce((a, b) => a + b) / n;
    double meanY = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      numerator += (x[i] - meanX) * (y[i] - meanY);
      denominator += (x[i] - meanX) * (x[i] - meanX);
    }
    
    _trendSlope = denominator != 0 ? numerator / denominator : 0.0;
    
    if (_trendSlope > 0) {
      _trendDirection = 'INCREASING';
    } else if (_trendSlope < 0) {
      _trendDirection = 'DECREASING';
    } else {
      _trendDirection = 'STABLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppHeader(title: l10n.get('climate')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displayData.isEmpty
              ? const Center(child: Text("Data unavailable"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${l10n.get('climate')} - India",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          DropdownButton<bool>(
                            value: _showLast50Years,
                            items: const [
                              DropdownMenuItem(value: true, child: Text("Last 50 Years")),
                              DropdownMenuItem(value: false, child: Text("Full Dataset")),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _showLast50Years = value;
                                  _updateDisplayData();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Trend: $_trendDirection (${_trendSlope.toStringAsFixed(3)} °C/year)",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _trendSlope > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 10 == 0) {
                                      return Text(value.toInt().toString());
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _displayData.map((e) {
                                  return FlSpot((e['year'] as num).toDouble(), (e['annual_temp'] as num).toDouble());
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
