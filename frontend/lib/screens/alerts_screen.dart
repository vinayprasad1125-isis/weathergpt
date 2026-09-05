import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/demo_alert_manager.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_card.dart';
import '../widgets/headers.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<WeatherAlert> _realAlerts = [];
  List<WeatherAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    DemoAlertManager.instance.unreadCount.addListener(_onNewDemoAlert);
    _loadAlerts();
  }

  @override
  void dispose() {
    DemoAlertManager.instance.unreadCount.removeListener(_onNewDemoAlert);
    super.dispose();
  }

  void _onNewDemoAlert() {
    if (mounted) {
      _combineAlerts();
    }
  }

  Future<void> _loadAlerts() async {
    _realAlerts = await AlertService.getActiveAlerts();
    if (mounted) {
      _combineAlerts();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _combineAlerts() {
    // Clear unread count when viewed, but temporarily remove listener to avoid infinite loop
    DemoAlertManager.instance.unreadCount.removeListener(_onNewDemoAlert);
    DemoAlertManager.instance.unreadCount.value = 0;
    DemoAlertManager.instance.unreadCount.addListener(_onNewDemoAlert);

    final demoAlerts = DemoAlertManager.instance.demoAlerts;
    setState(() {
      _alerts = [...demoAlerts, ..._realAlerts];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Disaster Alerts'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Alerts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'There are no extreme weather warnings in your area.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    return AlertCard(alert: _alerts[index]);
                  },
                ),
    );
  }
}
