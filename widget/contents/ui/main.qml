import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    property int fan1Rpm: 0
    property int fan2Rpm: 0
    property int fan1Pct: 0
    property int fan2Pct: 0
    property real cpuTemp: 0
    property real gpuTemp: 0
    property int pwmValue: 0
    property bool manualMode: false

    readonly property int minRpm: 2000
    readonly property int maxRpm: 5200

    function rpmToPercent(rpm) {
        if (rpm <= 0) return 0
        if (rpm <= minRpm) return Math.round(rpm / minRpm * 20)
        var pct = Math.round((rpm - minRpm) / (maxRpm - minRpm) * 80 + 20)
        return Math.min(100, Math.max(0, pct))
    }

    function pwmToPercent(pwm) {
        return Math.round(pwm / 255 * 100)
    }

    function colorForPercent(pct) {
        // Blue gradient: light blue → medium blue → deep blue
        if (pct <= 30) return "#7AB8FF"
        if (pct <= 50) return "#5A9CF0"
        if (pct <= 70) return "#3D7FDB"
        return "#2563C4"
    }

    function tempColor(temp) {
        if (temp >= 80) return "#2563C4"
        if (temp >= 65) return "#3D7FDB"
        return "#7AB8FF"
    }

    Plasma5Support.DataSource {
        id: dataSource
        engine: "executable"
        connectedSources: [
            "HP=$(grep -rl '^hp$' /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname 2>/dev/null); CT=$(grep -rl '^coretemp$' /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname 2>/dev/null); echo \"$(cat $HP/fan1_input 2>/dev/null || echo 0),$(cat $HP/fan2_input 2>/dev/null || echo 0),$(cat $CT/temp1_input 2>/dev/null || echo 0),$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0),$(cat $HP/pwm1 2>/dev/null || echo 0),$(cat $HP/pwm1_enable 2>/dev/null || echo 0)\""
        ]
        interval: 2000

        onNewData: function(source, data) {
            var parts = data.stdout.trim().split(",")
            if (parts.length >= 6) {
                root.fan1Rpm = parseInt(parts[0]) || 0
                root.fan2Rpm = parseInt(parts[1]) || 0
                root.cpuTemp = (parseInt(parts[2]) || 0) / 1000
                root.gpuTemp = parseFloat(parts[3]) || 0
                root.pwmValue = parseInt(parts[4]) || 0
                root.manualMode = (parseInt(parts[5]) === 1)

                if (root.manualMode) {
                    var pct = pwmToPercent(root.pwmValue)
                    root.fan1Pct = pct
                    root.fan2Pct = pct
                } else {
                    root.fan1Pct = rpmToPercent(root.fan1Rpm)
                    root.fan2Pct = rpmToPercent(root.fan2Rpm)
                }
            }
        }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: compactRow.implicitWidth
        Layout.preferredWidth: compactRow.implicitWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: root.fan1Pct + "%"
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                color: root.colorForPercent(root.fan1Pct)
            }
        }

        PlasmaComponents.ToolTip {
            text: "Fan 1: " + root.fan1Rpm + " RPM (" + root.fan1Pct + "%)\n" +
                  "Fan 2: " + root.fan2Rpm + " RPM (" + root.fan2Pct + "%)" +
                  (root.cpuTemp > 0 ? "\nCPU: " + Math.round(root.cpuTemp) + "°C" : "") +
                  (root.gpuTemp > 0 ? "\nGPU: " + Math.round(root.gpuTemp) + "°C" : "")
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredHeight: mainColumn.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.mediumSpacing

            PlasmaComponents.Label {
                text: "Omen Fan Monitor"
                font.bold: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                color: "#5A9CF0"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(0.48, 0.72, 1.0, 0.2)
            }

            // Fan 1
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label { text: "Fan 1"; opacity: 0.8 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: root.fan1Rpm + " RPM"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
                    }
                    PlasmaComponents.Label {
                        text: root.fan1Pct + "%"
                        font.bold: true
                        color: root.colorForPercent(root.fan1Pct)
                    }
                }

                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0; to: 100; value: root.fan1Pct
                }
            }

            // Fan 2
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label { text: "Fan 2"; opacity: 0.8 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: root.fan2Rpm + " RPM"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
                    }
                    PlasmaComponents.Label {
                        text: root.fan2Pct + "%"
                        font.bold: true
                        color: root.colorForPercent(root.fan2Pct)
                    }
                }

                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0; to: 100; value: root.fan2Pct
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(0.48, 0.72, 1.0, 0.2)
            }

            // Temperatures
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    spacing: 2
                    PlasmaComponents.Label {
                        text: "CPU"; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; opacity: 0.6
                    }
                    PlasmaComponents.Label {
                        text: root.cpuTemp > 0 ? Math.round(root.cpuTemp) + "°C" : "—"
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                        color: root.tempColor(root.cpuTemp)
                    }
                }

                ColumnLayout {
                    spacing: 2
                    PlasmaComponents.Label {
                        text: "GPU"; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; opacity: 0.6
                    }
                    PlasmaComponents.Label {
                        text: root.gpuTemp > 0 ? Math.round(root.gpuTemp) + "°C" : "—"
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                        color: root.tempColor(root.gpuTemp)
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 2
                    PlasmaComponents.Label {
                        text: "Max"; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; opacity: 0.6
                    }
                    PlasmaComponents.Label {
                        property real maxTemp: Math.max(root.cpuTemp, root.gpuTemp)
                        text: maxTemp > 0 ? Math.round(maxTemp) + "°C" : "—"
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                        color: root.tempColor(maxTemp)
                    }
                }
            }
        }
    }
}
