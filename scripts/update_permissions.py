import os
import re

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# 1. Update AndroidManifest.xml
manifest_file = os.path.join(base_dir, 'android/app/src/main/AndroidManifest.xml')
if os.path.exists(manifest_file):
    with open(manifest_file, 'r') as f:
        manifest_content = f.read()
    
    if 'android.permission.RECORD_AUDIO' not in manifest_content:
        permissions = '''
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
'''
        manifest_content = manifest_content.replace('<application', permissions + '\\n    <application')
        with open(manifest_file, 'w') as f:
            f.write(manifest_content)

# 2. Update Info.plist
plist_file = os.path.join(base_dir, 'ios/Runner/Info.plist')
if os.path.exists(plist_file):
    with open(plist_file, 'r') as f:
        plist_content = f.read()

    if 'NSSpeechRecognitionUsageDescription' not in plist_content:
        additions = '''
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>WeatherGPT requires speech recognition to understand your voice commands.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>WeatherGPT requires microphone access to record your voice commands.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>WeatherGPT requires location access to provide accurate local weather forecasts.</string>
'''
        plist_content = plist_content.replace('</dict>\\n</plist>', additions + '</dict>\\n</plist>')
        with open(plist_file, 'w') as f:
            f.write(plist_content)

print("Permissions updated.")
