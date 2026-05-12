#!/usr/bin/env bash
# =============================================================================
# reflutter_patch.sh — Patch a Flutter debug/release APK for Burp Suite interception
# =============================================================================

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────

# Auto-detect project directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"  # Use script's location as project root

DEFAULT_PACKAGE="com.example.imsapp"
BUILD_TYPE="debug"  # Change to "release" if you really need release (won't work due to pinning)
UBER_SIGNER_VERSION="1.3.0"
UBER_SIGNER_JAR="uber-apk-signer-${UBER_SIGNER_VERSION}.jar"
UBER_SIGNER_URL="https://github.com/nicholasgasior/uber-apk-signer/releases/download/v${UBER_SIGNER_VERSION}/${UBER_SIGNER_JAR}"
UBER_SIGNER_URL_FALLBACK="https://github.com/nicholasgasior/uber-apk-signer/releases/latest/download/${UBER_SIGNER_JAR}"

# ─── Color Codes ─────────────────────────────────────────────────────────────

USE_COLOR=true

setup_colors() {
    if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
    fi
}

# ─── Logging Helpers ─────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[✔]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[✘]${NC}      $*" >&2; }
step()    { echo -e "\n${BOLD}${CYAN}══════ $* ══════${NC}\n"; }

# ─── Usage ───────────────────────────────────────────────────────────────────

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -a, --apk <path>       Path to the APK (auto-detected if omitted)
  -b, --build <type>     Build type: debug or release (default: debug)
  -p, --package <id>     Android package ID (default: com.example.imsapp)
  -i, --ip <addr>        Proxy IP for reflutter (auto-detected)
  -w, --workdir <path>   Working directory (default: /tmp/reflutter_work)
  -s, --skip-install     Skip ADB uninstall/install steps
  --no-color             Disable colored output
  -h, --help             Show this help message

Examples:
  ./reflutter_patch.sh                    # Auto-detect, use debug build
  ./reflutter_patch.sh -b release         # Try release (likely fails due to pinning)
  ./reflutter_patch.sh --skip-install     # Patch only, don't install

Note: DEBUG builds work best for Burp Suite interception because they
      have certificate pinning disabled by default.
EOF
    exit 0
}

# ─── Parse Arguments ─────────────────────────────────────────────────────────

APK_PATH=""
PACKAGE_ID="$DEFAULT_PACKAGE"
PROXY_IP=""
WORK_DIR="/tmp/reflutter_work"
SKIP_INSTALL=false
BUILD_TYPE="debug"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--apk)       APK_PATH="$2";       shift 2 ;;
        -b|--build)     BUILD_TYPE="$2";     shift 2 ;;
        -p|--package)   PACKAGE_ID="$2";     shift 2 ;;
        -i|--ip)        PROXY_IP="$2";       shift 2 ;;
        -w|--workdir)   WORK_DIR="$2";       shift 2 ;;
        -s|--skip-install) SKIP_INSTALL=true; shift   ;;
        --no-color)     USE_COLOR=false;     shift   ;;
        -h|--help)      usage                        ;;
        *)              error "Unknown option: $1"; usage ;;
    esac
done

setup_colors

# Validate build type
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
    exit 1
fi

if [[ "$BUILD_TYPE" == "release" ]]; then
    warn "RELEASE builds have certificate pinning enabled!"
    warn "Supabase API will likely NOT appear in Burp Suite."
    warn "Use DEBUG build for full traffic interception."
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# ─── Auto-detect Proxy IP ────────────────────────────────────────────────────

detect_proxy_ip() {
    if [[ -z "$PROXY_IP" ]]; then
        PROXY_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
        if [[ -z "$PROXY_IP" ]]; then
            PROXY_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || true)
        fi
        if [[ -z "$PROXY_IP" ]]; then
            error "Could not auto-detect your LAN IP. Use --ip <addr> to specify it."
            exit 1
        fi
        info "Auto-detected proxy IP: ${BOLD}$PROXY_IP${NC}"
    else
        info "Using specified proxy IP: ${BOLD}$PROXY_IP${NC}"
    fi
}

# ─── Auto-detect APK based on build type ─────────────────────────────────────

detect_apk() {
    if [[ -n "$APK_PATH" ]]; then
        if [[ ! -f "$APK_PATH" ]]; then
            error "Specified APK not found: $APK_PATH"
            exit 1
        fi
        info "Using specified APK: $APK_PATH"
        return
    fi

    # Search paths based on build type
    local search_paths=()
    
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        search_paths=(
            "$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
            "$PROJECT_DIR/build/app/outputs/apk/debug/app-debug.apk"
            "$PROJECT_DIR/build/app/outputs/apk/debug/app-armeabi-v7a-debug.apk"
            "$PROJECT_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk"
        )
    else
        search_paths=(
            "$PROJECT_DIR/build/app/outputs/apk/release/app-release.apk"
            "$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
            "$PROJECT_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
        )
    fi

    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            APK_PATH="$path"
            info "Auto-detected ${BUILD_TYPE} APK: $APK_PATH"
            return
        fi
    done

    # Fallback: find any matching APK
    APK_PATH=$(find "$PROJECT_DIR/build" -name "*${BUILD_TYPE}*.apk" -type f 2>/dev/null | head -1 || true)
    if [[ -n "$APK_PATH" ]]; then
        info "Found ${BUILD_TYPE} APK via search: $APK_PATH"
        return
    fi

    error "No ${BUILD_TYPE} APK found. Build one first with:"
    error "  flutter build apk --${BUILD_TYPE}"
    exit 1
}

# ─── Build APK if missing ─────────────────────────────────────────────────────

build_apk_if_needed() {
    if [[ -n "$APK_PATH" ]] && [[ -f "$APK_PATH" ]]; then
        return
    fi
    
    info "${BUILD_TYPE} APK not found. Building now..."
    cd "$PROJECT_DIR"
    
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        flutter build apk --debug
    else
        flutter build apk --release
    fi
    
    # Re-detect after build
    detect_apk
}

# ─── Dependency Checks ───────────────────────────────────────────────────────

check_python() {
    if command -v python3 &>/dev/null; then
        success "Python 3 found: $(python3 --version 2>&1)"
    else
        error "Python 3 is required but not installed."
        exit 1
    fi
}

check_java() {
    if command -v java &>/dev/null; then
        success "Java found: $(java -version 2>&1 | head -1)"
    else
        error "Java is required but not installed."
        exit 1
    fi
}

check_adb() {
    if command -v adb &>/dev/null; then
        success "ADB found: $(adb version 2>&1 | head -1)"
    else
        error "ADB is required but not installed."
        exit 1
    fi
}

check_reflutter() {
    if command -v reflutter &>/dev/null; then
        success "reflutter found"
    else
        warn "reflutter not found. Installing via pip..."
        pip3 install reflutter --break-system-packages 2>/dev/null || pip3 install reflutter || pip install reflutter
        if command -v reflutter &>/dev/null; then
            success "reflutter installed successfully."
        elif [[ -f "$HOME/.local/bin/reflutter" ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            success "reflutter installed to ~/.local/bin"
        else
            error "Failed to install reflutter."
            exit 1
        fi
    fi
}

check_uber_signer() {
    local search_locations=(
        "$WORK_DIR/$UBER_SIGNER_JAR"
        "$HOME/Documents/$UBER_SIGNER_JAR"
        "$HOME/$UBER_SIGNER_JAR"
        "./$UBER_SIGNER_JAR"
    )

    for loc in "${search_locations[@]}"; do
        if [[ -f "$loc" ]]; then
            UBER_SIGNER_PATH="$loc"
            success "uber-apk-signer found: $UBER_SIGNER_PATH"
            return
        fi
    done

    warn "uber-apk-signer not found. Downloading..."
    UBER_SIGNER_PATH="$WORK_DIR/$UBER_SIGNER_JAR"
    mkdir -p "$WORK_DIR"

    if wget -q --show-progress -O "$UBER_SIGNER_PATH" "$UBER_SIGNER_URL" 2>/dev/null; then
        success "Downloaded uber-apk-signer"
    else
        error "Failed to download uber-apk-signer."
        exit 1
    fi
}

check_adb_device() {
    if [[ "$SKIP_INSTALL" == true ]]; then
        return
    fi

    local devices
    devices=$(adb devices 2>/dev/null | grep -w "device" | grep -v "List" || true)
    if [[ -z "$devices" ]]; then
        warn "No Android device detected."
        warn "Continuing without install step..."
        SKIP_INSTALL=true
    else
        success "ADB device detected"
    fi
}

# ─── Main Workflow ───────────────────────────────────────────────────────────

main() {
    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║      Flutter APK Patcher — Burp Suite Traffic Intercept     ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
    
    info "Build type: ${BOLD}${BUILD_TYPE}${NC}"
    
    if [[ "$BUILD_TYPE" == "debug" ]]; then
        success "DEBUG build — Certificate pinning is DISABLED ✅"
    else
        warn "RELEASE build — Certificate pinning is ENABLED ⚠️"
    fi

    # Step 1: Check Dependencies
    step "Step 1/6 — Checking Dependencies"
    check_python
    check_java
    check_adb
    check_reflutter

    # Step 2: Detect/Build APK
    step "Step 2/6 — Preparing APK"
    detect_apk
    build_apk_if_needed
    detect_proxy_ip
    mkdir -p "$WORK_DIR"
    check_uber_signer
    check_adb_device

    # Step 3: Copy APK
    step "Step 3/6 — Copying APK"
    local apk_basename
    apk_basename=$(basename "$APK_PATH")
    local work_apk="$WORK_DIR/$apk_basename"
    cp -v "$APK_PATH" "$work_apk"

    # Step 4: Patch with reflutter
    step "Step 4/6 — Patching APK with reflutter"
    info "Proxy IP: $PROXY_IP"
    (echo "1"; echo "$PROXY_IP") | reflutter "$work_apk"

    # Find patched APK
    local patched_apk="$WORK_DIR/release.RE.apk"
    if [[ ! -f "$patched_apk" ]]; then
        find . -name "release.RE.apk" -newer "$work_apk" -exec mv {} "$patched_apk" \; 2>/dev/null || true
    fi

    if [[ ! -f "$patched_apk" ]]; then
        error "Patched APK not found!"
        exit 1
    fi

    success "APK patched successfully"

    # Step 5: Sign
    step "Step 5/6 — Signing APK"
    java -jar "$UBER_SIGNER_PATH" --apk "$patched_apk"
    
    local signed_apk="$WORK_DIR/release.RE-aligned-debugSigned.apk"
    if [[ ! -f "$signed_apk" ]]; then
        signed_apk=$(find "$WORK_DIR" -name "*Signed*.apk" -type f | head -1)
    fi
    
    success "APK signed successfully"

    # Step 6: Install
    step "Step 6/6 — Installing"
    if [[ "$SKIP_INSTALL" == false ]]; then
        adb uninstall "$PACKAGE_ID" 2>/dev/null || true
        adb install "$signed_apk" && success "Installed successfully!"
    fi

    # Final output
    echo ""
    echo -e "${BOLD}${GREEN}✅ COMPLETE!${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo "  1. Ensure Burp Suite is listening on port 8083 (All interfaces)"
    echo "  2. Set WiFi proxy on phone to: ${BOLD}$PROXY_IP:8083${NC}"
    echo "  3. Install Burp CA certificate on device"
    echo "  4. Launch app and check Burp Suite → Proxy → HTTP history"
    echo ""
}

main "$@"
