#!/bin/bash
# install.sh - Install omen-fan-curve daemon
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Must run as root: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Installing omen-fan-curve ==="

# Install the script
install -m 755 "${SCRIPT_DIR}/omen-fan-curve" /usr/local/bin/omen-fan-curve
echo "[1/3] Installed /usr/local/bin/omen-fan-curve"

# Install config (don't overwrite existing)
if [[ ! -f /etc/omen-fan-curve.json ]]; then
    install -m 644 "${SCRIPT_DIR}/omen-fan-curve.json" /etc/omen-fan-curve.json
    echo "[2/3] Installed /etc/omen-fan-curve.json"
else
    echo "[2/3] Config /etc/omen-fan-curve.json already exists, skipping"
fi

# Install systemd service
install -m 644 "${SCRIPT_DIR}/omen-fan-curve.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable omen-fan-curve.service
echo "[3/3] Installed and enabled omen-fan-curve.service"

echo ""
echo "Done! Commands:"
echo "  sudo systemctl start omen-fan-curve    # Start the daemon"
echo "  sudo systemctl stop omen-fan-curve     # Stop (restores auto)"
echo "  omen-fan-curve status                  # Show current temps/fans"
echo "  sudo omen-fan-curve set 50             # Manual: set 50%"
echo "  sudo omen-fan-curve auto               # Restore auto mode"
echo "  sudo vim /etc/omen-fan-curve.json      # Edit the curve"
