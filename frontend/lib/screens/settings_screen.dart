import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/headers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useCelsius = true;
  bool _useKilometers = true;
  bool _severeAlerts = true;
  bool _dailySummary = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDark = themeProvider?.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppHeader(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('General'),
          _buildSettingsCard(context, [
            _buildSwitchTile(
              title: 'Temperature Unit',
              subtitle: _useCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
              icon: LucideIcons.thermometer,
              value: _useCelsius,
              onChanged: (val) => setState(() => _useCelsius = val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Distance Unit',
              subtitle: _useKilometers ? 'Kilometers (km)' : 'Miles (mi)',
              icon: LucideIcons.ruler,
              value: _useKilometers,
              onChanged: (val) => setState(() => _useKilometers = val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Use dark theme',
              icon: LucideIcons.moon,
              value: isDark,
              onChanged: (val) {
                if (themeProvider != null) {
                  themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                }
              },
            ),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          _buildSettingsCard(context, [
            _buildSwitchTile(
              title: 'Severe Alerts',
              subtitle: 'Push notifications for extreme weather',
              icon: LucideIcons.alertTriangle,
              value: _severeAlerts,
              onChanged: (val) => setState(() => _severeAlerts = val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Daily Summary',
              subtitle: 'Morning weather forecast briefing',
              icon: LucideIcons.sun,
              value: _dailySummary,
              onChanged: (val) => setState(() => _dailySummary = val),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildSettingsCard(context, [
            ListTile(
              leading: Icon(LucideIcons.info, color: AppColors.primary),
              title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Text('1.0.0', style: TextStyle(color: AppColors.textMuted)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(LucideIcons.shield, color: AppColors.primary),
              title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(LucideIcons.fileText, color: AppColors.primary),
              title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon, color: AppColors.primary),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
