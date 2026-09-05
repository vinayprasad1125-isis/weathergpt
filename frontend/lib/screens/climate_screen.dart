import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' as math;
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
  int _selectedYears = 50;
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
    if (_fullData.isEmpty) return;

    if (_selectedYears > 0) {
      int maxYear = _fullData.map((e) => e['year'] as int).reduce(math.max);
      int startYear = maxYear - _selectedYears;
      _displayData = _fullData.where((item) => (item['year'] as int) > startYear).toList();
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
                          DropdownButton<int>(
                            value: _selectedYears,
                            items: const [
                              DropdownMenuItem(value: 5, child: Text("Last 5 Years")),
                              DropdownMenuItem(value: 10, child: Text("Last 10 Years")),
                              DropdownMenuItem(value: 20, child: Text("Last 20 Years")),
                              DropdownMenuItem(value: 30, child: Text("Last 30 Years")),
                              DropdownMenuItem(value: 40, child: Text("Last 40 Years")),
                              DropdownMenuItem(value: 50, child: Text("Last 50 Years")),
                              DropdownMenuItem(value: 0, child: Text("Full Dataset")),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedYears = value;
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double maxY = 0;
                            double minY = double.infinity;
                            Set<int> localMaxima = {};
                            Set<int> localMinima = {};
                            
                            if (_displayData.isNotEmpty) {
                              maxY = _displayData.map((e) => (e['annual_temp'] as num).toDouble()).reduce(math.max);
                              minY = _displayData.map((e) => (e['annual_temp'] as num).toDouble()).reduce(math.min);
                              
                              for (int i = 0; i < _displayData.length; i++) {
                                double current = _displayData[i]['annual_temp'].toDouble();
                                bool isMax = true;
                                bool isMin = true;
                                
                                if (i > 0) {
                                  double prev = _displayData[i-1]['annual_temp'].toDouble();
                                  if (current <= prev) isMax = false;
                                  if (current >= prev) isMin = false;
                                }
                                if (i < _displayData.length - 1) {
                                  double next = _displayData[i+1]['annual_temp'].toDouble();
                                  if (current <= next) isMax = false;
                                  if (current >= next) isMin = false;
                                }
                                
                                if (isMax) localMaxima.add(i);
                                if (isMin) localMinima.add(i);
                              }
                            }

                            return LineChart(
                              LineChartData(
                                minY: _displayData.isNotEmpty ? (minY - 0.2).floorToDouble() : null,
                                maxY: _displayData.isNotEmpty ? (maxY + 0.2).ceilToDouble() : null,
                                gridData: const FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    axisNameWidget: const Text("Temperature (°C)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    axisNameSize: 24.0,
                                    sideTitles: const SideTitles(showTitles: true, reservedSize: 45.0),
                                  ),
                                  bottomTitles: AxisTitles(
                                    axisNameWidget: const Text("Year", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    axisNameSize: 24.0,
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30.0,
                                      interval: _selectedYears > 0 && _selectedYears <= 20 ? 2.0 : 10.0,
                                      getTitlesWidget: (value, meta) {
                                        if (value % (_selectedYears > 0 && _selectedYears <= 20 ? 2 : 10) == 0) {
                                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 12));
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
                                    barWidth: 3.0,
                                    dotData: FlDotData(
                                      show: true,
                                      checkToShowDot: (spot, barData) {
                                        int index = barData.spots.indexOf(spot);
                                        return localMaxima.contains(index) || localMinima.contains(index);
                                      },
                                      getDotPainter: (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 3.5,
                                          color: Colors.orange,
                                          strokeWidth: 2.0,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
