#!/bin/bash
# =============================================================================
# instrument_flutter_app.sh - Flutter APK Instrumentation with ReFlutter
# =============================================================================
# Automates ReFlutter-based APK instrumentation for Flutter applications.
# Supports both physical devices and emulators with proper proxy configuration.
#
# Project:  Flutter IMS (Inventory Management System)
# Package:  com.example.imsapp
# Entry:    auto-detects lib/main.dart or lib/main_prod.dart
#
# Usage:
#   ./scripts/instrument_flutter_app.sh [OPTIONS]
#
# Options:
#   --skip-build        Skip Flutter build (use existing APK)
#   --skip-install      Build & patch but do not install on device
#   --skip-cert         Skip certificate installation prompt
#   --skip-validation   Skip proxy validation tests
#   --no-frida          Skip Frida SSL pinning bypass prompt
#   --proxy-port PORT   Burp Suite proxy port (default: 8080)
#   --proxy-ip IP       Manual proxy IP (default: auto-detected)
#   --package NAME      Override package name (default: com.example.imsapp)
#   --entry-point FILE  Override main entry point (auto-detected if not set)
#   --output-dir DIR    Directory for patched APKs (default: ~/Documents/reflutter-output)
#   --usb-tethering     Force USB tethering mode (use usb0 interface IP)
#   --no-clean-cache    Don't wipe pub-cache before build
#   --test-proxy        Test proxy with httpbin.org before finishing
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
  echo -e "${NC}${CYAN}  Flutter APK Instrumentation — Powered by ReFlutter${NC}"
}

# ─── Defaults ─────────────────────────────────────────────────────────────────
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_NAME="com.example.imsapp"
ENTRY_POINT=""  # Auto-detect
APK_NAME="app-release.apk"
APK_RELATIVE_PATH="build/app/outputs/apk/release/$APK_NAME"
SIGNER_JAR="$HOME/tools/uber-apk-signer-1.3.0.jar"
OUTPUT_DIR="$HOME/Documents/reflutter-output"
PROXY_PORT=8080
PROXY_IP=""
USB_TETHERING=false
SKIP_BUILD=false
SKIP_INSTALL=false
SKIP_CERT=false
SKIP_VALIDATION=false
NO_FRIDA=false
CLEAN_CACHE=true
TEST_PROXY=false
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ─── Argument Parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)        SKIP_BUILD=true ;;
    --skip-install)      SKIP_INSTALL=true ;;
    --skip-cert)         SKIP_CERT=true ;;
    --skip-validation)   SKIP_VALIDATION=true ;;
    --no-frida)          NO_FRIDA=true ;;
    --test-proxy)        TEST_PROXY=true ;;
    --usb-tethering)     USB_TETHERING=true ;;
    --no-clean-cache)    CLEAN_CACHE=false ;;
    --proxy-port)        PROXY_PORT="$2"; shift ;;
    --proxy-ip)          PROXY_IP="$2"; shift ;;
    --package)           PACKAGE_NAME="$2"; shift ;;
    --entry-point)       ENTRY_POINT="$2"; shift ;;
    --output-dir)        OUTPUT_DIR="$2"; shift ;;
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

# ─── Step 0: Detect/Configure Network ────────────────────────────────────────
section "STEP 0 — Network Configuration"

# Detect proxy IP
if [ -n "$PROXY_IP" ]; then
  HOST_IP="$PROXY_IP"
  info "Using manual proxy IP: $HOST_IP"
elif $USB_TETHERING; then
  HOST_IP=$(ip addr show usb0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
  if [ -z "$HOST_IP" ]; then
    warn "USB tethering requested but usb0 interface not found"
    HOST_IP=$(hostname -I | awk '{print $1}')
    info "Falling back to Wi-Fi IP: $HOST_IP"
  else
    ok "Using USB tethering IP: $HOST_IP"
  fi
else
  HOST_IP=$(hostname -I | awk '{print $1}')
  ok "Auto-detected host IP: $HOST_IP"
fi

echo ""
echo -e "  ${BOLD}Proxy Configuration:${NC}"
echo -e "    Host IP:    ${GREEN}$HOST_IP${NC}"
echo -e "    Proxy Port: ${GREEN}$PROXY_PORT${NC}"
echo ""

# ─── Step 1: Critical Burp Suite Configuration ───────────────────────────────
section "STEP 1 — Burp Suite Configuration (CRITICAL)"

echo -e "${RED}${BOLD}⚠️  IMPORTANT: Flutter apps REQUIRE 'Invisible Proxying' in Burp Suite!${NC}"
echo ""
echo "  Please configure Burp Suite NOW:"
echo ""
echo "    1. Open Burp Suite"
echo "    2. Go to Proxy → Options → Proxy Listeners"
echo "    3. Select the listener on port $PROXY_PORT"
echo "    4. Click 'Edit'"
echo "    5. Bind to address: 'All interfaces'"
echo -e "    6. ${BOLD}${YELLOW}Request Handling tab → CHECK 'Support invisible proxying'${NC}"
echo "    7. Click OK"
echo ""
echo -e "  ${YELLOW}Without step 6, NO Flutter traffic will reach Burp Suite!${NC}"
echo ""
read -p "  Press Enter after completing these steps... "

# Test Burp connectivity
if curl -s -o /dev/null -w "%{http_code}" "http://$HOST_IP:$PROXY_PORT" 2>/dev/null | grep -q "200"; then
  ok "Burp Suite is accessible at http://$HOST_IP:$PROXY_PORT"
else
  warn "Cannot reach Burp Suite at http://$HOST_IP:$PROXY_PORT"
  echo ""
  echo "  Troubleshooting:"
  echo "    1. Is Burp Suite running?"
  echo "    2. Is the listener bound to 'All interfaces'?"
  echo "    3. Is invisible proxying enabled?"
  echo "    4. Is your firewall blocking port $PROXY_PORT?"
  echo ""
  read -p "  Continue anyway? (y/n): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# ─── Step 2: Verify Dependencies ─────────────────────────────────────────────
section "STEP 2 — Verifying Dependencies"

check_cmd() {
  local cmd="$1" label="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    ok "$label found: $(command -v "$cmd")"
    return 0
  else
    return 1
  fi
}

# Check Flutter
if ! check_cmd flutter; then
  fatal "Flutter not found. Please install Flutter SDK."
fi

# Check ADB
if ! check_cmd adb; then
  fatal "ADB not found. Install Android platform-tools."
fi

# Check Java
if ! check_cmd java; then
  fatal "Java not found. Install openjdk-11-jre."
fi

# Check ReFlutter
if check_cmd reflutter; then
  REFLUTTER_CMD="reflutter"
elif python3 -m reflutter --help &>/dev/null 2>&1; then
  ok "reflutter found (via python3 -m reflutter)"
  REFLUTTER_CMD="python3 -m reflutter"
else
  fatal "reflutter not found. Run: python3 -m pip install reflutter"
fi

# Check Uber APK Signer
if [ ! -f "$SIGNER_JAR" ]; then
  warn "Uber APK Signer not found at $SIGNER_JAR"
  info "Downloading Uber APK Signer..."
  mkdir -p "$(dirname "$SIGNER_JAR")"
  wget -q -O "$SIGNER_JAR" "https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar"
  if [ -f "$SIGNER_JAR" ]; then
    ok "Uber APK Signer downloaded successfully"
  else
    fatal "Failed to download Uber APK Signer"
  fi
else
  ok "Uber APK Signer found"
fi

# ─── Step 3: Check Android Device ────────────────────────────────────────────
section "STEP 3 — Checking Android Device"

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

# Test network connectivity to phone
if ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  info "Testing network connectivity..."
  if adb shell ping -c 1 -W 2 "$HOST_IP" &>/dev/null; then
    ok "Device can reach laptop at $HOST_IP"
  else
    warn "Device cannot ping $HOST_IP (may indicate network isolation)"
    echo ""
    echo "  If proxy doesn't work, try:"
    echo "    1. Use USB tethering instead of Wi-Fi"
    echo "    2. Disable 'AP Isolation' in your router"
    echo "    3. Run with --usb-tethering flag"
    echo ""
  fi
fi

# ─── Step 4: Auto-detect Entry Point ─────────────────────────────────────────
section "STEP 4 — Detecting Flutter Entry Point"

if [ -z "$ENTRY_POINT" ]; then
  if [ -f "$PROJECT_DIR/lib/main_prod.dart" ]; then
    ENTRY_POINT="lib/main_prod.dart"
    ok "Detected production entry point: $ENTRY_POINT"
  elif [ -f "$PROJECT_DIR/lib/main.dart" ]; then
    ENTRY_POINT="lib/main.dart"
    ok "Detected default entry point: $ENTRY_POINT"
  else
    fatal "Could not find main entry point. Specify with --entry-point"
  fi
else
  ok "Using specified entry point: $ENTRY_POINT"
fi

# ─── Step 5: Build Flutter Release APK ───────────────────────────────────────
section "STEP 5 — Building Flutter Release APK"

cd "$PROJECT_DIR"

if $SKIP_BUILD; then
  warn "--skip-build set: skipping Flutter build."
  APK_SOURCE="$PROJECT_DIR/$APK_RELATIVE_PATH"
  if [ ! -f "$APK_SOURCE" ]; then
    fatal "APK not found at $APK_SOURCE. Remove --skip-build to build first."
  fi
  ok "Using existing APK: $APK_SOURCE"
else
  if $CLEAN_CACHE; then
    info "Cleaning pub cache..."
    rm -rf ~/.pub-cache
    ok "Pub cache cleared"
  fi

  info "Running: flutter pub get"
  flutter pub get || fatal "flutter pub get failed"

  if git rev-parse --git-dir &>/dev/null; then
    info "Running: git pull"
    git pull || warn "git pull failed — continuing..."
  fi

  if ! $SKIP_INSTALL; then
    info "Uninstalling existing package from device..."
    adb uninstall "$PACKAGE_NAME" 2>/dev/null && ok "Uninstalled $PACKAGE_NAME" || warn "$PACKAGE_NAME not installed"
  fi

  info "Building release APK..."
  info "  Entry point: $ENTRY_POINT"
  info "  Command: flutter build apk --release -t $ENTRY_POINT"
  
  flutter build apk \
    --release \
    -t "$ENTRY_POINT" || fatal "Flutter build failed"

  APK_SOURCE="$PROJECT_DIR/$APK_RELATIVE_PATH"
  if [ ! -f "$APK_SOURCE" ]; then
    fatal "Build completed but APK not found at: $APK_SOURCE"
  fi
  ok "APK built successfully"
fi

APK_SIZE=$(du -sh "$APK_SOURCE" | awk '{print $1}')
info "APK size: $APK_SIZE"

# ─── Step 6: Stage APK ───────────────────────────────────────────────────────
section "STEP 6 — Staging APK"

mkdir -p "$OUTPUT_DIR"

STAGED_APK="$OUTPUT_DIR/$APK_NAME"
cp "$APK_SOURCE" "$STAGED_APK"
ok "Staged APK → $STAGED_APK"

# Clean previous artifacts
rm -f "$OUTPUT_DIR/release.RE.apk" "$OUTPUT_DIR/release.RE-aligned-debugSigned.apk"

# ─── Step 7: Patch with ReFlutter ────────────────────────────────────────────
section "STEP 7 — Patching with ReFlutter"

cd "$OUTPUT_DIR"

echo -e "  ${BOLD}ReFlutter will now prompt for your Burp Suite proxy IP.${NC}"
echo -e "  ${GREEN}Enter: $HOST_IP${NC}"
echo ""
read -p "  Press Enter to continue... "

$REFLUTTER_CMD "$APK_NAME"

PATCHED_APK="$OUTPUT_DIR/release.RE.apk"
if [ ! -f "$PATCHED_APK" ]; then
  fatal "ReFlutter did not produce release.RE.apk"
fi
ok "Patched APK produced: $PATCHED_APK"

# ─── Step 8: Re-sign with Uber APK Signer ────────────────────────────────────
section "STEP 8 — Re-signing APK"

info "Signing release.RE.apk..."
java -jar "$SIGNER_JAR" --apk "$PATCHED_APK"

SIGNED_APK="$OUTPUT_DIR/release.RE-aligned-debugSigned.apk"
if [ ! -f "$SIGNED_APK" ]; then
  fatal "Signing failed — signed APK not found"
fi
ok "Signed APK: $SIGNED_APK"

SIGNED_SIZE=$(du -sh "$SIGNED_APK" | awk '{print $1}')
info "Signed APK size: $SIGNED_SIZE"

# ─── Step 9: Install Certificate (if not skipped) ────────────────────────────
if ! $SKIP_CERT && ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  section "STEP 9 — Install Burp Certificate"
  
  echo "  To intercept HTTPS traffic, install the Burp certificate:"
  echo ""
  echo "    1. On your device, open Chrome and go to:"
  echo -e "       ${BOLD}http://$HOST_IP:$PROXY_PORT${NC}"
  echo ""
  echo "    2. Click 'CA Certificate' in the top-right corner"
  echo ""
  echo "    3. Download and save the certificate"
  echo ""
  echo "    4. Install the certificate:"
  echo "       Settings → Security → Encryption & credentials"
  echo "       → Install a certificate → CA certificate"
  echo "       → Select the downloaded cacert.der"
  echo "       → Name it 'BurpCA'"
  echo ""
  read -p "  Press Enter after certificate is installed... "
  
  # Verify certificate installation
  if adb shell ls /data/misc/user/0/cacerts-added/ 2>/dev/null | grep -q .; then
    ok "Certificate appears to be installed"
  else
    warn "Could not verify certificate installation"
  fi
fi

# ─── Step 10: Install APK on Device ──────────────────────────────────────────
if $SKIP_INSTALL; then
  warn "--skip-install set: skipping device install"
else
  section "STEP 10 — Installing on Device"
  
  if [ "$DEVICE_COUNT" -eq 0 ]; then
    fatal "No device connected for installation"
  fi
  
  info "Uninstalling existing $PACKAGE_NAME..."
  adb uninstall "$PACKAGE_NAME" 2>/dev/null && ok "Uninstalled" || warn "Not installed"
  
  info "Installing instrumented APK..."
  if adb install "$SIGNED_APK"; then
    ok "APK installed successfully"
  else
    fatal "Installation failed. Try: adb uninstall $PACKAGE_NAME"
  fi
fi

# ─── Step 11: Proxy Validation (if not skipped) ──────────────────────────────
if ! $SKIP_VALIDATION && ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  section "STEP 11 — Proxy Validation"
  
  echo "  Let's verify the proxy is working correctly:"
  echo ""
  echo "    1. Ensure your device Wi-Fi proxy is set to:"
  echo -e "       ${BOLD}Host: $HOST_IP${NC}"
  echo -e "       ${BOLD}Port: $PROXY_PORT${NC}"
  echo ""
  echo "    2. Open Chrome on your device and visit:"
  echo -e "       ${BOLD}http://$HOST_IP:$PROXY_PORT${NC}"
  echo ""
  read -p "  Does the Burp Suite welcome page load? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ok "Proxy is working!"
    
    if $TEST_PROXY; then
      info "Testing with httpbin.org..."
      adb shell am start -a android.intent.action.VIEW -d "http://httpbin.org/get" 2>/dev/null
      sleep 3
      echo ""
      echo -e "  ${YELLOW}Check Burp Suite → HTTP History for the request to httpbin.org${NC}"
      read -p "  Was the request captured? (y/n): " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        ok "HTTP interception working!"
      else
        warn "HTTP interception failed — check Burp configuration"
      fi
    fi
  else
    warn "Proxy validation failed"
    echo ""
    echo "  Troubleshooting:"
    echo "    1. Is invisible proxying ENABLED in Burp?"
    echo "    2. Is Burp bound to 'All interfaces'?"
    echo "    3. Is your phone's proxy set correctly?"
    echo "    4. Try: adb shell ping $HOST_IP"
    echo ""
  fi
fi

# ─── Step 12: SSL Pinning Bypass (Optional) ──────────────────────────────────
if ! $NO_FRIDA && ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  section "STEP 12 — SSL Pinning Bypass (Optional)"
  
  echo "  If your app has SSL pinning, traffic won't appear in Burp."
  echo "  Frida can bypass SSL pinning at runtime."
  echo ""
  read -p "  Set up Frida SSL unpinning? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if frida is installed
    if ! command -v frida &>/dev/null; then
      info "Installing frida-tools..."
      pip3 install frida-tools
    fi
    
    FRIDA_SCRIPT="/tmp/frida-universal-unpinning.js"
    if [ ! -f "$FRIDA_SCRIPT" ]; then
      info "Downloading Frida SSL unpinning script..."
      wget -q -O "$FRIDA_SCRIPT" \
        "https://raw.githubusercontent.com/httptoolkit/frida-interception-android-unpinning/main/frida-scripts/universal-android-unpinning.js"
      ok "Script downloaded"
    fi
    
    echo ""
    echo -e "  ${BOLD}Run this command in a NEW terminal:${NC}"
    echo ""
    echo -e "    ${CYAN}frida -U -f $PACKAGE_NAME -l $FRIDA_SCRIPT --no-pause${NC}"
    echo ""
    echo "  After running, launch your app and check Burp Suite for traffic."
    echo ""
    read -p "  Press Enter when ready... "
  fi
fi

# ─── Step 13: Launch Application ─────────────────────────────────────────────
if ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  section "STEP 13 — Launch Application"
  
  read -p "  Launch the app now? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Try to find and launch main activity
    MAIN_ACTIVITY=$(adb shell cmd package resolve-activity --brief "$PACKAGE_NAME" 2>/dev/null | tail -n 1 | tr -d '\r')
    
    if [ -n "$MAIN_ACTIVITY" ] && [ "$MAIN_ACTIVITY" != "$PACKAGE_NAME/" ]; then
      adb shell am start -n "$MAIN_ACTIVITY" 2>/dev/null
      ok "App launched"
    else
      warn "Could not determine launcher activity"
      info "Launch the app manually on your device"
    fi
    
    echo ""
    echo -e "  ${BOLD}Now check Burp Suite → HTTP History for app traffic!${NC}"
    echo ""
    read -p "  Press Enter when done testing... "
  fi
fi

# ─── Step 14: Monitor Logs (Optional) ────────────────────────────────────────
if ! $SKIP_INSTALL && [ "$DEVICE_COUNT" -gt 0 ]; then
  section "STEP 14 — Monitor Logs (Optional)"
  
  read -p "  Monitor app logs for errors? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Showing logs for $PACKAGE_NAME (Ctrl+C to stop)..."
    echo ""
    adb logcat | grep -E "$PACKAGE_NAME|Flutter|Dart|Error|Exception|http|socket" --color=always
  fi
fi

# ─── Completion ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║              INSTRUMENTATION COMPLETE ✓                     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Output files:${NC}"
echo -e "    ${CYAN}[Original]${NC}  $STAGED_APK"
echo -e "    ${CYAN}[Patched] ${NC}  $PATCHED_APK"
echo -e "    ${CYAN}[Signed]  ${NC}  $SIGNED_APK"
echo ""
echo -e "  ${BOLD}Final Checklist:${NC}"
echo -e "    ${GREEN}✓${NC} Burp Suite invisible proxying ENABLED"
echo -e "    ${GREEN}✓${NC} Burp bound to all interfaces on port $PROXY_PORT"
echo -e "    ${GREEN}✓${NC} Device proxy set to $HOST_IP:$PROXY_PORT"
echo -e "    ${GREEN}✓${NC} Burp certificate installed on device"
echo -e "    ${GREEN}✓${NC} Patched APK installed: $PACKAGE_NAME"
echo ""
echo -e "  ${BOLD}Next Steps:${NC}"
echo -e "    1. Open Burp Suite → Target → Site map"
echo -e "    2. Launch the app on your device"
echo -e "    3. Watch for traffic in Burp Suite"
echo ""
echo -e "  ${YELLOW}If no traffic appears:${NC}"
echo -e "    - Run with --no-frida and select Frida option"
echo -e "    - Check app has SSL pinning that needs bypassing"
echo -e "    - Verify invisible proxying is actually enabled"
echo ""

# Create convenience script for quick repatch
cat > "$OUTPUT_DIR/repatch.sh" << EOF
#!/bin/bash
# Quick repatch script for $PACKAGE_NAME
cd "$PROJECT_DIR"
bash scripts/instrument_flutter_app.sh --skip-build --skip-validation --proxy-ip $HOST_IP
EOF
chmod +x "$OUTPUT_DIR/repatch.sh"
ok "Created quick repatch script: $OUTPUT_DIR/repatch.sh"
