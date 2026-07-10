import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
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

    implicitWidth: 330
    implicitHeight: mainColumn.implicitHeight + 24
    color: "transparent"
    visible: shouldShow || container.opacity > 0

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "popup"

    // ── State ─────────────────────────────────────────────────────────
    property bool privacyMode: false
    property bool isFetching: false

    property string publicIP: ""
    property string ispName: ""
    property string countryCode: ""
    property string countryName: ""
    property string regionName: ""
    property string cityName: ""
    property string statusMessage: "..."

    property bool vpnActive: false
    property string vpnInterfaceName: ""

    property string latencyMs: ""
    property string latencyError: ""

    property string localIP: ""
    property string localGateway: ""
    property string localInterface: ""

    // ── Helpers ───────────────────────────────────────────────────────
    function getFlagEmoji(code) {
        if (!code || code.length !== 2) return ""
        let upper = code.toUpperCase()
        return String.fromCodePoint(127397 + upper.charCodeAt(0), 127397 + upper.charCodeAt(1))
    }

    function fetchIPInfo() {
        isFetching = true
        statusMessage = "..."
        fetchProc0.running = true
    }

    function fetchLocalDetails() {
        localIPProc.running   = true
        gatewayProc.running   = true
        interfaceProc.running = true
    }

    function checkVPN() { vpnProc.running = true }

    function refresh() {
        checkVPN()
        fetchLocalDetails()
        fetchIPInfo()
        latencyMs = ""
        latencyError = ""
        latencyProc.running = true
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

    // ── IP fetch — provider 0: ip-api.com ─────────────────────────────
    Process {
        id: fetchProc0
        command: ["curl", "-sf", "--max-time", "8", "http://ip-api.com/json"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const d = JSON.parse(data.trim())
                    if (d.query) {
                        popupWindow.publicIP    = d.query
                        popupWindow.ispName     = d.isp || d.org || ""
                        popupWindow.countryCode = (d.countryCode || "").toLowerCase()
                        popupWindow.countryName = d.country || ""
                        popupWindow.regionName  = d.regionName || d.region || ""
                        popupWindow.cityName    = d.city || ""
                        popupWindow.isFetching  = false
                        popupWindow.statusMessage = "OK"
                        return
                    }
                } catch(e) {}
                fetchProc1.running = true
            }
        }
        onExited: (code, status) => { if (code !== 0) fetchProc1.running = true }
    }

    // ── IP fetch — provider 1: ipinfo.io ──────────────────────────────
    Process {
        id: fetchProc1
        command: ["curl", "-sf", "--max-time", "8", "https://ipinfo.io/json"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const d = JSON.parse(data.trim())
                    if (d.ip) {
                        popupWindow.publicIP    = d.ip
                        popupWindow.ispName     = d.org || ""
                        popupWindow.countryCode = (d.country || "").toLowerCase()
                        popupWindow.regionName  = d.region || ""
                        popupWindow.cityName    = d.city || ""
                        popupWindow.isFetching  = false
                        popupWindow.statusMessage = "OK"
                        return
                    }
                } catch(e) {}
                fetchProc2.running = true
            }
        }
        onExited: (code, status) => { if (code !== 0) fetchProc2.running = true }
    }

    // ── IP fetch — provider 2: freeipapi.com ──────────────────────────
    Process {
        id: fetchProc2
        command: ["curl", "-sf", "--max-time", "8", "https://freeipapi.com/api/json"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const d = JSON.parse(data.trim())
                    if (d.ipAddress) {
                        popupWindow.publicIP    = d.ipAddress
                        popupWindow.ispName     = d.asnOrganization || ""
                        popupWindow.countryCode = (d.countryCode || "").toLowerCase()
                        popupWindow.countryName = d.countryName || ""
                        popupWindow.regionName  = d.regionName || ""
                        popupWindow.cityName    = d.cityName || ""
                        popupWindow.isFetching  = false
                        popupWindow.statusMessage = "OK"
                        return
                    }
                } catch(e) {}
                popupWindow.isFetching = false
                popupWindow.statusMessage = "Error"
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                popupWindow.isFetching = false
                popupWindow.statusMessage = "Error"
            }
        }
    }

    // ── Local network ─────────────────────────────────────────────────
    Process {
        id: localIPProc
        command: ["sh", "-c", "ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i==\"src\") {print $(i+1); exit}}' || hostname -I 2>/dev/null | awk '{print $1}'"]
        running: false
        stdout: SplitParser { onRead: data => { popupWindow.localIP = data.trim() || "N/A" } }
    }

    Process {
        id: gatewayProc
        command: ["sh", "-c", "ip route | awk '/default/ {print $3; exit}'"]
        running: false
        stdout: SplitParser { onRead: data => { popupWindow.localGateway = data.trim() || "N/A" } }
    }

    Process {
        id: interfaceProc
        command: ["sh", "-c", "ip route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if($i==\"dev\") print $(i+1); exit}'"]
        running: false
        stdout: SplitParser { onRead: data => { popupWindow.localInterface = data.trim() || "N/A" } }
    }

    // ── VPN detection ─────────────────────────────────────────────────
    Process {
        id: vpnProc
        command: ["sh", "-c", "ls /sys/class/net | grep -E '^(tun|tap|wg|ppp|proton|tailscale|zero|vpn|cscotun)' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const iface = data.trim()
                popupWindow.vpnActive = iface !== ""
                popupWindow.vpnInterfaceName = iface
            }
        }
        onExited: (code, status) => { if (code !== 0) popupWindow.vpnActive = false }
    }

    // ── Latency ───────────────────────────────────────────────────────
    Process {
        id: latencyProc
        command: ["ping", "-c", "1", "-W", "2", "8.8.8.8"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const m = data.match(/time=([\d.]+)\s*ms/)
                if (m) popupWindow.latencyMs = m[1] + " ms"
            }
        }
        onExited: (code, status) => { if (code !== 0) popupWindow.latencyError = "Timeout" }
    }

    // ── Clipboard ─────────────────────────────────────────────────────
    Process {
        id: clipProc
        command: ["wl-copy", "--", popupWindow.publicIP]
        running: false
    }

    Process {
        id: clipLocalProc
        command: ["wl-copy", "--", popupWindow.localIP]
        running: false
    }

    // ── Animated container ────────────────────────────────────────────
    FocusScope {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.TopRight
        focus: true

        Keys.onEscapePressed: popupWindow.shouldShow = false

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

        // ── UI ────────────────────────────────────────────────────────────
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
                    text: "IP Info" + (popupWindow.vpnActive ? "  •  VPN" : "")
                    color: popupWindow.vpnActive ? "#44cc88" : cPrimary
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.family: "Inter"
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: privacyHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                        Text { anchors.centerIn: parent; text: popupWindow.privacyMode ? "🙈" : "👁"; font.pixelSize: 13 }
                        HoverHandler { id: privacyHover }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: popupWindow.privacyMode = !popupWindow.privacyMode
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: refreshHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "↻"; font.pixelSize: 16; color: cPrimary
                            rotation: popupWindow.isFetching ? 360 : 0
                            Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }
                        }
                        HoverHandler { id: refreshHover }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: popupWindow.refresh()
                        }
                    }
                }
            }

            // ── Public Connection card ─────────────────────────────────────
            Rectangle {
                width: parent.width
                height: pubCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: pubCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Public Connection"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text {
                            text: "IP"; width: 80
                            color: cSubText
                            font.pixelSize: 12; font.family: "Inter"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: popupWindow.privacyMode ? "----" : (popupWindow.isFetching ? "..." : (popupWindow.publicIP || popupWindow.statusMessage))
                            color: cText
                            font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            visible: !popupWindow.privacyMode && popupWindow.publicIP !== ""
                            color: copyHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "⧉"; font.pixelSize: 11; color: cPrimary }
                            HoverHandler { id: copyHover }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: clipProc.running = true
                            }
                        }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text {
                            text: "ISP"; width: 80
                            color: cSubText
                            font.pixelSize: 12; font.family: "Inter"
                        }
                        Text {
                            text: popupWindow.privacyMode ? "----" : (popupWindow.ispName || "N/A")
                            color: cText; font.pixelSize: 12; font.family: "Inter"
                            width: parent.width - 80; elide: Text.ElideRight
                        }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text {
                            text: "Location"; width: 80
                            color: cSubText
                            font.pixelSize: 12; font.family: "Inter"
                        }
                        Text {
                            text: popupWindow.privacyMode ? "----" : (popupWindow.countryName ? popupWindow.countryName + (popupWindow.cityName ? " · " + popupWindow.cityName : "") : "N/A")
                            color: cText; font.pixelSize: 12; font.family: "Inter"
                            width: parent.width - 80; elide: Text.ElideRight
                        }
                    }
                }
            }

            // ── Local Network card ────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: localCol.implicitHeight + 20
                radius: 10
                color: cSurfaceContainer
                border.color: cBorder
                border.width: 1

                Column {
                    id: localCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    spacing: 8

                    Text {
                        text: "Local Network"
                        color: cPrimary
                        font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "Local IP"; width: 80; font.pixelSize: 12; font.family: "Inter"
                            color: cSubText }
                        Text { text: popupWindow.localIP || "..."; font.pixelSize: 12; font.family: "Inter"; color: cText }
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            visible: popupWindow.localIP !== ""
                            color: copyHover2.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                            Text { anchors.centerIn: parent; text: "⧉"; font.pixelSize: 11; color: cPrimary }
                            HoverHandler { id: copyHover2 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: clipLocalProc.running = true
                            }
                        }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "Gateway"; width: 80; font.pixelSize: 12; font.family: "Inter"
                            color: cSubText }
                        Text { text: popupWindow.localGateway || "..."; font.pixelSize: 12; font.family: "Inter"; color: cText }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "Interface"; width: 80; font.pixelSize: 12; font.family: "Inter"
                            color: cSubText }
                        Text { text: popupWindow.localInterface || "..."; font.pixelSize: 12; font.family: "Inter"; color: cText }
                    }

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "Latency"; width: 80; font.pixelSize: 12; font.family: "Inter"
                            color: cSubText }
                        Text {
                            text: popupWindow.latencyMs || popupWindow.latencyError || "..."
                            color: popupWindow.latencyError ? "#ff6666" : cText
                            font.pixelSize: 12; font.family: "Inter"
                        }
                    }
                }
            }
        }
    }
}
