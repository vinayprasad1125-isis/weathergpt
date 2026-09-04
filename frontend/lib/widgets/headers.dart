import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/demo_alert_manager.dart';
import '../screens/alerts_screen.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppHeader({super.key, this.title = 'WeatherGPT'});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.primaryDark)),
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.of(context).pop(),
            )
          : IconButton(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
            ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: DemoAlertManager.instance.isDemoMode,
          builder: (context, isDemo, child) {
            return Row(
              children: [
                const Text(
                  'Demo Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Switch(
                  value: isDemo,
                  onChanged: (val) {
                    DemoAlertManager.instance.toggle();
                  },
                ),
              ],
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: DemoAlertManager.instance.unreadCount,
          builder: (context, count, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.bell),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}
