import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Rectangle {
    id: root

    function fmtSpeed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024)    return (bps / 1024).toFixed(0) + " KB/s"
        return (bps > 0 ? bps.toFixed(0) : "0") + " B/s"
    }

    function formatBytes(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576)    return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024)       return (b / 1024).toFixed(0) + " KB"
        return b + " B"
    }

    radius: 24
    implicitHeight: 86
    clip: true
    color: Pywal.surfaceContainerHigh

    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 10; topMargin: 10; bottomMargin: 10 }
        spacing: 10

        ColumnLayout {
            spacing: 2
            Layout.preferredWidth: 90

            Text {
                text: "Network"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Pywal.info
            }

            ColumnLayout {
                spacing: 3

                RowLayout {
                    spacing: 5
                    Text {
                        text: "↓"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Pywal.success
                    }
                    Text {
                        text: root.fmtSpeed(SystemUsage.downloadSpeed)
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: Pywal.foreground
                    }
                }

                RowLayout {
                    spacing: 5
                    Text {
                        text: "↑"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Pywal.info
                    }
                    Text {
                        text: root.fmtSpeed(SystemUsage.uploadSpeed)
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: Pywal.foreground
                    }
                }
            }

            Rectangle {
                width: 80; height: 1
                color: Qt.rgba(Pywal.outlineVariant.r, Pywal.outlineVariant.g, Pywal.outlineVariant.b, 0.4)
            }

            Text {
                text: "↓ " + root.formatBytes(SystemUsage.lastRxBytes) + " · ↑ " + root.formatBytes(SystemUsage.lastTxBytes)
                font.family: "Inter"
                font.pixelSize: 9
                color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.5)
            }
        }

        NetworkGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            dataPoints: SystemUsage.networkHistory
            downloadColor: Pywal.success
            uploadColor: Pywal.info
            showGrid: true
            lineWidth: 1.5
            gradientOpacity: 0.18
        }
    }
}
