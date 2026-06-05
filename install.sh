#!/bin/sh
# Xboard-Node Alpine Linux Quick Installer
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

# Version
VERSION="1.0.0"

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
Xboard-Node Alpine Linux Installer v1.0.0

Usage:
  Machine Mode: curl -fsSL URL | sh -s -- --panel URL --token T --machine-id ID
  Node Mode:    curl -fsSL URL | sh -s -- --panel URL --token T --node-id ID

Arguments:
  --panel URL       Panel URL (required)
  --token TOKEN Auth token (required)
  --machine-id ID   Machine ID (for Machine Mode)
  --node-id ID      Node ID (for Node Mode)
  --version VERSION Xboard-Node version (default: latest)
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

# Create OpenRC service script
log_step "Creating OpenRC service script..."
cat > /etc/init.d/xboard-node <<'SVCEOF'
#!/sbin/openrc-run

description="Xboard Node Backend"
command="/usr/local/bin/xboard-node"
command_args="-c /etc/xboard-node/config.yml"
command_background=true
pidfile="/run/xboard-node.pid"
output_log="/var/log/xboard-node.log"
error_log="/var/log/xboard-node.err.log"

depend() {
    need net
    after firewall
}

start_pre() {
    mkdir -p /var/log
    touch "$output_log"
    touch "$error_log"
}
SVCEOF
chmod +x /etc/init.d/xboard-node

# Stop old service
log_step "Stopping existing service..."
rc-service xboard-node stop 2>/dev/null
killall xboard-node 2>/dev/null
rm -f /run/xboard-node.pid

# Start service
log_step "Starting xboard-node..."
rc-service xboard-node start

# Wait for startup
sleep 3

# Check status
if pgrep -x xboard-node >/dev/null; then
    echo ""
    echo "=============================================="
    log_info "Installation completed successfully!"
    echo "=============================================="
    echo ""
    log_info "Service status: running"
    log_info "View logs: tail -f /var/log/xboard-node.log"
    log_info "Restart: rc-service xboard-node restart"
    log_info "Stop: rc-service xboard-node stop"
    echo ""

    # Enable on boot
    rc-update add xboard-node default 2>/dev/null
    log_info "Enabled autostart on boot"
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