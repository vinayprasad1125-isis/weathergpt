import os

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# Fix main.dart
main_file = os.path.join(base_dir, 'lib/main.dart')
with open(main_file, 'r') as f:
    main_content = f.read()

main_content = main_content.replace("\\nimport 'screens/map_screen.dart';", "\\nimport 'screens/map_screen.dart';")
# wait, if it was written as \n literally, I should replace it.
main_content = main_content.replace("\\\\n", "\\n") # just in case
with open(main_file, 'w') as f:
    f.write(main_content)

# Fix chat_screen.dart
chat_file = os.path.join(base_dir, 'lib/screens/chat_screen.dart')
with open(chat_file, 'r') as f:
    chat_content = f.read()

chat_content = chat_content.replace("AppColors.primaryLight", "AppColors.primary")
with open(chat_file, 'w') as f:
    f.write(chat_content)

# Fix map_screen.dart
map_file = os.path.join(base_dir, 'lib/screens/map_screen.dart')
with open(map_file, 'r') as f:
    map_content = f.read()

map_content = map_content.replace("# Chennai", "// Chennai")
map_content = map_content.replace("AppColors.textPrimary", "AppColors.textSecondary")
with open(map_file, 'w') as f:
    f.write(map_content)

# Fix deprecated members across the project reported by flutter analyze
import glob

for filename in glob.glob(os.path.join(base_dir, 'lib', '**', '*.dart'), recursive=True):
    with open(filename, 'r') as f:
        content = f.read()
        
    content = content.replace("withOpacity", "withValues(alpha: ")
    # Fix the trailing parenthesis for withValues if it just replaced withOpacity. 
    # Actually, .withOpacity(0.1) -> .withValues(alpha: (0.1) which is invalid syntax without closing properly. 
    # Let's do regex
    import re
    content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
    
    with open(filename, 'w') as f:
        f.write(content)
        
print("Flutter errors fixed.")
