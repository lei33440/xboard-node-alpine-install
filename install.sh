#!/bin/sh
# Xboard-Node Alpine Linux Installer v1.1.0
#
# Usage:
#   Machine Mode: curl -fsSL URL | sh -s -- --panel URL --token T --machine-id ID
#   Node Mode:    curl -fsSL URL | sh -s -- --panel URL --token T --node-id ID
#
# Documentation: https://github.com/lei33440/xboard-node-alpine-install

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="1.1.0"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check root
[ "$(id -u)" -ne 0 ] && log_error "Please run as root" && exit 1

# Check Alpine Linux
[ ! -f /etc/alpine-release ] && log_error "This script only supports Alpine Linux" && exit 1

# Parse arguments
MODE=""
PANEL_URL=""
TOKEN=""
NODE_ID=""
MACHINE_ID=""
INSTALL_VERSION="latest"

while [ $# -gt 0 ]; do
    case "$1" in
        --panel) PANEL_URL="$2"; shift 2;;
        --token) TOKEN="$2"; shift 2;;
        --machine-id) MACHINE_ID="$2"; MODE="machine"; shift 2;;
        --node-id) NODE_ID="$2"; MODE="node"; shift 2;;
        --version) INSTALL_VERSION="$2"; shift 2;;
        --help) cat <<'HELP'
Xboard-Node Alpine Linux Installer v1.1.0

Usage:
  Machine Mode: curl -fsSL URL | sh -s -- --panel URL --token T --machine-id ID
  Node Mode:    curl -fsSL URL | sh -s -- --panel URL --token T --node-id ID

Arguments:
  --panel URL       Panel URL (required)
  --token TOKEN     Auth token (required)
  --machine-id ID   Machine ID (for Machine Mode)
  --node-id ID      Node ID (for Node Mode)
  --version VER     Xboard-Node version (default: latest)
  --help            Show this help

Examples:
  # Machine Mode
  curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-alpine-install/main/install.sh | sh -s -- \
    --panel http://panel.com --token xxx --machine-id 21

  # Node Mode
  curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-alpine-install/main/install.sh | sh -s -- \
    --panel http://panel.com --token xxx --node-id 1

Documentation: https://github.com/lei33440/xboard-node-alpine-install
HELP
exit 0 ;;
        *) shift;;
    esac
done

# Validate arguments
[ -z "$PANEL_URL" ] && log_error "Missing --panel argument" && exit 1
[ -z "$TOKEN" ] && log_error "Missing --token argument" && exit 1
[ -z "$MODE" ] && log_error "Please specify --machine-id or --node-id" && exit 1

# Banner
echo ""
echo "=============================================="
echo "  Xboard-Node Alpine Installer v${VERSION}"
echo "=============================================="
echo ""
log_info "Mode: ${MODE}"
log_info "Panel: ${PANEL_URL}"
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64|arm64) ARCH_NAME="arm64" ;;
    *) log_error "Unsupported architecture: $ARCH" && exit 1 ;;
esac
log_info "Architecture: $ARCH ($ARCH_NAME)"

# Install dependencies
log_step "Installing dependencies..."
apk add --no-cache curl ca-certificates openrc >/dev/null 2>&1
mkdir -p /etc/xboard-node /var/log

# Download binary
log_step "Downloading xboard-node..."
BASE="https://github.com/cedar2025/xboard-node/releases"
if [ "$INSTALL_VERSION" = "latest" ]; then
    DOWNLOAD_URL="$BASE/latest/download/xboard-node-linux-$ARCH_NAME"
else
    DOWNLOAD_URL="$BASE/download/$INSTALL_VERSION/xboard-node-linux-$ARCH_NAME"
fi

curl -fsSL -o /usr/local/bin/xboard-node "$DOWNLOAD_URL" || {
    log_error "Failed to download xboard-node"
    log_error "URL: $DOWNLOAD_URL"
    exit 1
}
chmod +x /usr/local/bin/xboard-node
log_info "Binary downloaded successfully"

# Create config
log_step "Creating configuration..."
ID_PREFIX=$(echo "$PANEL_URL" | sed 's|https\?://||' | tr './' '-')

if [ "$MODE" = "machine" ]; then
    INSTANCE_ID="${ID_PREFIX}-machine-${MACHINE_ID}-$(date +%s)"
    cat > /etc/xboard-node/config.yml <<EOF
instances:
    - id: ${INSTANCE_ID}
      panel:
        url: ${PANEL_URL}
      machine:
        machine_id: ${MACHINE_ID}
        token: ${TOKEN}
EOF
    log_info "Configured as Machine Mode (ID: $MACHINE_ID)"
else
    cat > /etc/xboard-node/config.yml <<EOF
panel:
  url: "${PANEL_URL}"
  token: "${TOKEN}"
  node_id: ${NODE_ID}
EOF
    log_info "Configured as Node Mode (ID: $NODE_ID)"
fi

# Stop old service
log_step "Stopping existing service..."
pkill -9 xboard-node 2>/dev/null || true
rm -f /run/xboard-node.pid
sleep 1

# Start service directly (more reliable on Alpine)
log_step "Starting xboard-node..."
/usr/local/bin/xboard-node -c /etc/xboard-node/config.yml >> /var/log/xboard-node.log 2>&1 &

# Wait for startup
sleep 3

# Check status
if pgrep -x xboard-node >/dev/null; then
    # Get listening port
    PORT=$(ss -tlnp 2>/dev/null | grep xboard-node | awk '{print $4}' | cut -d: -f2)

    echo ""
    echo "=============================================="
    log_info "Installation completed successfully!"
    echo "=============================================="
    echo ""
    log_info "Config: /etc/xboard-node/config.yml"
    log_info "Log: /var/log/xboard-node.log"
    if [ -n "$PORT" ]; then
        log_info "Listening port: $PORT"
    fi
    echo ""
    log_info "Commands:"
    log_info "  View logs:  tail -f /var/log/xboard-node.log"
    log_info "  Restart:    /usr/local/bin/xboard-node -c /etc/xboard-node/config.yml >> /var/log/xboard-node.log 2>&1 &"
    echo ""

    # Set up autostart
    if [ ! -f /etc/local.d/xboard-node.start ]; then
        log_step "Setting up autostart..."
        cat > /etc/local.d/xboard-node.start <<'AUTOSTART'
#!/bin/sh
# Start xboard-node on boot
sleep 2
mkdir -p /var/log
/usr/local/bin/xboard-node -c /etc/xboard-node/config.yml >> /var/log/xboard-node.log 2>&1 &
AUTOSTART
        chmod +x /etc/local.d/xboard-node.start
        log_info "Autostart configured"
    fi
else
    echo ""
    echo "=============================================="
    log_error "Service failed to start"
    echo "=============================================="
    echo ""
    log_error "Please check logs:"
    log_error "  tail -30 /var/log/xboard-node.log"
    echo ""
    exit 1
fi