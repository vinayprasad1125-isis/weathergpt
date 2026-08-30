import os
import glob

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# Fix the withValues syntax error in all dart files
for filename in glob.glob(os.path.join(base_dir, 'lib', '**', '*.dart'), recursive=True):
    with open(filename, 'r') as f:
        content = f.read()
    
    # We want to replace .withValues(alpha: <something>) back to .withOpacity(<something>)
    # Because my previous regex broke the code by matching too much.
    import re
    content = content.replace(".withValues(alpha: ", ".withOpacity(")
    
    with open(filename, 'w') as f:
        f.write(content)

# Fix main.dart literal \n
main_file = os.path.join(base_dir, 'lib/main.dart')
with open(main_file, 'r') as f:
    main_content = f.read()
main_content = main_content.replace("\\nimport 'screens/map_screen.dart';", "\nimport 'screens/map_screen.dart';")
with open(main_file, 'w') as f:
    f.write(main_content)

# Fix chat_screen.dart AppColors.primaryLight
chat_file = os.path.join(base_dir, 'lib/screens/chat_screen.dart')
with open(chat_file, 'r') as f:
    chat_content = f.read()
chat_content = chat_content.replace("AppColors.primaryLight", "AppColors.primary")
with open(chat_file, 'w') as f:
    f.write(chat_content)

# Fix map_screen.dart AppColors.textPrimary and # Chennai
map_file = os.path.join(base_dir, 'lib/screens/map_screen.dart')
with open(map_file, 'r') as f:
    map_content = f.read()
map_content = map_content.replace("AppColors.textPrimary", "AppColors.textSecondary")
map_content = map_content.replace("# Chennai", "// Chennai")
with open(map_file, 'w') as f:
    f.write(map_content)

print("Flutter syntax fixed.")
