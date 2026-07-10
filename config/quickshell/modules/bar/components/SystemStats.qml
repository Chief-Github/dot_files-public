// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services

Item {
    id: root
    implicitWidth: statsRow.implicitWidth
    implicitHeight: 22

    property var sysInfoPopup

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.sysInfoPopup)
                root.sysInfoPopup.shouldShow = !root.sysInfoPopup.shouldShow
        }
    }

    RowLayout {
        id: statsRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: Math.round(SystemUsage.cpuTemp) + "°"
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: {
                const t = SystemUsage.cpuTemp
                if (t > 80) return Pywal.error
                if (t > 65) return Pywal.warning
                return Pywal.foreground
            }
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            width: 1; height: 10; radius: 0.5
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.15)
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: "󰍛"
            font.family: "Material Design Icons"
            font.pixelSize: 13
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.65)
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: Math.round(SystemUsage.cpuPerc * 100) + "%"
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Pywal.foreground
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            width: 1; height: 10; radius: 0.5
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.15)
            Layout.alignment: Qt.AlignVCenter
        }
        

        Text {
            text: "󰘚"
            font.family: "Material Design Icons"
            font.pixelSize: 13
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.65)
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: Math.round(SystemUsage.memPerc * 100) + "%"
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Pywal.foreground
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
