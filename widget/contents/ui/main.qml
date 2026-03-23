import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property int fan1Rpm: dataProvider.fan1Rpm
    property int fan2Rpm: dataProvider.fan2Rpm
    property int fan1Pct: rpmToPercent(fan1Rpm)
    property int fan2Pct: rpmToPercent(fan2Rpm)
    property string fanMode: dataProvider.fanMode
    property real cpuTemp: dataProvider.cpuTemp
    property real gpuTemp: dataProvider.gpuTemp

    readonly property int minRpm: 2000
    readonly property int maxRpm: 5200

    preferredRepresentation: compactRepresentation

    FanDataProvider { id: dataProvider }

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

    // Compact representation (in panel)
    compactRepresentation: MouseArea {
        id: compactRoot

        Layout.minimumWidth: row.implicitWidth
        Layout.preferredWidth: row.implicitWidth

        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: row
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
                color: colorForPercent(root.fan1Pct)
            }
        }

        PlasmaComponents.ToolTip {
            text: "Fan 1: " + root.fan1Rpm + " RPM (" + root.fan1Pct + "%)\n" +
                  "Fan 2: " + root.fan2Rpm + " RPM (" + root.fan2Pct + "%)\n" +
                  "Mode: " + root.fanMode +
                  (root.cpuTemp > 0 ? "\nCPU: " + root.cpuTemp + "°C" : "") +
                  (root.gpuTemp > 0 ? "\nGPU: " + root.gpuTemp + "°C" : "")
        }
    }

    // Full representation (expanded popup)
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

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: modeLabel.implicitWidth + Kirigami.Units.mediumSpacing * 2
                    height: modeLabel.implicitHeight + Kirigami.Units.smallSpacing
                    radius: height / 2
                    color: root.fanMode === "manual" ? Kirigami.Theme.neutralTextColor :
                           root.fanMode === "max" ? Kirigami.Theme.negativeTextColor :
                           Kirigami.Theme.positiveTextColor
                    opacity: 0.2

                    PlasmaComponents.Label {
                        id: modeLabel
                        anchors.centerIn: parent
                        text: root.fanMode.toUpperCase()
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        font.bold: true
                        color: root.fanMode === "manual" ? Kirigami.Theme.neutralTextColor :
                               root.fanMode === "max" ? Kirigami.Theme.negativeTextColor :
                               Kirigami.Theme.positiveTextColor
                    }
                }
            }

            // Separator
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
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
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
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        color: colorForPercent(root.fan1Pct)
                    }
                }

                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: root.fan1Pct

                    background: Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: 6
                        radius: 3
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.separatorColor
                        border.width: 0.5
                    }

                    contentItem: Item {
                        implicitWidth: parent.width
                        implicitHeight: 6

                        Rectangle {
                            width: parent.parent.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: colorForPercent(root.fan1Pct)
                            opacity: 0.8
                        }
                    }
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
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
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
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        color: colorForPercent(root.fan2Pct)
                    }
                }

                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: root.fan2Pct

                    background: Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: 6
                        radius: 3
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.separatorColor
                        border.width: 0.5
                    }

                    contentItem: Item {
                        implicitWidth: parent.width
                        implicitHeight: 6

                        Rectangle {
                            width: parent.parent.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: colorForPercent(root.fan2Pct)
                            opacity: 0.8
                        }
                    }
                }
            }

            // Separator
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
                        color: root.cpuTemp >= 80 ? Kirigami.Theme.negativeTextColor :
                               root.cpuTemp >= 65 ? Kirigami.Theme.neutralTextColor :
                               Kirigami.Theme.textColor
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
                        color: root.gpuTemp >= 80 ? Kirigami.Theme.negativeTextColor :
                               root.gpuTemp >= 65 ? Kirigami.Theme.neutralTextColor :
                               Kirigami.Theme.textColor
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
                        text: {
                            var maxT = Math.max(root.cpuTemp, root.gpuTemp);
                            return maxT > 0 ? Math.round(maxT) + "°C" : "—";
                        }
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                        color: {
                            var maxT = Math.max(root.cpuTemp, root.gpuTemp);
                            return maxT >= 80 ? Kirigami.Theme.negativeTextColor :
                                   maxT >= 65 ? Kirigami.Theme.neutralTextColor :
                                   Kirigami.Theme.textColor;
                        }
                    }
                }
            }
        }
    }
}
