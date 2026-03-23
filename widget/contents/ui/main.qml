import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    property int fan1Rpm: fan1Sensor.value || 0
    property int fan2Rpm: fan2Sensor.value || 0
    property int fan1Pct: rpmToPercent(fan1Rpm)
    property int fan2Pct: rpmToPercent(fan2Rpm)
    property real cpuTemp: cpuTempSensor.value || 0
    property real gpuTemp: gpuTempSensor.value || 0

    readonly property int minRpm: 2000
    readonly property int maxRpm: 5200

    preferredRepresentation: compactRepresentation

    // Native KSysGuard sensors — no shell commands needed
    Sensors.Sensor { id: fan1Sensor; sensorId: "lmsensors/hp-isa-0000/fan1"; updateInterval: 2000 }
    Sensors.Sensor { id: fan2Sensor; sensorId: "lmsensors/hp-isa-0000/fan2"; updateInterval: 2000 }
    Sensors.Sensor { id: cpuTempSensor; sensorId: "cpu/all/averageTemperature"; updateInterval: 2000 }
    Sensors.Sensor { id: gpuTempSensor; sensorId: "gpu/gpu1/temperature"; updateInterval: 2000 }

    function rpmToPercent(rpm) {
        if (rpm <= 0) return 0;
        if (rpm <= minRpm) return Math.round(rpm / minRpm * 20);
        var pct = Math.round((rpm - minRpm) / (maxRpm - minRpm) * 80 + 20);
        return Math.min(100, Math.max(0, pct));
    }

    function colorForPercent(pct) {
        if (pct <= 30) return Kirigami.Theme.positiveTextColor;
        if (pct <= 60) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.negativeTextColor;
    }

    function tempColor(temp) {
        if (temp >= 80) return Kirigami.Theme.negativeTextColor;
        if (temp >= 65) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.textColor;
    }

    // Compact representation (panel)
    compactRepresentation: MouseArea {
        id: compactRoot
        Layout.minimumWidth: compactRow.implicitWidth
        Layout.preferredWidth: compactRow.implicitWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "sensors-fan"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

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

    // Full representation (popup)
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredHeight: mainColumn.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.mediumSpacing

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "sensors-fan"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                PlasmaComponents.Label {
                    text: "Omen Fan Monitor"
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.Theme.separatorColor
            }

            // Fan 1
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        text: "Fan 1"
                        opacity: 0.8
                    }
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

                    PlasmaComponents.Label {
                        text: "Fan 2"
                        opacity: 0.8
                    }
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
                color: Kirigami.Theme.separatorColor
            }

            // Temperatures
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    spacing: 2
                    PlasmaComponents.Label {
                        text: "CPU"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
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
                        text: "GPU"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
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
                        text: "Max"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.6
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
