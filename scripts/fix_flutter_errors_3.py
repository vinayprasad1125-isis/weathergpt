import os
import glob

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# Fix the withOpacity syntax error in all dart files
for filename in glob.glob(os.path.join(base_dir, 'lib', '**', '*.dart'), recursive=True):
    with open(filename, 'r') as f:
        content = f.read()
    
    # We want to replace .withOpacity((0.05) to .withOpacity(0.05)
    import re
    content = re.sub(r'\.withOpacity\(\((.*?)\)', r'.withOpacity(\1', content)
    
    with open(filename, 'w') as f:
        f.write(content)

print("Flutter syntax fixed round 3.")
