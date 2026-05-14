#!/bin/bash
# =============================================================================
# install_dependencies.sh
# Installs and verifies all tools required for ReFlutter APK instrumentation.
# Usage: bash install_dependencies.sh
# =============================================================================

set -e

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── Helpers ──────────────────────────────────────────────────────────────────
ok()   { echo -e "${GREEN}  ✓ $*${NC}"; }
warn() { echo -e "${YELLOW}  ⚠ $*${NC}"; }
err()  { echo -e "${RED}  ✗ $*${NC}"; }
info() { echo -e "${CYAN}  → $*${NC}"; }
section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${NC}"; echo -e "${BOLD}  $*${NC}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════${NC}"; }

TOOLS_DIR="$HOME/tools"
SIGNER_VERSION="1.3.0"
SIGNER_JAR="uber-apk-signer-${SIGNER_VERSION}.jar"
SIGNER_URL="https://github.com/patrickfav/uber-apk-signer/releases/download/v${SIGNER_VERSION}/${SIGNER_JAR}"

ERRORS=()

# ─── 1. System Packages ───────────────────────────────────────────────────────
section "Step 1 — System Packages"

info "Updating apt package index…"
sudo apt-get update -qq

PACKAGES=(git curl unzip wget python3 python3-pip openjdk-17-jre android-tools-adb)

for pkg in "${PACKAGES[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg…"
    if sudo apt-get install -y "$pkg" &>/dev/null; then
      ok "$pkg installed"
    else
      # Fallback: try openjdk-11-jre if openjdk-17 not available
      if [[ "$pkg" == "openjdk-17-jre" ]]; then
        warn "openjdk-17-jre not available, trying openjdk-11-jre…"
        sudo apt-get install -y openjdk-11-jre &>/dev/null && ok "openjdk-11-jre installed" || {
          err "Failed to install Java. Install manually: sudo apt install openjdk-17-jre"
          ERRORS+=("java")
        }
      else
        err "Failed to install $pkg"
        ERRORS+=("$pkg")
      fi
    fi
  fi
done

# ─── 2. Python / pip ──────────────────────────────────────────────────────────
section "Step 2 — Python & pip"

info "Upgrading pip…"
python3 -m pip install --upgrade pip --quiet
ok "pip upgraded"

# ─── 3. ReFlutter ─────────────────────────────────────────────────────────────
section "Step 3 — ReFlutter"

if command -v reflutter &>/dev/null; then
  CURRENT_VER=$(python3 -m pip show reflutter 2>/dev/null | grep Version | awk '{print $2}')
  ok "ReFlutter already installed (version: ${CURRENT_VER:-unknown})"
  info "Upgrading to latest version…"
  python3 -m pip install --upgrade reflutter --quiet && ok "ReFlutter upgraded"
else
  info "Installing ReFlutter…"
  python3 -m pip install reflutter --quiet
  ok "ReFlutter installed"
fi

# Ensure ~/.local/bin is on PATH for this session
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  warn "Added ~/.local/bin to PATH for this session."
  warn "Add the following line to your ~/.bashrc or ~/.zshrc to make it permanent:"
  echo -e "    ${YELLOW}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
fi

# ─── 4. Uber APK Signer ───────────────────────────────────────────────────────
section "Step 4 — Uber APK Signer"

mkdir -p "$TOOLS_DIR"

if [ -f "$TOOLS_DIR/$SIGNER_JAR" ]; then
  ok "Uber APK Signer already present at $TOOLS_DIR/$SIGNER_JAR"
else
  info "Downloading Uber APK Signer v${SIGNER_VERSION}…"
  if wget -q --show-progress -O "$TOOLS_DIR/$SIGNER_JAR" "$SIGNER_URL"; then
    ok "Downloaded to $TOOLS_DIR/$SIGNER_JAR"
  else
    err "Download failed. Check your internet connection or download manually from:"
    err "  $SIGNER_URL"
    ERRORS+=("uber-apk-signer")
  fi
fi

# ─── 5. Verification ──────────────────────────────────────────────────────────
section "Step 5 — Verification"

echo ""
printf "%-30s %s\n" "Tool" "Status"
echo "──────────────────────────────────────────────────"

# Flutter
if command -v flutter &>/dev/null; then
  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  printf "%-30s ${GREEN}✓ installed${NC} (v%s)\n" "flutter" "$FLUTTER_VER"
else
  printf "%-30s ${RED}✗ NOT FOUND${NC} — install Flutter SDK\n" "flutter"
  ERRORS+=("flutter")
fi

# ADB
if command -v adb &>/dev/null; then
  ADB_VER=$(adb version 2>/dev/null | head -1 | sed 's/Android Debug Bridge/ADB/')
  printf "%-30s ${GREEN}✓ installed${NC} (%s)\n" "adb" "$ADB_VER"
else
  printf "%-30s ${RED}✗ NOT FOUND${NC} — sudo apt install android-tools-adb\n" "adb"
  ERRORS+=("adb")
fi

# Java
if command -v java &>/dev/null; then
  JAVA_VER=$(java -version 2>&1 | head -1)
  printf "%-30s ${GREEN}✓ installed${NC} (%s)\n" "java" "$JAVA_VER"
else
  printf "%-30s ${RED}✗ NOT FOUND${NC} — sudo apt install openjdk-17-jre\n" "java"
  ERRORS+=("java")
fi

# ReFlutter
if command -v reflutter &>/dev/null || python3 -m reflutter --help &>/dev/null 2>&1; then
  RF_VER=$(python3 -m pip show reflutter 2>/dev/null | grep Version | awk '{print $2}')
  printf "%-30s ${GREEN}✓ installed${NC} (v%s)\n" "reflutter" "${RF_VER:-unknown}"
else
  printf "%-30s ${RED}✗ NOT FOUND${NC} — python3 -m pip install reflutter\n" "reflutter"
  ERRORS+=("reflutter")
fi

# Uber APK Signer
if [ -f "$TOOLS_DIR/$SIGNER_JAR" ]; then
  printf "%-30s ${GREEN}✓ present${NC} (%s)\n" "uber-apk-signer" "$TOOLS_DIR/$SIGNER_JAR"
else
  printf "%-30s ${RED}✗ NOT FOUND${NC} — %s\n" "uber-apk-signer" "$TOOLS_DIR/$SIGNER_JAR"
  ERRORS+=("uber-apk-signer")
fi

# ADB Devices
echo ""
info "Connected Android devices:"
adb devices 2>/dev/null || warn "ADB not available"

echo ""
echo "──────────────────────────────────────────────────"

# ─── Summary ──────────────────────────────────────────────────────────────────
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo -e "\n${GREEN}${BOLD}  All dependencies installed successfully!${NC}"
  echo -e "${CYAN}  You can now run: ${BOLD}./instrument_flutter_app.sh${NC}"
else
  echo -e "\n${RED}${BOLD}  Installation completed with errors for: ${ERRORS[*]}${NC}"
  echo -e "${YELLOW}  Please resolve the above issues before running the instrumentation script.${NC}"
  exit 1
fi
