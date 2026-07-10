// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick 6.10
import QtQuick.Layouts 6.10
import qs.services
import Qt5Compat.GraphicalEffects
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property bool shouldShow: false
    readonly property var player: Players.active
    property real currentPosition: player?.position ?? 0
    property real vinylAngle: 0
    property var cavaBars: Array(24).fill(0)

    readonly property var pywal: QsServices.Pywal
    readonly property color cPrimary: pywal.primary

    // ── Display properties (cross-fade safe) ──────────────────────
    property string displayTitle:  player?.trackTitle  ?? ""
    property string displayArtist: player?.trackArtist ?? ""
    property string displayAlbum:  player?.trackAlbum  ?? ""
    property string displayArtUrl: player?.trackArtUrl ?? ""

    // When track changes: fade info out → update → fade in
    Timer {
        id: trackSwapTimer; interval: 180
        onTriggered: {
            popupWindow.displayTitle  = player?.trackTitle  ?? ""
            popupWindow.displayArtist = player?.trackArtist ?? ""
            popupWindow.displayAlbum  = player?.trackAlbum  ?? ""
            popupWindow.displayArtUrl = player?.trackArtUrl ?? ""
            trackInfo.opacity = 1
            trackInfo.slideY  = 0
        }
    }
    Connections {
        target: player
        function onTrackTitleChanged() {
            if (!popupWindow.shouldShow) return
            trackInfo.opacity = 0
            trackInfo.slideY  = 10
            trackSwapTimer.restart()
        }
    }

    // Position update
    Timer {
        interval: 250
        running: (player?.isPlaying ?? false) && shouldShow
        repeat: true
        onTriggered: currentPosition = player?.position ?? 0
    }

    // Vinyl rotation
    Timer {
        interval: 33
        running: (player?.isPlaying ?? false) && shouldShow
        repeat: true
        onTriggered: vinylAngle = (vinylAngle + 0.79) % 360
    }

    // Content reveal animation on open
    SequentialAnimation {
        id: contentReveal
        PauseAnimation { duration: 140 }
        ParallelAnimation {
            NumberAnimation { target: mainContent; property: "opacity"; from: 0; to: 1; duration: 320; easing.type: Easing.OutQuad }
            NumberAnimation { target: mainContent; property: "slideY"; from: 22; to: 0;  duration: 400; easing.type: Easing.OutCubic }
        }
    }

    // Play/pause bounce
    NumberAnimation {
        id: playBounce
        target: playBtn; property: "scale"
        from: 1.20; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.6
    }
    Connections {
        target: player
        function onIsPlayingChanged() { if (popupWindow.shouldShow) playBounce.restart() }
    }

    visible: shouldShow && player !== null
    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins { top: 10; left: 25 }
    implicitWidth:  shouldShow ? 380 : 0
    implicitHeight: shouldShow && player ? mainContent.implicitHeight + 40 : 0
    color: "transparent"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "popup"

    Behavior on implicitWidth  { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    property bool mouseHasEntered: false
    onShouldShowChanged: {
        if (shouldShow) {
            mouseHasEntered = false
            mainContent.opacity = 0
            mainContent.slideY  = 22
            contentReveal.restart()
        }
    }
    HoverHandler {
        onHoveredChanged: {
            if (hovered) { popupWindow.mouseHasEntered = true; closeTimer.stop() }
            else if (popupWindow.mouseHasEntered) closeTimer.restart()
        }
    }
    Timer { id: closeTimer; interval: 100; onTriggered: popupWindow.shouldShow = false }

    // Cava raw output → 24 bar values 0-1
    Process {
        id: cavaProc
        command: ["sh", "-c",
            "printf '[general]\\nbars=24\\nframerate=30\\n\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=100\\nbar_delimiter=59\\nframe_delimiter=10\\n' > /tmp/qs_cava.cfg && cava -p /tmp/qs_cava.cfg"
        ]
        running: popupWindow.shouldShow
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(";").filter(v => v !== "")
                if (parts.length >= 20)
                    popupWindow.cavaBars = parts.slice(0, 24).map(v => {
                        const n = parseInt(v); return isNaN(n) ? 0 : Math.min(1, n / 100)
                    })
            }
        }
    }

    function formatTime(s) {
        if (!s || s <= 0) return "0:00"
        const m = Math.floor(s / 60), sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    // Outer rounded clip
    Rectangle {
        id: outerRect
        anchors.fill: parent
        radius: 20
        clip: true
        color: pywal.surfaceContainerHighest
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width:  outerRect.width
                height: outerRect.height
                radius: 20
            }
        }

        // Blurred album art background
        Item {
            anchors.fill: parent
            Image {
                id: bgImage
                anchors.centerIn: parent
                width: parent.width + 120; height: parent.height + 120
                source: displayArtUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true
            }
            FastBlur {
                anchors.fill: bgImage; source: bgImage; radius: 72
                opacity: (bgImage.source !== "" && bgImage.status === Image.Ready) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.60) }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * 0.45
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.28) }
            }
        }

        // Main content (animated in on open)
        Column {
            id: mainContent
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 14
            visible: player !== null
            opacity: 0
            property real slideY: 22
            transform: Translate { y: mainContent.slideY }
            Behavior on opacity { NumberAnimation { duration: 280 } }
            Behavior on slideY  { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

            // Vinyl disc
            Item {
                width: parent.width; height: 210

                // Glow ring (pulses while playing)
                Rectangle {
                    id: vinylGlow
                    anchors.centerIn: parent
                    width: 228; height: 228; radius: 114
                    color: "transparent"
                    border.width: 3
                    border.color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, glowA)
                    property real glowA: 0
                    SequentialAnimation {
                        running: (player?.isPlaying ?? false) && shouldShow
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) vinylGlow.glowA = 0
                        NumberAnimation { target: vinylGlow; property: "glowA"; to: 0.45; duration: 1500; easing.type: Easing.OutSine }
                        NumberAnimation { target: vinylGlow; property: "glowA"; to: 0.05; duration: 1500; easing.type: Easing.InSine }
                    }
                }

                // Outer soft glow halo
                Rectangle {
                    anchors.centerIn: parent
                    width: 246; height: 246; radius: 123
                    color: "transparent"
                    border.width: 8
                    border.color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, vinylGlow.glowA * 0.18)
                }

                Item {
                    id: vinylDisc
                    width: 210; height: 210
                    anchors.centerIn: parent
                    rotation: vinylAngle

                    Rectangle {
                        anchors.fill: parent; radius: 105; color: "#0c0c0c"
                        Repeater {
                            model: 8
                            Rectangle {
                                anchors.centerIn: parent
                                width: 210 - index * 22; height: 210 - index * 22
                                radius: (210 - index * 22) / 2
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, Math.max(0, 0.07 - index * 0.008))
                                border.width: 1
                            }
                        }
                    }

                    Item {
                        anchors.centerIn: parent; width: 150; height: 150
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 150; height: 150; radius: 75 }
                        }
                        Image {
                            anchors.fill: parent; source: displayArtUrl
                            fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
                        }
                        Rectangle {
                            anchors.fill: parent; radius: 75
                            color: displayArtUrl ? "transparent" : Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.25)
                            Text {
                                anchors.centerIn: parent; visible: !displayArtUrl
                                text: "󰎇"; font.family: "Material Design Icons"
                                font.pixelSize: 48; color: Qt.rgba(1, 1, 1, 0.4)
                            }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent; width: 20; height: 20; radius: 10
                        color: "#1c1c1c"; border.color: Qt.rgba(1,1,1,0.20); border.width: 1
                        Rectangle {
                            anchors.centerIn: parent; width: 7; height: 7; radius: 3.5
                            color: Qt.rgba(1,1,1,0.28)
                        }
                    }
                }
            }

            // Track info (cross-fades on track change)
            Column {
                id: trackInfo
                width: parent.width; spacing: 6
                opacity: 1
                property real slideY: 0
                transform: Translate { y: trackInfo.slideY }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                Behavior on slideY  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Item {
                    width: parent.width; height: 22
                    Row {
                        id: barsRow
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        spacing: 3
                        Repeater {
                            model: 3
                            Rectangle {
                                width: 3; radius: 1.5; color: cPrimary
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                SequentialAnimation on height {
                                    running: (player?.isPlaying ?? false) && shouldShow
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 170 }
                                    NumberAnimation { to: 18; duration: 400; easing.type: Easing.OutQuad }
                                    NumberAnimation { to: 4;  duration: 400; easing.type: Easing.InQuad }
                                }
                            }
                        }
                    }
                    Text {
                        anchors { left: barsRow.right; leftMargin: 8; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: displayTitle; color: "white"
                        font.pixelSize: 15; font.weight: Font.Bold; font.family: "Inter"
                        elide: Text.ElideRight
                    }
                }

                Text {
                    width: parent.width; text: displayArtist
                    color: Qt.rgba(1,1,1,0.68); font.pixelSize: 12; font.family: "Inter"
                    elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    width: parent.width; text: displayAlbum
                    color: Qt.rgba(1,1,1,0.38); font.pixelSize: 11; font.family: "Inter"
                    elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                }
            }

            // Progress + time
            Column {
                width: parent.width; spacing: 6
                Item {
                    width: parent.width; height: 18
                    Rectangle {
                        id: progressTrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Qt.rgba(1,1,1,0.15)
                        Rectangle {
                            id: progressFill
                            width: (player && player.length > 0)
                                   ? parent.width * Math.min(1, currentPosition / player.length) : 0
                            height: parent.height; radius: 2; color: cPrimary
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(progressFill.width - width/2, progressTrack.width - width))
                            width: 14; height: 14; radius: 7; color: "white"
                            visible: seekArea.containsMouse || seekArea.pressed
                            Behavior on x { NumberAnimation { duration: 80 } }
                        }
                    }
                    MouseArea {
                        id: seekArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (player && player.length > 0)
                                player.position = Math.max(0, Math.min(1, mouseX / progressTrack.width)) * player.length
                        }
                        onPositionChanged: mouse => {
                            if (pressed && player && player.length > 0)
                                player.position = Math.max(0, Math.min(1, mouseX / progressTrack.width)) * player.length
                        }
                    }
                }
                Item {
                    width: parent.width; height: 14
                    Text { text: formatTime(currentPosition); color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.family: "Inter" }
                    Text { anchors.right: parent.right; text: formatTime(player?.length ?? 0); color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.family: "Inter" }
                }
            }

            // ── Cava visualiser ───────────────────────────────────
            Canvas {
                id: vizCanvas
                width: parent.width; height: 56

                Timer {
                    interval: 33; repeat: true; running: popupWindow.shouldShow
                    onTriggered: vizCanvas.requestPaint()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    const bars = popupWindow.cavaBars
                    const n = Math.min(bars.length, 24)
                    if (n === 0) return
                    const sp = 3
                    const bw = (width - (n - 1) * sp) / n
                    const mid = height / 2
                    const r = Math.round(cPrimary.r * 255)
                    const g = Math.round(cPrimary.g * 255)
                    const b = Math.round(cPrimary.b * 255)
                    for (let i = 0; i < n; i++) {
                        const bv = Math.max(0, Math.min(1, bars[i] ?? 0))
                        const x = i * (bw + sp)
                        const h = Math.max(2, mid * bv)
                        // top half
                        const gt = ctx.createLinearGradient(x, mid, x, mid - h)
                        gt.addColorStop(0, `rgba(${r},${g},${b},0.88)`)
                        gt.addColorStop(1, `rgba(${r},${g},${b},0.10)`)
                        ctx.fillStyle = gt
                        ctx.fillRect(x, mid - h, bw, h)
                        // bottom half (mirror)
                        const gb = ctx.createLinearGradient(x, mid, x, mid + h)
                        gb.addColorStop(0, `rgba(${r},${g},${b},0.88)`)
                        gb.addColorStop(1, `rgba(${r},${g},${b},0.10)`)
                        ctx.fillStyle = gb
                        ctx.fillRect(x, mid, bw, h)
                    }
                }
            }

            // Controls
            Item {
                width: parent.width; height: 64

                Rectangle {
                    width: 38; height: 38; radius: 19
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    color: shuffleMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: shuffleMouse.pressed ? 0.86 : 1; Behavior on scale { NumberAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent; text: "󰒝"
                        font.family: "Material Design Icons"; font.pixelSize: 18
                        color: (player?.shuffle ?? false) ? cPrimary : Qt.rgba(1,1,1,0.42)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: shuffleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (player) player.shuffle = !(player.shuffle ?? false) }
                    }
                }

                Rectangle {
                    width: 46; height: 46; radius: 23
                    anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -68 }
                    color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: prevMouse.pressed ? 0.86 : 1; Behavior on scale { NumberAnimation { duration: 80 } }
                    Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Material Design Icons"; font.pixelSize: 24; color: "white" }
                    MouseArea {
                        id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (player && player.canGoPrevious) player.previous() }
                    }
                }

                Rectangle {
                    id: playBtn
                    width: 62; height: 62; radius: 31
                    anchors.centerIn: parent
                    color: playMouse.containsMouse ? Qt.lighter(cPrimary, 1.12) : cPrimary
                    Behavior on color { ColorAnimation { duration: 150 } }
                    // scale managed by playBounce animation + press
                    scale: playMouse.pressed ? 0.88 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 10; height: parent.height + 10; radius: width/2
                        color: "transparent"; z: -1
                        border.width: 2
                        border.color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, playMouse.containsMouse ? 0.40 : 0)
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (player?.isPlaying ?? false) ? 0 : 2
                        text: (player?.isPlaying ?? false) ? "󰏤" : "󰐊"
                        font.family: "Material Design Icons"; font.pixelSize: 28; color: "white"
                    }
                    MouseArea {
                        id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (player && player.canTogglePlaying) player.togglePlaying() }
                    }
                }

                Rectangle {
                    width: 46; height: 46; radius: 23
                    anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: 68 }
                    color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: nextMouse.pressed ? 0.86 : 1; Behavior on scale { NumberAnimation { duration: 80 } }
                    Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Material Design Icons"; font.pixelSize: 24; color: "white" }
                    MouseArea {
                        id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (player && player.canGoNext) player.next() }
                    }
                }

                Rectangle {
                    width: 38; height: 38; radius: 19
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    color: repeatMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: repeatMouse.pressed ? 0.86 : 1; Behavior on scale { NumberAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: (player?.loopStatus ?? 0) === 2 ? "󰑘" : "󰑖"
                        font.family: "Material Design Icons"; font.pixelSize: 18
                        color: (player?.loopStatus ?? 0) > 1 ? cPrimary : Qt.rgba(1,1,1,0.42)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: repeatMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!player) return
                            const s = player.loopStatus ?? 0
                            if (s <= 1)       player.loopStatus = 3
                            else if (s === 3) player.loopStatus = 2
                            else              player.loopStatus = 1
                        }
                    }
                }
            }

            // Volume
            Row {
                width: parent.width; spacing: 8
                Text {
                    text: "󰕿"; font.family: "Material Design Icons"; font.pixelSize: 16
                    color: Qt.rgba(1,1,1,0.42); anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    width: parent.width - 50; height: 20; anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        id: volTrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2; color: Qt.rgba(1,1,1,0.15)
                        Rectangle {
                            width: parent.width * Math.min(1, player?.volume ?? 1)
                            height: parent.height; radius: 2; color: Qt.rgba(1,1,1,0.55)
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: volTrack.width * Math.min(1, player?.volume ?? 1) - width/2
                            width: 12; height: 12; radius: 6; color: "white"
                            visible: volMouse.containsMouse || volMouse.pressed
                        }
                    }
                    MouseArea {
                        id: volMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => { if (player) player.volume = Math.max(0, Math.min(1, mouseX / volTrack.width)) }
                        onPositionChanged: mouse => { if (pressed && player) player.volume = Math.max(0, Math.min(1, mouseX / volTrack.width)) }
                    }
                }
                Text {
                    text: "󰕾"; font.family: "Material Design Icons"; font.pixelSize: 16
                    color: Qt.rgba(1,1,1,0.42); anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

    }
}
