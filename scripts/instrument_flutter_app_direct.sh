#!/bin/bash
# =============================================================================
# instrument_flutter_app_direct.sh
# Direct Flutter APK instrumentation with dynamic proxy configuration
# NO REFLUTTER REQUIRED - Uses source code modification
# =============================================================================
# This script:
#   1. Auto-detects your laptop's current IP
#   2. Patches main.dart with the correct proxy IP
#   3. Creates network_security_config.xml if missing
#   4. Builds and installs the instrumented APK
#   5. Handles IP changes gracefully
#
# Usage:
#   ./scripts/instrument_flutter_app_direct.sh [OPTIONS]
#
# Options:
#   --skip-build        Skip Flutter build (use existing APK)
#   --skip-install      Build but do not install on device
#   --proxy-port PORT   Burp Suite proxy port (default: 8080)
#   --proxy-ip IP       Manual proxy IP (default: auto-detected)
#   --force-network     Force recreate network_security_config.xml
#   --help              Show this help message
# =============================================================================

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m';    GREEN='\033[0;32m';   YELLOW='\033[1;33m'
CYAN='\033[0;36m';   BOLD='\033[1m';       NC='\033[0m'

ok()      { echo -e "${GREEN}  ✓  $*${NC}"; }
warn()    { echo -e "${YELLOW}  ⚠  $*${NC}"; }
err()     { echo -e "${RED}  ✗  $*${NC}" >&2; }
info()    { echo -e "${CYAN}  →  $*${NC}"; }
fatal()   { err "$*"; exit 1; }

section() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║  $*${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

print_banner() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo "  ██████  ███████ ███████ ██      ██    ██ ████████ ████████ ███████ ██████  "
  echo "  ██   ██ ██      ██      ██      ██    ██    ██       ██    ██      ██   ██ "
  echo "  ██████  █████   █████   ██      ██    ██    ██       ██    █████   ██████  "
  echo "  ██   ██ ██      ██      ██      ██    ██    ██       ██    ██      ██   ██ "
  echo "  ██   ██ ███████ ██      ███████  ██████     ██       ██    ███████ ██   ██ "
  echo ""
  echo -e "${NC}${CYAN}  Direct Flutter APK Instrumentation — Dynamic Proxy Mode${NC}"
}

# ─── Defaults ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_NAME="com.example.imsapp"
APK_NAME="app-release.apk"
APK_PATH="build/app/outputs/apk/release/$APK_NAME"
PROXY_PORT=8080
PROXY_IP=""
SKIP_BUILD=false
SKIP_INSTALL=false
FORCE_NETWORK=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ─── Argument Parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)        SKIP_BUILD=true ;;
    --skip-install)      SKIP_INSTALL=true ;;
    --force-network)     FORCE_NETWORK=true ;;
    --proxy-port)        PROXY_PORT="$2"; shift ;;
    --proxy-ip)          PROXY_IP="$2"; shift ;;
    --help)
      sed -n '/^# Usage:/,/^# =/p' "$0" | grep -v "^# =" | sed 's/^# //'
      exit 0
      ;;
    *) fatal "Unknown option: $1. Run with --help for usage." ;;
  esac
  shift
done

# ─── Display Banner ───────────────────────────────────────────────────────────
print_banner
echo -e "${CYAN}  Project: ${BOLD}$PROJECT_DIR${NC}"
echo -e "${CYAN}  Package: ${BOLD}$PACKAGE_NAME${NC}"
echo -e "${CYAN}  Timestamp: ${BOLD}$TIMESTAMP${NC}"
echo ""

# ─── Step 0: Detect Proxy IP ─────────────────────────────────────────────────
section "STEP 0 — Network Detection"

if [ -n "$PROXY_IP" ]; then
  HOST_IP="$PROXY_IP"
  info "Using manual proxy IP: $HOST_IP"
else
  # Try multiple methods to get the correct IP
  HOST_IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || echo "")
  
  if [ -z "$HOST_IP" ]; then
    HOST_IP=$(hostname -I | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || echo "")
  fi
  
  if [ -z "$HOST_IP" ]; then
    # Try USB tethering interface
    HOST_IP=$(ip addr show usb0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
  fi
  
  if [ -z "$HOST_IP" ]; then
    fatal "Could not auto-detect IP address. Please specify with --proxy-ip"
  fi
  
  ok "Auto-detected host IP: $HOST_IP"
fi

echo ""
echo -e "  ${BOLD}Proxy Configuration:${NC}"
echo -e "    ${GREEN}►${NC} Host IP:    ${BOLD}$HOST_IP${NC}"
echo -e "    ${GREEN}►${NC} Proxy Port: ${BOLD}$PROXY_PORT${NC}"
echo ""

# ─── Step 1: Verify Burp Suite Configuration ─────────────────────────────────
section "STEP 1 — Burp Suite Verification"

echo -e "  ${YELLOW}${BOLD}IMPORTANT:${NC} Ensure Burp Suite is configured correctly:"
echo ""
echo "    1. Proxy → Options → Proxy Listeners"
echo "    2. Select listener on port $PROXY_PORT → Edit"
echo "    3. Bind to address: 'All interfaces'"
echo "    4. Request Handling → ✅ 'Support invisible proxying'"
echo ""

read -p "  Press Enter after confirming Burp configuration... "

# Test Burp connectivity
if curl -s -o /dev/null -w "%{http_code}" "http://$HOST_IP:$PROXY_PORT" 2>/dev/null | grep -q "200"; then
  ok "Burp Suite is accessible at http://$HOST_IP:$PROXY_PORT"
else
  warn "Cannot reach Burp Suite - check configuration"
  echo ""
  read -p "  Continue anyway? (y/n): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# ─── Step 2: Create/Update Network Security Config ───────────────────────────
section "STEP 2 — Network Security Configuration"

NETWORK_SECURITY_DIR="$PROJECT_DIR/android/app/src/main/res/xml"
NETWORK_SECURITY_FILE="$NETWORK_SECURITY_DIR/network_security_config.xml"

if [ ! -f "$NETWORK_SECURITY_FILE" ] || $FORCE_NETWORK; then
  info "Creating network_security_config.xml..."
  mkdir -p "$NETWORK_SECURITY_DIR"
  
  cat > "$NETWORK_SECURITY_FILE" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
EOF
  ok "Created: $NETWORK_SECURITY_FILE"
  
  # Update AndroidManifest.xml to reference the config
  MANIFEST_FILE="$PROJECT_DIR/android/app/src/main/AndroidManifest.xml"
  if [ -f "$MANIFEST_FILE" ]; then
    if ! grep -q "networkSecurityConfig" "$MANIFEST_FILE"; then
      info "Updating AndroidManifest.xml to reference network security config..."
      # Backup original
      cp "$MANIFEST_FILE" "$MANIFEST_FILE.backup"
      
      # Add networkSecurityConfig to application tag
      sed -i 's/<application /<application android:networkSecurityConfig="@xml\/network_security_config" /' "$MANIFEST_FILE"
      ok "AndroidManifest.xml updated (backup saved as .backup)"
    else
      ok "AndroidManifest.xml already has networkSecurityConfig reference"
    fi
  else
    warn "AndroidManifest.xml not found - please add manually:"
    echo '  android:networkSecurityConfig="@xml/network_security_config"'
  fi
else
  ok "Network security config already exists: $NETWORK_SECURITY_FILE"
fi

# ─── Step 3: Patch main.dart with Dynamic Proxy ──────────────────────────────
section "STEP 3 — Patching main.dart with Proxy Configuration"

MAIN_FILE="$PROJECT_DIR/lib/main.dart"
if [ ! -f "$MAIN_FILE" ]; then
  # Try alternative main file
  MAIN_FILE="$PROJECT_DIR/lib/main_prod.dart"
  [ ! -f "$MAIN_FILE" ] && fatal "Could not find main.dart or main_prod.dart"
fi

info "Patching: $MAIN_FILE"

# Create a backup with timestamp
BACKUP_FILE="${MAIN_FILE}.backup.${TIMESTAMP}"
cp "$MAIN_FILE" "$BACKUP_FILE"
ok "Backup created: $BACKUP_FILE"

# Check if proxy code already exists
if grep -q "_BurpProxyOverrides" "$MAIN_FILE"; then
  info "Found existing proxy configuration - updating IP address..."
  
  # Update the proxy IP in existing code
  sed -i "s/const _kProxyHost = '[0-9.]*';/const _kProxyHost = '$HOST_IP';/" "$MAIN_FILE"
  sed -i "s/const _kProxyPort = [0-9]*;/const _kProxyPort = $PROXY_PORT;/" "$MAIN_FILE"
  ok "Updated proxy IP to: $HOST_IP"
else
  info "Adding proxy configuration to main.dart..."
  
  # Check if HttpOverrides import exists
  if ! grep -q "import 'dart:io';" "$MAIN_FILE"; then
    # Add import after the last import
    sed -i "/^import /a import 'dart:io';" "$MAIN_FILE"
  fi
  
  # Create a temporary file with the proxy class
  TMP_FILE=$(mktemp)
  
  cat > "$TMP_FILE" << EOF

// ===== PROXY CONFIGURATION FOR BURP SUITE (Auto-injected) =====
// Generated: $TIMESTAMP
// Proxy IP: $HOST_IP
// Proxy Port: $PROXY_PORT

const _kProxyHost = '$HOST_IP';
const _kProxyPort = $PROXY_PORT;

class _BurpProxyOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY \$_kProxyHost:\$_kProxyPort';
    // Accept Burp's certificate for interception
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}
// ===== END PROXY CONFIGURATION =====

EOF
  
  # Insert proxy code after imports but before main()
  # Find the position of 'void main()' or 'Future<void> main()'
  LINE_NUM=$(grep -n "main()" "$MAIN_FILE" | head -1 | cut -d: -f1)
  
  if [ -n "$LINE_NUM" ]; then
    # Insert at line before main
    sed -i "${LINE_NUM}i\\" "$MAIN_FILE"
    sed -i "${LINE_NUM}r $TMP_FILE" "$MAIN_FILE"
    
    # Find the main function and add HttpOverrides.global assignment
    # Look for WidgetsFlutterBinding.ensureInitialized()
    if grep -q "WidgetsFlutterBinding.ensureInitialized()" "$MAIN_FILE"; then
      # Add after ensureInitialized
      sed -i "/WidgetsFlutterBinding.ensureInitialized()/a \  HttpOverrides.global = _BurpProxyOverrides();" "$MAIN_FILE"
    else
      # Add at the beginning of main
      sed -i "/main()/a {\n  HttpOverrides.global = _BurpProxyOverrides();" "$MAIN_FILE"
    fi
    
    ok "Proxy configuration injected successfully"
  else
    warn "Could not find main() function - please add manually:"
    echo "  HttpOverrides.global = _BurpProxyOverrides();"
  fi
  
  rm -f "$TMP_FILE"
fi

# Display the current configuration
echo ""
info "Current proxy configuration:"
grep -A2 "_kProxyHost" "$MAIN_FILE" || echo "  (could not verify)"

# ─── Step 4: Check Android Device ────────────────────────────────────────────
section "STEP 4 — Checking Android Device"

info "Connected devices:"
adb devices

DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
  if $SKIP_INSTALL; then
    warn "No device found — skipping install (--skip-install is set)"
  else
    fatal "No Android device connected. Enable USB debugging and retry."
  fi
else
  ok "$DEVICE_COUNT device(s) connected"
  
  # Get device model
  DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
  info "Device: $DEVICE_MODEL"
fi

# ─── Step 5: Build Flutter APK ───────────────────────────────────────────────
section "STEP 5 — Building Flutter APK"

cd "$PROJECT_DIR"

if $SKIP_BUILD; then
  warn "--skip-build set: skipping Flutter build"
  if [ ! -f "$APK_PATH" ]; then
    fatal "APK not found at $APK_PATH"
  fi
else
  info "Running flutter clean..."
  flutter clean
  
  info "Running flutter pub get..."
  flutter pub get
  
  info "Building release APK..."
  info "  Command: flutter build apk --release"
  
  if flutter build apk --release; then
    ok "Build completed successfully"
  else
    fatal "Flutter build failed"
  fi
  
  if [ ! -f "$APK_PATH" ]; then
    fatal "APK not found at: $APK_PATH"
  fi
fi

APK_SIZE=$(du -sh "$APK_PATH" | awk '{print $1}')
ok "APK: $APK_PATH ($APK_SIZE)"

# ─── Step 6: Install on Device ───────────────────────────────────────────────
if $SKIP_INSTALL; then
  warn "--skip-install set: skipping device install"
else
  section "STEP 6 — Installing on Device"
  
  if [ "$DEVICE_COUNT" -eq 0 ]; then
    fatal "No device connected for installation"
  fi
  
  info "Uninstalling existing version..."
  adb uninstall "$PACKAGE_NAME" 2>/dev/null && ok "Uninstalled" || warn "Not installed"
  
  info "Installing instrumented APK..."
  if adb install "$APK_PATH"; then
    ok "APK installed successfully"
  else
    fatal "Installation failed"
  fi
fi

# ─── Step 7: Certificate Reminder ────────────────────────────────────────────
section "STEP 7 — Certificate Installation"

echo "  Ensure Burp certificate is installed on your device:"
echo ""
echo "    1. On device browser, go to: http://$HOST_IP:$PROXY_PORT"
echo "    2. Click 'CA Certificate' in top-right"
echo "    3. Download and install the certificate"
echo "    4. Settings → Security → Encryption & credentials"
echo "    5. Install a certificate → CA certificate"
echo "    6. Select the downloaded cacert.der"
echo "    7. Name it 'BurpCA'"
echo ""

read -p "  Certificate installed? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  ok "Certificate confirmed"
else
  warn "Please install certificate for HTTPS interception"
fi

# ─── Step 8: Launch App ──────────────────────────────────────────────────────
if ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  section "STEP 8 — Launch Application"
  
  read -p "  Launch the app now? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Launch the app
    adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 2>/dev/null
    ok "App launched"
    
    echo ""
    echo -e "  ${BOLD}Now check Burp Suite → HTTP History for traffic!${NC}"
    echo ""
    echo "  Expected to see:"
    echo "    • POST /auth/v1/token - Authentication requests"
    echo "    • GET /rest/v1/* - API calls"
    echo "    • POST /functions/v1/chat-ai - AI chat calls"
    echo ""
    
    read -p "  Press Enter when done testing... "
  fi
fi

# ─── Step 9: Save IP Configuration ───────────────────────────────────────────
section "STEP 9 — Save Configuration"

CONFIG_FILE="$PROJECT_DIR/.proxy_config"
cat > "$CONFIG_FILE" << EOF
# Proxy configuration saved on $TIMESTAMP
PROXY_IP=$HOST_IP
PROXY_PORT=$PROXY_PORT
PACKAGE_NAME=$PACKAGE_NAME
EOF
ok "Configuration saved to: $CONFIG_FILE"

# Create a quick repatch script
REPATCH_SCRIPT="$PROJECT_DIR/scripts/update_proxy.sh"
mkdir -p "$PROJECT_DIR/scripts"

cat > "$REPATCH_SCRIPT" << EOF
#!/bin/bash
# Quick script to update proxy IP when network changes
# Generated: $TIMESTAMP

cd "$PROJECT_DIR"

# Get current IP
CURRENT_IP=\$(ip route get 1 2>/dev/null | awk '{print \$NF;exit}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

if [ -z "\$CURRENT_IP" ]; then
    CURRENT_IP=\$(hostname -I | awk '{print \$1}')
fi

echo "Current IP: \$CURRENT_IP"
echo "Updating main.dart..."

# Update the proxy IP in main.dart
sed -i "s/const _kProxyHost = '[0-9.]*';/const _kProxyHost = '\$CURRENT_IP';/" lib/main.dart

echo "Proxy updated to: \$CURRENT_IP"
echo ""
echo "Rebuild with: flutter build apk --release"
echo "Reinstall with: adb install -r build/app/outputs/apk/release/app-release.apk"
EOF

chmod +x "$REPATCH_SCRIPT"
ok "Created quick update script: $REPATCH_SCRIPT"

# ─── Completion ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║              INSTRUMENTATION COMPLETE ✓                     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Summary:${NC}"
echo -e "    ${GREEN}►${NC} Proxy IP:     ${BOLD}$HOST_IP${NC}"
echo -e "    ${GREEN}►${NC} Proxy Port:   ${BOLD}$PROXY_PORT${NC}"
echo -e "    ${GREEN}►${NC} APK Location: ${BOLD}$APK_PATH${NC}"
echo -e "    ${GREEN}►${NC} Backup:       ${BOLD}$BACKUP_FILE${NC}"
echo ""
echo -e "  ${BOLD}When your IP changes (different WiFi):${NC}"
echo -e "    ${YELLOW}1.${NC} Run: ${BOLD}./scripts/update_proxy.sh${NC}"
echo -e "    ${YELLOW}2.${NC} Rebuild: ${BOLD}flutter build apk --release${NC}"
echo -e "    ${YELLOW}3.${NC} Reinstall: ${BOLD}adb install -r build/app/outputs/apk/release/app-release.apk${NC}"
echo ""
echo -e "  ${BOLD}To restore original main.dart:${NC}"
echo -e "    ${BOLD}cp $BACKUP_FILE $MAIN_FILE${NC}"
echo ""
