// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Io
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property bool shouldShow: false
    readonly property var pywal: QsServices.Pywal

    readonly property color cSurface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 0.48)
    readonly property color cSurfaceContainer: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 0.58)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
    readonly property color cHover: Qt.rgba(cText.r, cText.g, cText.b, 0.06)

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { right: 12; top: 12 }
    implicitWidth: 320
    implicitHeight: mainColumn.implicitHeight + 24
    color: "transparent"
    visible: shouldShow || container.opacity > 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "popup"

    // Device data
    property bool isFetching: false
    property bool devConnected: false
    property string devName: ""
    property string devType: ""
    property string devMac: ""
    property string devBattery: ""
    property string devRssi: ""

    // Adapter data
    property string adpMac: ""
    property string adpName: ""
    property string adpPowered: ""
    property string adpDiscoverable: ""

    function iconToType(icon) {
        if (!icon) return ""
        if (icon.includes("headset") || icon.includes("headphone")) return "Headset"
        if (icon.includes("audio")) return "Audio"
        if (icon.includes("phone")) return "Phone"
        if (icon.includes("computer") || icon.includes("laptop")) return "Computer"
        if (icon.includes("mouse")) return "Mouse"
        if (icon.includes("keyboard")) return "Keyboard"
        if (icon.includes("joystick") || icon.includes("gamepad")) return "Controller"
        if (icon.includes("printer")) return "Printer"
        return "Device"
    }

    function refresh() {
        isFetching = true
        devConnected = false; devName = ""; devType = ""; devMac = ""; devBattery = ""; devRssi = ""
        adpMac = ""; adpName = ""; adpPowered = ""; adpDiscoverable = ""
        deviceProc.running = true
        adapterProc.running = true
    }

    onShouldShowChanged: {
        if (shouldShow) {
            mouseHasEntered = false
            closeTimer.stop()
            refresh()
        }
    }

    property bool mouseHasEntered: false

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                popupWindow.mouseHasEntered = true
                closeTimer.stop()
            } else if (popupWindow.mouseHasEntered && popupWindow.shouldShow) {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 100
        onTriggered: {
            if (!hoverHandler.hovered && popupWindow.mouseHasEntered && popupWindow.shouldShow)
                popupWindow.shouldShow = false
        }
    }

    // Get connected device info via bluetoothctl
    Process {
        id: deviceProc
        command: ["sh", "-c", "mac=$(bluetoothctl devices Connected 2>/dev/null | head -1 | awk '{print $2}'); [ -n \"$mac\" ] && bluetoothctl info \"$mac\" 2>/dev/null || echo NODEVICE"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line === "NODEVICE") return
                if (line.startsWith("Device ")) {
                    popupWindow.devMac = line.split(" ")[1] || ""
                    popupWindow.devConnected = true
                } else if (line.startsWith("Alias: ")) {
                    popupWindow.devName = line.substring(7).trim()
                } else if (line.startsWith("Name: ") && !popupWindow.devName) {
                    popupWindow.devName = line.substring(6).trim()
                } else if (line.startsWith("Icon: ")) {
                    popupWindow.devType = popupWindow.iconToType(line.substring(6).trim())
                } else if (line.includes("Battery Percentage:")) {
                    const m = line.match(/\((\d+)\)/)
                    if (m) popupWindow.devBattery = m[1] + "%"
                } else if (line.startsWith("RSSI: ")) {
                    popupWindow.devRssi = line.substring(6).trim() + " dBm"
                }
            }
        }
        onExited: popupWindow.isFetching = false
    }

    // Get adapter info
    Process {
        id: adapterProc
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line.startsWith("Controller ")) {
                    popupWindow.adpMac = line.split(" ")[1] || ""
                } else if (line.startsWith("Alias: ") && !popupWindow.adpName) {
                    popupWindow.adpName = line.substring(7).trim()
                } else if (line.startsWith("Name: ") && !popupWindow.adpName) {
                    popupWindow.adpName = line.substring(6).trim()
                } else if (line.startsWith("Powered: ")) {
                    popupWindow.adpPowered = line.substring(9).trim()
                } else if (line.startsWith("Discoverable: ")) {
                    popupWindow.adpDiscoverable = line.substring(14).trim()
                }
            }
        }
    }

    Process {
        id: clipDevMacProc
        command: ["wl-copy", "--", popupWindow.devMac]
        running: false
    }

    Process {
        id: clipAdpMacProc
        command: ["wl-copy", "--", popupWindow.adpMac]
        running: false
    }

    FocusScope {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.TopRight

        states: State {
            name: "visible"
            when: popupWindow.shouldShow
            PropertyChanges { target: container; opacity: 1; scale: 1.0 }
        }

        transitions: [
            Transition {
                to: "visible"
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                }
            },
            Transition {
                from: "visible"
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { property: "scale"; to: 0.94; duration: 120 }
                }
            }
        ]

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: cSurface
            border.color: cBorder
            border.width: 1
        }

        Column {
            id: mainColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            // Header
            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "BT Info"
                    color: cPrimary
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.family: "Inter"
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28; radius: 14
                    color: refreshHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        font.pixelSize: 16
                        color: cPrimary
                        rotation: popupWindow.isFetching ? 360 : 0
                        Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }
                    }
                    HoverHandler { id: refreshHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupWindow.refresh()
                    }
                }
            }

            // ── Connected Device card ──────────────────────────────────────
            Rectangle {
                width: parent.width
                height: devCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: devCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Connected Device"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Text {
                        visible: !popupWindow.devConnected
                        text: popupWindow.isFetching ? "..." : "No device connected"
                        color: cSubText
                        font.pixelSize: 12; font.family: "Inter"
                    }

                    Row {
                        visible: popupWindow.devConnected
                        width: parent.width; spacing: 6
                        Text {
                            text: "Device"; width: 80
                            color: cSubText; font.pixelSize: 12; font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: popupWindow.devName || "..."
                            color: cText; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        visible: popupWindow.devConnected && popupWindow.devType !== ""
                        width: parent.width; spacing: 6
                        Text { text: "Type"; width: 80; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text { text: popupWindow.devType; color: cText; font.pixelSize: 12; font.family: "Inter" }
                    }

                    Row {
                        visible: popupWindow.devConnected && popupWindow.devBattery !== ""
                        width: parent.width; spacing: 6
                        Text { text: "Battery"; width: 80; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text { text: popupWindow.devBattery; color: cText; font.pixelSize: 12; font.family: "Inter" }
                    }

                    Row {
                        visible: popupWindow.devConnected && popupWindow.devRssi !== ""
                        width: parent.width; spacing: 6
                        Text { text: "Signal"; width: 80; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text { text: popupWindow.devRssi; color: cText; font.pixelSize: 12; font.family: "Inter" }
                    }

                    Row {
                        visible: popupWindow.devConnected && popupWindow.devMac !== ""
                        width: parent.width; spacing: 6
                        Text {
                            text: "Address"; width: 80
                            color: cSubText; font.pixelSize: 12; font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: popupWindow.devMac
                            color: cText; font.pixelSize: 12; font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: copyDevHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "⧉"; font.pixelSize: 11; color: cPrimary }
                            HoverHandler { id: copyDevHover }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: clipDevMacProc.running = true
                            }
                        }
                    }
                }
            }

            // ── Adapter card ──────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: adpCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: adpCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Adapter"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Row {
                        visible: popupWindow.adpName !== ""
                        width: parent.width; spacing: 6
                        Text { text: "Name"; width: 80; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text { text: popupWindow.adpName; color: cText; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text {
                            text: "Address"; width: 80
                            color: cSubText; font.pixelSize: 12; font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: popupWindow.adpMac || "..."
                            color: cText; font.pixelSize: 12; font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            visible: popupWindow.adpMac !== ""
                            color: copyAdpHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "⧉"; font.pixelSize: 11; color: cPrimary }
                            HoverHandler { id: copyAdpHover }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: clipAdpMacProc.running = true
                            }
                        }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "Powered"; width: 80; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: popupWindow.adpPowered || "..."
                            color: popupWindow.adpPowered === "yes" ? cPrimary : cText
                            font.pixelSize: 12; font.family: "Inter"
                        }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "Discoverable"; width: 80; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: popupWindow.adpDiscoverable || "..."
                            color: cText; font.pixelSize: 12; font.family: "Inter"
                        }
                    }
                }
            }
        }
    }
}
