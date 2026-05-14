#!/bin/bash
# Quick script to update proxy IP when network changes
# Generated: 20260514_080013

cd "/media/yajju/DATA/NIMS/Flutter-IMS"

# Get current IP
CURRENT_IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

if [ -z "$CURRENT_IP" ]; then
    CURRENT_IP=$(hostname -I | awk '{print $1}')
fi

echo "Current IP: $CURRENT_IP"
echo "Updating main.dart..."

# Update the proxy IP in main.dart
sed -i "s/const _kProxyHost = '[0-9.]*';/const _kProxyHost = '$CURRENT_IP';/" lib/main.dart

echo "Proxy updated to: $CURRENT_IP"
echo ""
echo "Rebuild with: flutter build apk --release"
echo "Reinstall with: adb install -r build/app/outputs/apk/release/app-release.apk"
