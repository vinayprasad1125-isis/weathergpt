import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../main.dart'; // To access rootScaffoldMessengerKey

class DemoAlertManager {
  static final DemoAlertManager _instance = DemoAlertManager._internal();
  static DemoAlertManager get instance => _instance;

  DemoAlertManager._internal();

  final ValueNotifier<bool> isDemoMode = ValueNotifier<bool>(false);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final List<WeatherAlert> demoAlerts = [];

  Timer? _timer;
  final Random _random = Random();

  final List<Map<String, String>> _alertTemplates = [
    {
      'severity': 'Severe',
      'type': 'Rain',
      'description': 'Heavy rain expected in your area.',
      'title': 'Heavy Rain Warning',
    },
    {
      'severity': 'Extreme',
      'type': 'Heat',
      'description': 'Temperature rising rapidly — current temperature 39°C.',
      'title': 'Heat Alert',
    },
    {
      'severity': 'Moderate',
      'type': 'Thunderstorm',
      'description': 'Thunderstorm activity detected nearby.',
      'title': 'Thunderstorm Warning',
    },
    {
      'severity': 'Moderate',
      'type': 'Wind',
      'description': 'Strong winds expected — wind speed may reach 28 km/h.',
      'title': 'Strong Wind Alert',
    },
    {
      'severity': 'Extreme',
      'type': 'Heatwave',
      'description': 'Heatwave conditions detected — feels like 43°C.',
      'title': 'Heatwave Warning',
    },
    {
      'severity': 'Minor',
      'type': 'Fog',
      'description': 'Reduced visibility expected due to fog.',
      'title': 'Visibility Alert',
    },
    {
      'severity': 'Moderate',
      'type': 'Rain',
      'description': 'High chance of rainfall within the next hour.',
      'title': 'Rain Probability',
    },
  ];

  void toggle() {
    isDemoMode.value = !isDemoMode.value;
    if (isDemoMode.value) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_timer != null && _timer!.isActive) return;
    if (demoAlerts.isEmpty) {
      _generateAlert();
      _generateAlert(); // Generate 2 immediate alerts so it's not empty
    } else {
      _generateAlert();
    }
    _scheduleNextAlert();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNextAlert() {
    if (!isDemoMode.value) return;

    // Random interval between 10 and 30 seconds
    final delay = Duration(seconds: 10 + _random.nextInt(21));
    _timer = Timer(delay, () {
      if (isDemoMode.value) {
        _generateAlert();
        _scheduleNextAlert(); // Schedule the next one
      }
    });
  }

  void _generateAlert() {
    final template = _alertTemplates[_random.nextInt(_alertTemplates.length)];
    
    final newAlert = WeatherAlert(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      severity: template['severity']!,
      type: template['title']!, // Using title as type for UI display
      location: 'Your Area',
      time: 'Just now',
      description: template['description']!,
      recommendedAction: 'Stay safe and monitor local news.',
      source: 'Demo System',
      status: 'Active',
      isDemo: true,
    );

    // Insert at top of list
    demoAlerts.insert(0, newAlert);
    
    // Update unread count
    unreadCount.value += 1;

    // Show popup notification
    _showPopup(newAlert);
  }

  void _showPopup(WeatherAlert alert) {
    if (rootScaffoldMessengerKey.currentState == null) return;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: kToolbarHeight + 10, left: 16, right: 16),
      dismissDirection: DismissDirection.horizontal,
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIconForAlert(alert.type),
            color: _getColorForSeverity(alert.severity),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alert.type,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• Just now',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // We want the snackbar to appear at the TOP since it's a notification popup
    rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
  
  IconData _getIconForAlert(String type) {
    if (type.contains('Rain') || type.contains('Thunderstorm')) return Icons.water_drop;
    if (type.contains('Heat')) return Icons.thermostat;
    if (type.contains('Wind')) return Icons.air;
    if (type.contains('Fog')) return Icons.cloud;
    return Icons.warning;
  }
  
  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme': return Colors.red;
      case 'severe': return Colors.orange;
      case 'moderate': return Colors.amber;
      case 'minor': return Colors.blue;
      default: return Colors.grey;
    }
  }

  // Dispose not strictly needed for singleton, but good practice
  void dispose() {
    _stop();
    isDemoMode.dispose();
    unreadCount.dispose();
  }
}
