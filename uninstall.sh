#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Must run as root: sudo $0"
    exit 1
fi

systemctl stop omen-fan-curve.service 2>/dev/null || true
systemctl disable omen-fan-curve.service 2>/dev/null || true
rm -f /etc/systemd/system/omen-fan-curve.service
systemctl daemon-reload
rm -f /usr/local/bin/omen-fan-curve
echo "omen-fan-curve removed. Config kept at /etc/omen-fan-curve.json"
