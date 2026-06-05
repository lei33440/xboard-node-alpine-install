#!/bin/sh
# Xboard-Node Alpine Linux 卸载脚本
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-alpine-install/main/uninstall.sh | sh
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
[ "$(id -u)" -ne 0 ] && log_error "Please run as root" && exit 1

echo ""
echo "=============================================="
echo "  Xboard-Node Uninstall Script"
echo "=============================================="
echo ""

# Stop service
log_info "Stopping xboard-node service..."
rc-service xboard-node stop 2>/dev/null
killall xboard-node 2>/dev/null

# Remove service script
log_info "Removing service script..."
rm -f /etc/init.d/xboard-node

# Remove binary
log_info "Removing binary..."
rm -f /usr/local/bin/xboard-node

# Remove config
log_info "Removing configuration..."
rm -rf /etc/xboard-node

# Remove logs
log_info "Removing logs..."
rm -f /var/log/xboard-node.log
rm -f /var/log/xboard-node.err.log

# Remove pid file
rm -f /run/xboard-node.pid

# Disable autostart
rc-update del xboard-node default 2>/dev/null

echo ""
echo "=============================================="
log_info "Uninstallation completed!"
echo "=============================================="
echo ""
log_info "All xboard-node files have been removed."
echo ""