import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'weather_card.dart';
import 'alert_card.dart';
import 'forecast_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    Widget content;
    switch (message.type) {
      case 'weather_card':
        content = WeatherCard(data: message.data as WeatherData);
        break;
      case 'alert_card':
        content = AlertCard(alert: message.data as WeatherAlert);
        break;
      case 'forecast_card':
        content = ForecastCard(data: ForecastData(hourly: [], daily: List<DailyForecast>.from(message.data)));
        break;
      default:
        content = Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            message.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isUser ? AppColors.surface : AppColors.text,
              height: 1.4,
            ),
          ),
        );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.md),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: content,
    );
  }
}
