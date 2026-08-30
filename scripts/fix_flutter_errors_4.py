import os

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# 1. home_screen.dart
file1 = os.path.join(base_dir, 'lib/screens/home_screen.dart')
with open(file1, 'r') as f:
    content1 = f.read()
content1 = content1.replace(
    'BoxShadow(color: Colors.black.withOpacity(0.2, blurRadius: 4, offset: const Offset(0, 2)),',
    'BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),'
)
with open(file1, 'w') as f:
    f.write(content1)

# 2. weather_card.dart
file2 = os.path.join(base_dir, 'lib/widgets/weather_card.dart')
with open(file2, 'r') as f:
    content2 = f.read()
content2 = content2.replace(
    'style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.surface.withOpacity(0.9),',
    'style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.surface.withOpacity(0.9)),'
)
content2 = content2.replace(
    'style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface.withOpacity(0.8),',
    'style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface.withOpacity(0.8)),'
)
content2 = content2.replace(
    'border: Border(top: BorderSide(color: AppColors.surface.withOpacity(0.2)),',
    'border: Border(top: BorderSide(color: AppColors.surface.withOpacity(0.2))),'
)
with open(file2, 'w') as f:
    f.write(content2)
    
# 3. alert_card.dart
file3 = os.path.join(base_dir, 'lib/widgets/alert_card.dart')
with open(file3, 'r') as f:
    content3 = f.read()
content3 = content3.replace(
    'color: Colors.black.withOpacity(0.05,',
    'color: Colors.black.withOpacity(0.05),'
)
with open(file3, 'w') as f:
    f.write(content3)

print("Final manual syntax fix applied.")
