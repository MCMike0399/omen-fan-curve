#!/bin/bash
# Install the Omen Fan Monitor Plasma widget
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WIDGET_ID="org.kde.plasma.omen-fan-monitor"

echo "Installing Omen Fan Monitor widget..."

# Install using kpackagetool6
kpackagetool6 -t Plasma/Applet -r "$WIDGET_ID" 2>/dev/null || true
kpackagetool6 -t Plasma/Applet -i "${SCRIPT_DIR}/widget"

echo ""
echo "Done! Right-click your panel → Add Widgets → search for 'Omen Fan Monitor'"
