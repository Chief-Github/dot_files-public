// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
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
    readonly property color cWarn: pywal.warning
    readonly property color cError: pywal.error

    // Fetched-on-open sensor data
    property real nvmeTemp: -1
    property real wifiTemp: -1
    property real acpiTemp: -1
    property var fanData: []
    property var diskData: []
    property real homeBytes: -1  // -1 = not yet loaded, -2 = calculating
    property var ramData: ({used: 0, total: 1, pct: 0})
    property var batteryData: null

    readonly property var rootDiskEntry: {
        for (var i = 0; i < diskData.length; i++)
            if (diskData[i].mount === "/") return diskData[i]
        return null
    }
    readonly property bool homeIsSeparate: {
        for (var i = 0; i < diskData.length; i++)
            if (diskData[i].mount === "/home") return true
        return false
    }

    function tempColor(t) {
        if (t < 0) return cSubText
        if (t > 80) return cError
        if (t > 65) return cWarn
        return cText
    }

    function fmtTime(min) {
        if (min < 0) return "—"
        const h = Math.floor(min / 60), m = min % 60
        if (h > 0 && m > 0) return h + "h " + m + "m"
        if (h > 0) return h + "h"
        return m + "m"
    }

    function battColor(status, cap) {
        if (status === "Charging" || status === "Full") return cPrimary
        if (cap <= 15) return cError
        if (cap <= 30) return cWarn
        return cPrimary
    }

    function diskColor(pct) {
        if (pct > 85) return cError
        if (pct > 70) return cWarn
        return cPrimary
    }

    function fmtBytes(b) {
        const tb = b / 1e12, gb = b / 1e9, mb = b / 1e6
        if (tb >= 1) return (Math.round(tb * 10) / 10) + " TB"
        if (gb >= 1) return (Math.round(gb * 10) / 10) + " GB"
        return Math.round(mb) + " MB"
    }

    function refreshSensors() {
        nvmeTempProc.running = true
        wifiTempProc.running = true
        acpiTempProc.running = true
        fanProc.buffer = []
        fanProc.running = true
        ramProc.running = true
        battProc.running = true
    }

    function refresh() {
        refreshSensors()
        diskData = []
        dfProc.buffer = []
        dfProc.running = true
        homeBytes = -2
        homeSizeProc.running = true
    }

    Timer {
        interval: 500
        repeat: true
        running: popupWindow.shouldShow
        onTriggered: popupWindow.refreshSensors()
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

    // NVMe temp from sysfs
    Process {
        id: nvmeTempProc
        command: ["sh", "-c", "f=$(grep -rl nvme /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1); [ -n \"$f\" ] && cat \"${f%name}temp1_input\" 2>/dev/null || echo -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                popupWindow.nvmeTemp = v > 0 ? v / 1000 : -1
            }
        }
    }

    // WiFi temp from sysfs
    Process {
        id: wifiTempProc
        command: ["sh", "-c", "f=$(grep -rl iwl /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1); [ -n \"$f\" ] && cat \"${f%name}temp1_input\" 2>/dev/null || echo -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                popupWindow.wifiTemp = v > 0 ? v / 1000 : -1
            }
        }
    }

    // ACPI / motherboard temp from sysfs
    Process {
        id: acpiTempProc
        command: ["sh", "-c", "f=$(grep -rl acpitz /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1); [ -n \"$f\" ] && cat \"${f%name}temp1_input\" 2>/dev/null || echo -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                popupWindow.acpiTemp = v > 0 ? v / 1000 : -1
            }
        }
    }

    // Fan speeds — skip zeros/dummies (threshold 100 RPM)
    Process {
        id: fanProc
        property var buffer: []
        command: ["sh", "-c", "i=1; for d in /sys/class/hwmon/hwmon*/; do for f in \"$d\"fan*_input; do [ -f \"$f\" ] || continue; rpm=$(cat \"$f\" 2>/dev/null); [ \"${rpm:-0}\" -gt 100 ] 2>/dev/null || continue; echo \"Fan $i:$rpm\"; i=$((i+1)); done; done"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(":")
                if (parts.length >= 2)
                    fanProc.buffer = fanProc.buffer.concat([{label: parts[0], rpm: parseInt(parts[1])}])
            }
        }
        onExited: { popupWindow.fanData = fanProc.buffer; fanProc.buffer = [] }
    }

    // Disk usage — only real partitions > 1 GB
    Process {
        id: dfProc
        property var buffer: []
        command: ["sh", "-c", "df -B1 -x tmpfs -x devtmpfs -x squashfs --output=target,size,used 2>/dev/null | awk 'NR>1 && $2+0>1073741824 {print $1, $2, $3}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    const total = parseInt(parts[1]), used = parseInt(parts[2])
                    if (total > 0)
                        dfProc.buffer = dfProc.buffer.concat([{mount: parts[0], total, used, pct: Math.round(used / total * 100)}])
                }
            }
        }
        onExited: { popupWindow.diskData = dfProc.buffer; dfProc.buffer = [] }
    }

    // /home directory size (only meaningful when /home isn't a separate partition)
    Process {
        id: homeSizeProc
        command: ["sh", "-c", "du -sxb /home 2>/dev/null | cut -f1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                popupWindow.homeBytes = v > 0 ? v : -1
            }
        }
        onExited: { if (popupWindow.homeBytes === -2) popupWindow.homeBytes = -1 }
    }

    // RAM usage from /proc/meminfo via free
    Process {
        id: ramProc
        command: ["sh", "-c", "free -b | awk '/^Mem:/{print $2, $2-$7}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 2) {
                    const total = parseInt(parts[0]), used = parseInt(parts[1])
                    if (total > 0)
                        popupWindow.ramData = {used, total, pct: Math.round(used / total * 100)}
                }
            }
        }
    }

    // Battery info from sysfs — handles both energy-based (µWh/µW) and charge-based (µAh/µA)
    Process {
        id: battProc
        command: ["sh", "-c", "d=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -z \"$d\" ] && exit 0; st=$(cat \"$d/status\" 2>/dev/null || echo Unknown); cap=$(cat \"$d/capacity\" 2>/dev/null || echo 0); cy=$(cat \"$d/cycle_count\" 2>/dev/null || echo -1); if [ -f \"$d/energy_now\" ]; then now=$(cat \"$d/energy_now\" 2>/dev/null || echo 0); full=$(cat \"$d/energy_full\" 2>/dev/null || echo 0); des=$(cat \"$d/energy_full_design\" 2>/dev/null || echo 0); rate=$(cat \"$d/power_now\" 2>/dev/null || echo 0); echo \"$st|$cap|$now|$full|$des|$rate|$cy|1|0\"; else now=$(cat \"$d/charge_now\" 2>/dev/null || echo 0); full=$(cat \"$d/charge_full\" 2>/dev/null || echo 0); des=$(cat \"$d/charge_full_design\" 2>/dev/null || echo 0); rate=$(cat \"$d/current_now\" 2>/dev/null || echo 0); volts=$(cat \"$d/voltage_now\" 2>/dev/null || echo 0); echo \"$st|$cap|$now|$full|$des|$rate|$cy|0|$volts\"; fi"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split("|")
                if (p.length < 8) return
                const status = p[0], cap = parseInt(p[1]) || 0
                const now = parseInt(p[2]) || 0, full = parseInt(p[3]) || 0
                const design = parseInt(p[4]) || 0, rate = parseInt(p[5]) || 0
                const cycles = parseInt(p[6]) || -1
                const isEnergy = p[7] === "1"
                const voltageUV = parseInt(p[8]) || 0

                const health = design > 0 ? Math.round(full / design * 100) : -1
                const powerW = isEnergy ? rate / 1e6 : (rate / 1e6) * (voltageUV / 1e6)

                let timeMin = -1
                if (rate > 1000) {
                    if (status === "Discharging" && now > 0)
                        timeMin = Math.round(now / rate * 60)
                    else if (status === "Charging" && full > now)
                        timeMin = Math.round((full - now) / rate * 60)
                }

                popupWindow.batteryData = {status, cap, health, powerW, timeMin, cycles}
            }
        }
    }

    component CircularGauge: Item {
        id: gauge
        width: 88; height: 106

        property real value: 0        // 0.0–1.0
        property color fillCol: cPrimary
        property string centerText: Math.round(value * 100) + "%"
        property string label: ""
        property string sublabel: ""

        onValueChanged: arc.requestPaint()
        onFillColChanged: arc.requestPaint()

        Canvas {
            id: arc
            width: 76; height: 76
            anchors.horizontalCenter: parent.horizontalCenter
            Component.onCompleted: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx = width / 2, cy = height / 2, r = cx - 7
                ctx.lineWidth = 6
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.strokeStyle = Qt.rgba(gauge.fillCol.r, gauge.fillCol.g, gauge.fillCol.b, 0.15).toString()
                ctx.stroke()
                if (gauge.value > 0.001) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + gauge.value * Math.PI * 2)
                    ctx.strokeStyle = gauge.fillCol.toString()
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }

        Text {
            anchors.centerIn: arc
            text: gauge.centerText
            color: gauge.fillCol
            font.pixelSize: 13; font.weight: Font.Bold; font.family: "Inter"
        }

        Column {
            anchors { top: arc.bottom; topMargin: 5; horizontalCenter: parent.horizontalCenter }
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.label
                color: cSubText; font.pixelSize: 11; font.family: "Inter"
            }
            Text {
                visible: gauge.sublabel !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.sublabel
                color: cSubText; font.pixelSize: 10; font.family: "Inter"
            }
        }
    }

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { right: 12; top: 12 }
    implicitWidth: 320
    implicitHeight: mainColumn.implicitHeight + 24
    color: "transparent"
    visible: shouldShow || container.opacity > 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "popup"

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
                    text: "System Info"
                    color: cPrimary
                    font.pixelSize: 13; font.weight: Font.Bold; font.family: "Inter"
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28; radius: 14
                    color: refreshHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                    Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: 16; color: cPrimary }
                    HoverHandler { id: refreshHover }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: popupWindow.refresh()
                    }
                }
            }

            // ── Temperatures card ─────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: tempCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: tempCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Temperatures"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "CPU"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: Math.round(SystemUsage.cpuTemp) + "°C  ·  " + Math.round(SystemUsage.cpuPerc * 100) + "%"
                            color: tempColor(SystemUsage.cpuTemp)
                            font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                        }
                    }

                    Row {
                        visible: popupWindow.acpiTemp >= 0
                        width: parent.width; spacing: 6
                        Text { text: "System"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: Math.round(popupWindow.acpiTemp) + "°C"
                            color: tempColor(popupWindow.acpiTemp)
                            font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                        }
                    }

                    Row {
                        visible: popupWindow.nvmeTemp >= 0
                        width: parent.width; spacing: 6
                        Text { text: "NVMe"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: Math.round(popupWindow.nvmeTemp) + "°C"
                            color: tempColor(popupWindow.nvmeTemp)
                            font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                        }
                    }

                    Row {
                        visible: popupWindow.wifiTemp >= 0
                        width: parent.width; spacing: 6
                        Text { text: "WiFi Adapter"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: Math.round(popupWindow.wifiTemp) + "°C"
                            color: tempColor(popupWindow.wifiTemp)
                            font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                        }
                    }

                    Repeater {
                        model: popupWindow.fanData
                        Row {
                            required property var modelData
                            width: tempCol.width; spacing: 6
                            Text { text: modelData.label; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                            Text {
                                text: modelData.rpm + " RPM"
                                color: cText; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            // ── Resources card ───────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: resourcesCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: resourcesCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 10

                    Text {
                        text: "Resources"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 32

                        CircularGauge {
                            value: SystemUsage.cpuPerc
                            fillCol: diskColor(Math.round(SystemUsage.cpuPerc * 100))
                            label: "CPU"
                            sublabel: Math.round(SystemUsage.cpuTemp) + "°C"
                        }

                        CircularGauge {
                            value: popupWindow.ramData.pct / 100
                            fillCol: diskColor(popupWindow.ramData.pct)
                            label: "RAM"
                            sublabel: fmtBytes(popupWindow.ramData.used)
                        }
                    }
                }
            }

            // ── Top Processes card ───────────────────────────────────────
            Rectangle {
                width: parent.width
                height: procsCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: procsCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Top Processes"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: SystemUsage.topProcesses.slice(0, 3)

                            Rectangle {
                                id: procChip
                                required property var modelData
                                property color accentCol: diskColor(Math.min(modelData.cpu, 100))
                                width: (procsCol.width - 16) / 3
                                height: 44; radius: 8
                                color: Qt.rgba(cText.r, cText.g, cText.b, 0.06)
                                border.color: Qt.rgba(accentCol.r, accentCol.g, accentCol.b, 0.25)
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name.split('/').pop()
                                        color: cSubText
                                        font.pixelSize: 10; font.family: "Inter"
                                        width: procChip.width - 12
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.cpu.toFixed(1) + "%"
                                        color: accentCol
                                        font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Battery card ──────────────────────────────────────────────
            Rectangle {
                visible: popupWindow.batteryData !== null
                width: parent.width
                height: battCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: battCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    // Header row: title + status
                    Item {
                        width: parent.width; height: 14
                        Text {
                            text: "Battery"
                            color: cPrimary
                            font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                        }
                        Text {
                            anchors.right: parent.right
                            text: popupWindow.batteryData ? popupWindow.batteryData.status : ""
                            color: popupWindow.batteryData
                                ? battColor(popupWindow.batteryData.status, popupWindow.batteryData.cap)
                                : cSubText
                            font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                        }
                    }

                    // Charge bar + %
                    Column {
                        width: parent.width
                        spacing: 4
                        Row {
                            width: parent.width; spacing: 6
                            Text {
                                text: popupWindow.batteryData ? popupWindow.batteryData.cap + "%" : "—"
                                color: popupWindow.batteryData
                                    ? battColor(popupWindow.batteryData.status, popupWindow.batteryData.cap)
                                    : cSubText
                                font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 4; radius: 2
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
                            Rectangle {
                                width: parent.width * ((popupWindow.batteryData ? popupWindow.batteryData.cap : 0) / 100)
                                height: parent.height; radius: 2
                                color: popupWindow.batteryData
                                    ? battColor(popupWindow.batteryData.status, popupWindow.batteryData.cap)
                                    : cPrimary
                                opacity: 0.8
                            }
                        }
                    }

                    // Power draw / charge rate
                    Row {
                        visible: popupWindow.batteryData && popupWindow.batteryData.powerW > 0.1
                        width: parent.width; spacing: 6
                        Text { text: "Power"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: popupWindow.batteryData
                                ? (Math.round(popupWindow.batteryData.powerW * 10) / 10) + " W"
                                : "—"
                            color: cText; font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                        }
                    }

                    // Time remaining / to full
                    Row {
                        visible: popupWindow.batteryData && popupWindow.batteryData.timeMin >= 0
                        width: parent.width; spacing: 6
                        Text {
                            text: popupWindow.batteryData && popupWindow.batteryData.status === "Charging"
                                ? "To full" : "Remaining"
                            width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter"
                        }
                        Text {
                            text: popupWindow.batteryData ? fmtTime(popupWindow.batteryData.timeMin) : "—"
                            color: cText; font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                        }
                    }

                    // Health
                    Row {
                        visible: popupWindow.batteryData && popupWindow.batteryData.health >= 0
                        width: parent.width; spacing: 6
                        Text { text: "Health"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: popupWindow.batteryData ? popupWindow.batteryData.health + "%" : "—"
                            color: popupWindow.batteryData && popupWindow.batteryData.health < 70 ? cWarn : cText
                            font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                        }
                    }

                    // Cycle count
                    Row {
                        visible: popupWindow.batteryData && popupWindow.batteryData.cycles > 0
                        width: parent.width; spacing: 6
                        Text { text: "Cycles"; width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter" }
                        Text {
                            text: popupWindow.batteryData ? popupWindow.batteryData.cycles : "—"
                            color: cText; font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                        }
                    }
                }
            }

            // ── Storage card ──────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: storageCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: storageCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Storage"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Text {
                        visible: popupWindow.diskData.length === 0
                        text: "..."
                        color: cSubText; font.pixelSize: 12; font.family: "Inter"
                    }

                    Repeater {
                        model: popupWindow.diskData

                        Column {
                            required property var modelData
                            width: storageCol.width
                            spacing: 4

                            Row {
                                width: parent.width; spacing: 6
                                Text {
                                    text: modelData.mount
                                    width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter"
                                    elide: Text.ElideMiddle
                                }
                                Text {
                                    text: fmtBytes(modelData.used) + " / " + fmtBytes(modelData.total)
                                    color: cText; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                                }
                                Text {
                                    text: modelData.pct + "%"
                                    color: diskColor(modelData.pct)
                                    font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                                }
                            }

                            // Usage bar
                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Qt.rgba(cText.r, cText.g, cText.b, 0.08)

                                Rectangle {
                                    width: parent.width * (modelData.pct / 100)
                                    height: parent.height
                                    radius: 2
                                    color: diskColor(modelData.pct)
                                    opacity: 0.7
                                }
                            }
                        }
                    }

                    // /home breakdown vs / (only when /home is not its own partition)
                    Column {
                        visible: !popupWindow.homeIsSeparate && popupWindow.rootDiskEntry !== null
                        width: storageCol.width
                        spacing: 4

                        property int homePct: popupWindow.rootDiskEntry && popupWindow.homeBytes > 0
                            ? Math.round(popupWindow.homeBytes / popupWindow.rootDiskEntry.total * 100)
                            : 0

                        Row {
                            width: parent.width; spacing: 6
                            Text {
                                text: "/home"
                                width: 90; color: cSubText; font.pixelSize: 12; font.family: "Inter"
                            }
                            Text {
                                text: popupWindow.homeBytes === -2 ? "calculating…"
                                    : popupWindow.homeBytes > 0 && popupWindow.rootDiskEntry
                                        ? fmtBytes(popupWindow.homeBytes) + " / " + fmtBytes(popupWindow.rootDiskEntry.total)
                                        : "—"
                                color: cText; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                            }
                            Text {
                                visible: popupWindow.homeBytes > 0 && popupWindow.rootDiskEntry !== null
                                text: parent.parent.homePct + "%"
                                color: diskColor(parent.parent.homePct)
                                font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            visible: popupWindow.homeBytes > 0 && popupWindow.rootDiskEntry !== null
                            width: parent.width
                            height: 4; radius: 2
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
                            Rectangle {
                                width: parent.width * (parent.parent.homePct / 100)
                                height: parent.height; radius: 2
                                color: diskColor(parent.parent.homePct)
                                opacity: 0.7
                            }
                        }
                    }
                }
            }
        }
    }
}
