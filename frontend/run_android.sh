#!/bin/bash

# Automatically port-forward backend before launching app on Android device.
# This maps the Android device's localhost:8000 → your Mac's localhost:8000.

DEVICE_ID="766d58add187"

echo "Setting up adb reverse for backend (port 8000)..."
adb -s "$DEVICE_ID" reverse tcp:8000 tcp:8000
if [ $? -ne 0 ]; then
  echo "❌ adb reverse failed. Is the device connected?"
  exit 1
fi
echo "✅ adb reverse set: device:8000 → mac:8000"

echo "Launching Flutter app on device $DEVICE_ID..."
flutter run -d "$DEVICE_ID" "$@"
