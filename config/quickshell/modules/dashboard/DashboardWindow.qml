// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../controlcenter/components"

PanelWindow {
    id: root

    property bool shouldShow: false

    readonly property var config: QsConfig.Config
    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var players: QsServices.Players
    readonly property var screenshot: QsServices.Screenshot
    readonly property var network: QsServices.Network
    readonly property var audio: QsServices.Audio
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var notifs: QsServices.Notifs
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var battery: UPower.displayDevice
    readonly property var weather: QsServices.Weather

    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant
    readonly property int batteryPercent: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool hasMedia: players?.active !== null
    readonly property var currentDate: time.date
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int currentDay: currentDate.getDate()
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property int calendarOffset: {
        const first = new Date(currentYear, currentMonth, 1).getDay()
        return (first + 6) % 7
    }
    readonly property int calendarDays: new Date(currentYear, currentMonth + 1, 0).getDate()
    readonly property var calendarCells: {
        const cells = []
        const prevMonthDays = new Date(currentYear, currentMonth, 0).getDate()
        for (let index = 0; index < 42; index++) {
            const dayNumber = index - calendarOffset + 1
            if (dayNumber < 1) {
                cells.push({ day: prevMonthDays + dayNumber, current: false, today: false })
            } else if (dayNumber > calendarDays) {
                cells.push({ day: dayNumber - calendarDays, current: false, today: false })
            } else {
                cells.push({ day: dayNumber, current: true, today: dayNumber === currentDay })
            }
        }
        return cells
    }

    Process {
        id: chargeCyclesProcess
        property int cycles: 0
        command: ["/bin/sh", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep 'charge-cycles' | awk '{print $2}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const n = parseInt(data.trim())
                if (!isNaN(n)) chargeCyclesProcess.cycles = n
            }
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: chargeCyclesProcess.running = true
    }

    function closeDashboard() {
        shouldShow = false
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function formatBytes(bytes) {
        if (!bytes || bytes <= 0) return "0 B"
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB"
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB"
        if (bytes >= 1024) return (bytes / 1024).toFixed(0) + " KB"
        return bytes + " B"
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.height ?? 34) + config.dashboard.margin
        left: Math.max(0, Math.round((screen.width - config.dashboard.width) / 2))
    }
    implicitWidth: config.dashboard.width
    implicitHeight: shouldShow || panel.opacity > 0 ? Math.min(config.dashboard.height, screen.height - margins.top - 24) : 0
    visible: config.dashboard.enabled && (shouldShow || panel.opacity > 0)
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        property real revealOffset: shouldShow ? 0 : -18
        scale: shouldShow ? 1.0 : 0.975
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow
        transform: Translate { y: panel.revealOffset }

        Keys.onEscapePressed: root.closeDashboard()

        Behavior on scale {
            NumberAnimation { duration: 240; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        Behavior on revealOffset {
            NumberAnimation { duration: 260; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0] }
        }

        AuroraSurface {
            anchors.fill: parent
            radius: 28
            color: root.cSurface
            strokeColor: root.cBorder
            accentColor: root.cPrimary
            elevation: 4
            highlighted: root.shouldShow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: time.format("dddd")
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            color: root.cText
                        }

                        Text {
                            text: time.format("MMMM d, yyyy  •  hh:mm")
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 12
                            color: root.cSubText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    SummaryChip {
                        Layout.fillWidth: true
                        icon: root.notifs.unreadCount > 0 ? "󰂚" : "󰂜"
                        label: root.notifs.unreadCount > 0 ? `${root.notifs.unreadCount} unread` : "Inbox clear"
                        accent: root.cPrimary
                    }

                    SummaryChip {
                        Layout.fillWidth: true
                        icon: root.network.connected ? "󰖩" : "󰖪"
                        label: root.network.connected ? (root.network.ssid || "Wi‑Fi") : "Offline"
                        accent: root.network.connected ? pywal.info : root.cSubText
                    }

                    SummaryChip {
                        Layout.fillWidth: true
                        icon: root.bluetooth.connected ? "󰂱" : "󰂲"
                        label: root.bluetooth.connected ? (root.bluetooth.deviceName || "Bluetooth") : "Bluetooth"
                        accent: root.bluetooth.connected ? pywal.secondary : root.cSubText
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 16

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 254

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Calendar"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: time.format("MMMM yyyy")
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 12
                                        color: root.cSubText
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 6
                                    columnSpacing: 6

                                    Repeater {
                                        model: root.dayLabels

                                        Text {
                                            id: dayHeader
                                            required property var modelData
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: dayHeader.modelData
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: root.cSubText
                                        }
                                    }

                                    Repeater {
                                        model: root.calendarCells

                                        Rectangle {
                                            id: dayCell
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            color: dayHover.containsMouse && dayCell.modelData.current
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, dayCell.modelData.today ? 0.28 : 0.14)
                                                : dayCell.modelData.today
                                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                                    : dayCell.modelData.current
                                                        ? "transparent"
                                                        : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.03)
                                            border.width: dayCell.modelData.today ? 1 : 0
                                            border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.36)
                                            scale: dayHover.containsMouse && dayCell.modelData.current ? 1.12 : 1.0

                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: `${dayCell.modelData.day}`
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 11
                                                font.weight: (dayCell.modelData.today || dayHover.containsMouse) ? Font.Bold : Font.Medium
                                                color: dayCell.modelData.current ? root.cText : root.cSubText
                                                opacity: dayCell.modelData.current ? 1.0 : 0.45
                                            }

                                            MouseArea {
                                                id: dayHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Controls"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.powerProfiles.isAvailable ? root.powerProfiles.getProfileLabel(root.powerProfiles.activeProfile) : "Power"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        color: root.cSubText
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    QuickAction {
                                        Layout.fillWidth: true
                                        icon: "󰄀"
                                        label: "Region"
                                        subLabel: "Screenshot"
                                        accent: root.cPrimary
                                        onClicked: root.screenshot.takeScreenshot("region")
                                    }
                                    QuickAction {
                                        Layout.fillWidth: true
                                        icon: root.screenshot.isRecording ? "󰛿" : "󰻃"
                                        label: root.screenshot.isRecording ? "Stop" : "Record"
                                        subLabel: "Screen"
                                        accent: pywal.error
                                        onClicked: {
                                            if (root.screenshot.isRecording)
                                                root.screenshot.stopRecording()
                                            else
                                                root.screenshot.startRecording()
                                        }
                                    }
                                    QuickAction {
                                        Layout.fillWidth: true
                                        icon: "󰆍"
                                        label: "Terminal"
                                        subLabel: "kitty"
                                        accent: pywal.secondary
                                        onClicked: Quickshell.execDetached("kitty") 
                                        //onClicked: Quickshell.execDetached(config.launcher.terminalCommand ?? ["kitty"])
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: root.powerProfiles.availableProfiles

                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            radius: 18
                                            color: root.powerProfiles.activeProfile === modelData
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.16)
                                                : root.cSurfaceContainerHigh
                                            border.width: 1
                                            border.color: root.powerProfiles.activeProfile === modelData
                                                ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.36)
                                                : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.05)

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.powerProfiles.getProfileLabel(modelData)
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                                color: root.powerProfiles.activeProfile === modelData ? root.cPrimary : root.cText
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.powerProfiles.setProfile(modelData)
                                            }
                                        }
                                    }
                                }

                                SurfaceMetricRow {
                                    icon: "󰂎"
                                    title: "Battery"
                                    value: `${root.batteryPercent}%`
                                    detail: battery?.state === UPowerDevice.Charging ? "Charging" : battery?.state === UPowerDevice.FullyCharged ? "Full" : "Discharging"
                                    accent: root.batteryPercent <= 20 ? pywal.error : root.cPrimary
                                }
                               // SurfaceMetricRow {
                               //     icon: root.audio.muted ? "󰖁" : "󰕾"
                               //     title: "Volume"
                               //     value: `${Math.round((root.audio.percentage ?? 0))}%`
                               //     detail: root.audio.muted ? "Muted" : "Default output"
                               //     accent: pywal.secondary
                               // }
                               // SurfaceMetricRow {
                               //     icon: root.network.connected ? "󰖩" : "󰖪"
                               //     title: "Network"
                               //     value: root.network.connected ? (root.network.ssid || "Connected") : "Disconnected"
                               //     detail: root.network.connected ? `Signal ${root.network.signalStrength}%` : "Wi‑Fi idle"
                               //     accent: pywal.info
                               // }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 16

                        SystemStats {
                            Layout.fillWidth: true
                            systemUsage: root.systemUsage
                            pywal: root.pywal
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.hasMedia ? 124 : 88

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 0
                                spacing: 0

                                Text {
                                    visible: !root.hasMedia
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 22
                                    text: "No media playing"
                                    font.family: QsConfig.Config.appearance.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: root.cSubText
                                }

                                MediaCard {
                                    visible: root.hasMedia
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    mpris: root.players
                                    pywal: root.pywal
                                }
                            }
                        }

                        SurfaceCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Today at a Glance"
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: root.cText
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.time.format("ddd")
                                        font.family: QsConfig.Config.appearance.fontFamily
                                        font.pixelSize: 11
                                        color: root.cSubText
                                    }
                                }

                                //InsightCard {
                                //    title: "CPU and memory"
                                //    body: `CPU ${'d=$(date +%j); y=$(date +%Y); t=$(date -d "$y-12-31" +%j); echo $((d*100/t))'
                                //    Layout.fillWidth: true
                                //    accent: pywal.error
                                //}
                                WeatherCard {
                                    Layout.fillWidth: true
                                }
                                
                                NetworkActivityCard {
                                    Layout.fillWidth: true
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    radius: 18
                                    implicitHeight: 74
                                    color: root.cSurfaceContainerHigh
                                    border.width: 1
                                    border.color: Qt.rgba(root.pywal.secondary.r, root.pywal.secondary.g, root.pywal.secondary.b, 0.22)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        Text {
                                            text: "󰔛"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 25
                                            color: root.pywal.secondary
                                            Layout.preferredWidth: 28
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            width: 1; height: 36
                                            
                                            color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.4)
                                        }

                                        ColumnLayout {
                                            spacing: 1

                                            Text {
                                                text: "System uptime"
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 10
                                                color: root.cSubText
                                            }

                                            Text {
                                                text: QsServices.Uptime.uptimeText
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 18
                                                font.weight: Font.Bold
                                                color: root.cText
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            width: 1; height: 36
                                            color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.4)
                                        }

                                        Text {
                                            text: "󰂎"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 22
                                            color: root.batteryPercent <= 20 ? root.pywal.error : root.cPrimary
                                            Layout.preferredWidth: 15
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            spacing: 1
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                text: chargeCyclesProcess.cycles > 0 ? "Cycles · Draw" : "Draw"
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 10
                                                color: root.cSubText
                                            }

                                            Text {
                                                text: chargeCyclesProcess.cycles > 0
                                                    ? `${chargeCyclesProcess.cycles} · ${Math.abs(root.battery?.changeRate ?? 0).toFixed(1)} W`
                                                    : `${Math.abs(root.battery?.changeRate ?? 0).toFixed(1)} W`
                                                font.family: QsConfig.Config.appearance.fontFamily
                                                font.pixelSize: 16
                                                font.weight: Font.Bold
                                                color: root.cText
                                            }
                                        }

                                    }
                                }

                                //InsightCard {
                                //    title: "Power mode"
                                //    body: root.powerProfiles.isAvailable
                                //        ? `${root.powerProfiles.getProfileLabel(root.powerProfiles.activeProfile)} profile active`
                                //        : "powerprofilesctl not available"
                                //    accent: pywal.secondary
                                //}
                            }
                        }
                    }
                }
            }
        }
    }

    component SurfaceCard: Rectangle {
        radius: 22
        color: root.cSurfaceContainer
        border.width: 1
        border.color: root.cBorder
        clip: true
    }

    component SummaryChip: Rectangle {
        id: chipRoot
        required property string icon
        required property string label
        required property color accent
        implicitWidth: chipRow.implicitWidth + 18
        height: 34
        radius: 17
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.18)

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: chipRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 15
                color: chipRoot.accent
            }
            Text {
                text: chipRoot.label
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.cText
            }
        }
    }

    component QuickAction: Rectangle {
        id: actionRoot
        required property string icon
        required property string label
        required property string subLabel
        required property color accent
        signal clicked()

        radius: 18
        color: mouse.containsMouse ? Qt.lighter(root.cSurfaceContainerHigh, 1.03) : root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(actionRoot.accent.r, actionRoot.accent.g, actionRoot.accent.b, 0.22)
        implicitHeight: 84
        scale: mouse.pressed ? 0.985 : mouse.containsMouse ? 1.01 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: actionRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: actionRoot.accent
            }
            Text {
                text: actionRoot.label
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.cText
            }
            Text {
                text: actionRoot.subLabel
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 10
                color: root.cSubText
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionRoot.clicked()
        }
    }

    component SurfaceMetricRow: Rectangle {
        id: metricRoot
        required property string icon
        required property string title
        required property string value
        required property string detail
        required property color accent
        Layout.fillWidth: true
        radius: 16
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(metricRoot.accent.r, metricRoot.accent.g, metricRoot.accent.b, 0.14)
        implicitHeight: 52

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: metricRoot.icon
                font.family: "Material Design Icons"
                font.pixelSize: 18
                color: metricRoot.accent
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: metricRoot.title
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 11
                    color: root.cSubText
                }
                Text {
                    text: metricRoot.detail
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: root.cText
                }
            }
            Text {
                text: metricRoot.value
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                color: root.cText
            }
        }
    }

    component WeatherCard: Rectangle {
        id: wcRoot

        readonly property string cond: root.weather.condition.toLowerCase()

        readonly property bool isSunny:  cond.includes("sun") || cond.includes("clear")
        readonly property bool isStormy: cond.includes("storm") || cond.includes("thunder")
        readonly property bool isRainy:  (cond.includes("rain") || cond.includes("drizzle") || cond.includes("shower")) && !isStormy
        readonly property bool isSnowy:  cond.includes("snow") || cond.includes("blizzard") || cond.includes("sleet") || cond.includes("ice")
        readonly property bool isFoggy:  cond.includes("fog") || cond.includes("mist") || cond.includes("haze")
        readonly property bool isCloudy: (cond.includes("cloud") || cond.includes("overcast")) && !isRainy && !isStormy

        readonly property color accentColor: {
            if (isSunny)  return root.pywal.warning
            if (isStormy) return root.pywal.error
            if (isRainy)  return root.pywal.info
            return root.pywal.info
        }

        radius: 18
        implicitHeight: 74
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.28)
        Behavior on border.color { ColorAnimation { duration: 600 } }

        // inner Rectangle with same radius — clip: true here clips to the rounded shape
        Rectangle {
            id: animClip
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            clip: true

            readonly property color cc: wcRoot.isStormy ? root.pywal.error : root.pywal.info

            // sun
            Item {
                visible: wcRoot.isSunny
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                anchors.rightMargin: 8
                width: 80; height: 80
                opacity: 0.14

                Rectangle {
                    anchors.centerIn: parent
                    width: 72; height: 72; radius: 36
                    color: "transparent"
                    border.color: root.pywal.warning; border.width: 1
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 15
                    color: root.pywal.warning
                }
                Item {
                    anchors.centerIn: parent
                    width: 80; height: 80
                    RotationAnimation on rotation {
                        from: 0; to: 360; duration: 24000
                        loops: Animation.Infinite; running: wcRoot.isSunny
                    }
                    Repeater {
                        model: 8
                        Rectangle {
                            property real a: index * Math.PI / 4
                            x: 40 + Math.sin(a) * 22 - 2
                            y: 40 - Math.cos(a) * 22 - 5
                            width: 4; height: 10; radius: 2
                            color: root.pywal.warning
                            rotation: index * 45
                        }
                    }
                }
            }

            // clouds
            Item {
                visible: wcRoot.isCloudy || wcRoot.isRainy || wcRoot.isStormy || wcRoot.isFoggy
                anchors.fill: parent

                Item {
                    y: 8; width: 64; height: 32; opacity: 0.15; x: -70
                    Rectangle { x: 0;  y: 14; width: 60; height: 16; radius: 8;  color: animClip.cc }
                    Rectangle { x: 6;  y: 8;  width: 22; height: 22; radius: 11; color: animClip.cc }
                    Rectangle { x: 22; y: 5;  width: 20; height: 20; radius: 10; color: animClip.cc }
                    Rectangle { x: 38; y: 10; width: 18; height: 18; radius: 9;  color: animClip.cc }
                    NumberAnimation on x { from: -70; to: animClip.width + 10; duration: 16000; loops: Animation.Infinite; running: true }
                }
                Item {
                    y: 28; width: 44; height: 22; opacity: 0.11
                    Component.onCompleted: x = animClip.width + 10
                    Rectangle { x: 0;  y: 10; width: 40; height: 11; radius: 5;  color: animClip.cc }
                    Rectangle { x: 4;  y: 4;  width: 15; height: 15; radius: 7;  color: animClip.cc }
                    Rectangle { x: 16; y: 2;  width: 14; height: 14; radius: 7;  color: animClip.cc }
                    Rectangle { x: 28; y: 6;  width: 12; height: 12; radius: 6;  color: animClip.cc }
                    NumberAnimation on x { from: animClip.width + 10; to: -50; duration: 19000; loops: Animation.Infinite; running: true }
                }
                Item {
                    y: 50; width: 52; height: 26; opacity: 0.13; x: -20
                    Rectangle { x: 0;  y: 11; width: 48; height: 14; radius: 7;  color: animClip.cc }
                    Rectangle { x: 5;  y: 5;  width: 18; height: 18; radius: 9;  color: animClip.cc }
                    Rectangle { x: 20; y: 3;  width: 16; height: 16; radius: 8;  color: animClip.cc }
                    Rectangle { x: 34; y: 7;  width: 14; height: 14; radius: 7;  color: animClip.cc }
                    NumberAnimation on x { from: -20; to: animClip.width + 20; duration: 22000; loops: Animation.Infinite; running: true }
                }
            }

            // rain
            Item {
                visible: wcRoot.isRainy || wcRoot.isStormy
                anchors.fill: parent
                opacity: 0.45
                Repeater {
                    model: 12
                    Rectangle {
                        x: (index / 12.0) * (animClip.width - 10) + 5
                        width: 1.5; height: 10; radius: 1
                        color: root.pywal.info
                        rotation: 12
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: wcRoot.isRainy || wcRoot.isStormy
                            PauseAnimation { duration: (index * 280) % 2000 }
                            NumberAnimation { from: -12; to: animClip.height + 5; duration: 480 + (index % 7) * 55; easing.type: Easing.Linear }
                        }
                    }
                }
            }

            // snow
            Item {
                visible: wcRoot.isSnowy
                anchors.fill: parent
                opacity: 0.6
                Repeater {
                    model: 10
                    Item {
                        property real xBase: (index / 10.0) * (animClip.width - 12) + 6
                        x: xBase; width: 4; height: 4
                        Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: "white" }
                        SequentialAnimation on y {
                            loops: Animation.Infinite; running: wcRoot.isSnowy
                            PauseAnimation { duration: index * 380 }
                            NumberAnimation { from: -5; to: animClip.height + 5; duration: 2400 + index * 200; easing.type: Easing.Linear }
                        }
                        SequentialAnimation on x {
                            loops: Animation.Infinite; running: wcRoot.isSnowy
                            NumberAnimation { from: xBase - 5; to: xBase + 5; duration: 1600 + index * 140; easing.type: Easing.InOutSine }
                            NumberAnimation { from: xBase + 5; to: xBase - 5; duration: 1600 + index * 140; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            // lightning flash
            Rectangle {
                visible: wcRoot.isStormy
                anchors.fill: parent
                color: Qt.rgba(root.pywal.warning.r, root.pywal.warning.g, root.pywal.warning.b, 0.12)
                opacity: 0
                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: wcRoot.isStormy
                    PauseAnimation { duration: 5200 }
                    NumberAnimation { to: 1;   duration: 35 }
                    NumberAnimation { to: 0;   duration: 70 }
                    NumberAnimation { to: 0.7; duration: 35 }
                    NumberAnimation { to: 0;   duration: 110 }
                }
            }

            // fog
            Item {
                visible: wcRoot.isFoggy
                anchors.fill: parent
                Repeater {
                    model: 3
                    Rectangle {
                        y: 8 + index * 28
                        width: animClip.width * 1.2; height: 16; radius: 8
                        color: Qt.rgba(root.pywal.onSurfaceMuted.r, root.pywal.onSurfaceMuted.g, root.pywal.onSurfaceMuted.b, 0.18)
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite; running: wcRoot.isFoggy
                            NumberAnimation { to: 1.0; duration: 2800 + index * 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.3; duration: 2800 + index * 700; easing.type: Easing.InOutSine }
                        }
                        SequentialAnimation on x {
                            loops: Animation.Infinite; running: wcRoot.isFoggy
                            NumberAnimation { from: -15; to: 20; duration: 7000 + index * 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 20; to: -15; duration: 7000 + index * 2000; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        // content
        RowLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 12

            ColumnLayout {
                spacing: 1
                Text {
                    text: root.weather.icon
                    font.family: "Material Design Icons"
                    font.pixelSize: 22
                    color: wcRoot.accentColor
                    Behavior on color { ColorAnimation { duration: 500 } }
                }
                Text {
                    text: root.weather.temperature
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: root.cText
                }
            }

            Rectangle {
                width: 1; height: 36
                color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.35)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: root.weather.condition
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: root.cText
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: "Humidity  " + root.weather.humidity
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 10
                    color: root.cSubText
                }
            }
        }
    }

    component NetworkActivityCard: Rectangle {
        id: netRoot

        function fmtSpeed(bps) {
            if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
            if (bps >= 1024)    return (bps / 1024).toFixed(0) + " KB/s"
            return (bps > 0 ? bps.toFixed(0) : "0") + " B/s"
        }

        radius: 18
        implicitHeight: 80
        clip: true
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(root.pywal.info.r, root.pywal.info.g, root.pywal.info.b, 0.2)

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 10; topMargin: 10; bottomMargin: 10 }
            spacing: 10

            // speeds column
            ColumnLayout {
                spacing: 2
                Layout.preferredWidth: 90

                Text {
                    text: "Network"
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: root.pywal.info
                }

                ColumnLayout {
                    spacing: 3

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "↓"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.pywal.success
                        }
                        Text {
                            text: netRoot.fmtSpeed(root.systemUsage.downloadSpeed)
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 10
                            color: root.cText
                        }
                    }

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "↑"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.pywal.info
                        }
                        Text {
                            text: netRoot.fmtSpeed(root.systemUsage.uploadSpeed)
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 10
                            color: root.cText
                        }
                    }
                }

                Rectangle {
                    width: 80; height: 1
                    color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.4)
                }

                Text {
                    text: `↓ ${root.formatBytes(root.systemUsage.lastRxBytes)} · ↑ ${root.formatBytes(root.systemUsage.lastTxBytes)}`
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 9
                    color: root.cSubText
                }
            }

            // graph
            NetworkGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                dataPoints: root.systemUsage.networkHistory
                downloadColor: root.pywal.success
                uploadColor: root.pywal.info
                showGrid: true
                lineWidth: 1.5
                gradientOpacity: 0.18
            }
        }
    }

    component InsightCard: Rectangle {
        id: insightRoot
        required property string title
        required property string body
        required property color accent
        radius: 18
        color: root.cSurfaceContainerHigh
        border.width: 1
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
        implicitHeight: 74

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4
            Text {
                text: insightRoot.title
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: insightRoot.accent
            }
            Text {
                text: insightRoot.body
                wrapMode: Text.WordWrap
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 11
                color: root.cText
            }
        }
    }
}
