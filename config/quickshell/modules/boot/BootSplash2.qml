// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick 6.10

PanelWindow {
    id: splash
    WlrLayershell.namespace: "boot"
    exclusiveZone: -1
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Overlay

    MouseArea {
        anchors.fill: parent
        onClicked: { audioProc.running = false; splash.visible = false }
    }

    Process {
        id: audioProc
        command: ["mpv", "--no-video", "--af=afade=t=in:st=0:d=3,afade=t=out:st=14:d=2.5", "/home/chief/Documents/BOOT3.wav"]
        running: false
    }

    // Play-once guard — skip on reloads
    Process {
        id: bootCheck
        command: ["/bin/sh", "-c", "test -f /tmp/.qs_boot_done && echo skip || (touch /tmp/.qs_boot_done && echo play)"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "play") {
                    audioProc.running = true
                    mainSequence.running = true
                } else {
                    splash.visible = false
                }
            }
        }
    }

    // Persistent background — stays solid while content fades
    Rectangle {
        id: solidBg
        anchors.fill: parent
        color: "#0078d4"
        z: 0
    }

    // Background colour seizure during drop
    Timer {
        id: bgSeizure
        interval: 75
        running: false
        repeat: true
        readonly property var colors: [
            "#ff0000", "#00cc00", "#0000ff", "#ffff00",
            "#ff00ff", "#00ffff", "#ffffff", "#000000",
            "#ff6600", "#0078d4", "#8800ff", "#ff0088"
        ]
        onTriggered: solidBg.color = colors[Math.floor(Math.random() * colors.length)]
    }

    Item {
        id: content
        anchors.fill: parent
        z: 1
        opacity: 0

        property bool dropping: false
        property real chromaOffset: 0

        Rectangle {
            anchors.fill: parent
            color: "#0078d4"
        }

        Rectangle {
            id: flashRect
            anchors.fill: parent
            color: "transparent"
            z: 9
        }

        // Chroma oscillation during drop
        Timer {
            interval: 50
            running: content.chromaOffset > 0
            repeat: true
            onTriggered: content.chromaOffset = Math.random() * 22 + 6
        }

        // ── BSOD layout ───────────────────────────────────────────────
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            spacing: 28
            width: 700

            // Sad face
            Item {
                id: sadFaceItem
                width: sadFaceMain.implicitWidth
                height: sadFaceMain.implicitHeight

                property real jitterX: 0
                property real jitterY: 0
                transform: Translate { x: sadFaceItem.jitterX; y: sadFaceItem.jitterY }

                Timer {
                    interval: 35
                    running: content.dropping
                    repeat: true
                    onTriggered: {
                        sadFaceItem.jitterX = (Math.random() - 0.5) * 16
                        sadFaceItem.jitterY = (Math.random() - 0.5) * 8
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -content.chromaOffset
                    text: sadFaceMain.text
                    color: "#00ffff"
                    font.pixelSize: 108; font.weight: Font.Light; font.family: "Inter"
                    opacity: content.chromaOffset > 0 ? 0.5 : 0
                }
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: content.chromaOffset
                    text: sadFaceMain.text
                    color: "#ff00ff"
                    font.pixelSize: 108; font.weight: Font.Light; font.family: "Inter"
                    opacity: content.chromaOffset > 0 ? 0.5 : 0
                }
                Text {
                    id: sadFaceMain
                    text: ":("
                    color: "white"
                    font.pixelSize: 108
                    font.weight: Font.Light
                    font.family: "Inter"
                }
            }

            // Main message
            Text {
                id: mainMsg
                property string displayed: "Your PC ran into a problem and needs to restart.\nWe're just collecting some error info, and then we'll restart for you."
                text: displayed
                color: "white"
                font.pixelSize: 20
                font.family: "Inter"
                wrapMode: Text.WordWrap
                width: parent.width
                lineHeight: 1.4

                Timer {
                    id: mainMsgScrambler
                    interval: 55
                    running: false
                    repeat: true
                    property int ticks: 0
                    onTriggered: {
                        ticks++
                        const glitch = "!@#$%^&*[]{}|<>?/\\"
                        let out = ""
                        for (let i = 0; i < mainMsg.displayed.length; i++) {
                            const c = mainMsg.displayed[i]
                            out += (c !== " " && c !== "\n" && Math.random() < 0.2)
                                ? glitch[Math.floor(Math.random() * glitch.length)]
                                : c
                        }
                        mainMsg.displayed = out
                        if (ticks > 10) {
                            mainMsgScrambler.running = false
                            mainMsg.displayed = "FUCK WINDOWS"
                            mainMsg.color = "#00ff41"
                        }
                    }
                }
            }

            // Percentage
            Text {
                id: percentText
                property real pct: 0
                text: Math.floor(pct) + "% complete"
                color: "white"
                font.pixelSize: 20
                font.family: "Inter"
            }

            // Info block
            Column {
                spacing: 6

                Text {
                    text: "For more information about this issue and possible fixes, visit"
                    color: "white"; opacity: 0.85
                    font.pixelSize: 14; font.family: "Inter"
                }
                Text {
                    text: "https://www.windows.com/stopcode"
                    color: "white"; opacity: 0.85
                    font.pixelSize: 14; font.family: "Inter"
                    font.underline: true
                }
                Item { width: 1; height: 10 }
                Text {
                    text: "If you call a support person, give them this info:"
                    color: "white"; opacity: 0.85
                    font.pixelSize: 14; font.family: "Inter"
                }
                Text {
                    id: stopCode
                    property string displayed: "CRITICAL_PROCESS_DIED"
                    property bool scrambling: false
                    property bool locked: false
                    text: "Stop code:  " + displayed
                    color: "white"
                    font.pixelSize: 14; font.family: "Inter"

                    Timer {
                        interval: 40
                        running: stopCode.scrambling && !stopCode.locked
                        repeat: true
                        property int ticks: 0
                        onTriggered: {
                            ticks++
                            const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#_"
                            let out = ""
                            for (let i = 0; i < stopCode.displayed.length; i++) {
                                const c = stopCode.displayed[i]
                                out += (c !== "_" && Math.random() < 0.3)
                                    ? chars[Math.floor(Math.random() * chars.length)]
                                    : c
                            }
                            stopCode.displayed = out
                            if (ticks > 14) {
                                stopCode.locked = true
                                stopCode.displayed = "CHIEF"
                                stopCode.color = "#00ff41"
                                stopCode.font.pixelSize = 18
                                stopCode.font.weight = Font.Bold
                            }
                        }
                    }
                }
            }
        }

        // ── Noise ─────────────────────────────────────────────────────
        Canvas {
            id: noiseCanvas
            anchors.fill: parent
            opacity: 0
            z: 3
            Timer {
                interval: 50
                running: noiseCanvas.opacity > 0
                repeat: true
                onTriggered: noiseCanvas.requestPaint()
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const count = Math.floor(width * height * 0.006)
                for (let i = 0; i < count; i++) {
                    const x = Math.random() * width
                    const y = Math.random() * height
                    const v = Math.floor(Math.random() * 200 + 55)
                    ctx.fillStyle = `rgba(${v},${v},${v},0.7)`
                    ctx.fillRect(x, y, 1, Math.random() > 0.7 ? 3 : 1)
                }
            }
        }
    }

    // ── Screen tear overlay ───────────────────────────────────────────
    // Captures content and re-renders it in horizontally-shifted strips
    ShaderEffectSource {
        id: contentCapture
        sourceItem: content
        live: true
        visible: false
    }

    Item {
        id: tearOverlay
        anchors.fill: parent
        opacity: 0
        z: 10

        readonly property int bands: 24
        readonly property real bandH: splash.height / bands

        Repeater {
            model: tearOverlay.bands
            delegate: Item {
                id: tearBand
                property real shift: 0
                y: index * tearOverlay.bandH
                width: splash.width
                height: tearOverlay.bandH + 2
                clip: true

                Timer {
                    interval: Math.floor(Math.random() * 65 + 20)
                    running: tearOverlay.opacity > 0
                    repeat: true
                    onTriggered: {
                        tearBand.shift = Math.random() < 0.65
                            ? (Math.random() - 0.5) * 140
                            : 0
                    }
                }

                ShaderEffect {
                    width: splash.width
                    height: splash.height
                    y: -(index * tearOverlay.bandH)
                    x: tearBand.shift
                    property var source: contentCapture
                }
            }
        }
    }

    // ── GPU corruption blocks ─────────────────────────────────────────
    Repeater {
        model: 10
        Rectangle {
            id: gpuBlock
            x: Math.random() * splash.width * 0.4
            y: Math.random() * splash.height
            width: Math.random() * splash.width * 0.55 + 80
            height: Math.random() * 45 + 4
            color: Qt.rgba(Math.random(), Math.random(), Math.random(), 0.75)
            visible: content.dropping
            z: 12

            Timer {
                interval: Math.floor(Math.random() * 90 + 35)
                running: gpuBlock.visible
                repeat: true
                onTriggered: {
                    gpuBlock.x      = Math.random() * splash.width * 0.4
                    gpuBlock.y      = Math.random() * splash.height
                    gpuBlock.width  = Math.random() * splash.width * 0.55 + 80
                    gpuBlock.height = Math.random() * 45 + 4
                    gpuBlock.color  = Qt.rgba(Math.random(), Math.random(), Math.random(), 0.75)
                }
            }
        }
    }

    // ── Fade-out overlay — fades in on top of everything ─────────────
    Rectangle {
        id: fadeOverlay
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        z: 50
    }

    // ── Main sequence ─────────────────────────────────────────────────
    SequentialAnimation {
        id: mainSequence
        running: false

        // BSOD fades in
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 250 }

        // Percentage ticks up unevenly
        PauseAnimation { duration: 700 }
        NumberAnimation { target: percentText; property: "pct"; from: 0;  to: 18; duration: 700;  easing.type: Easing.OutQuad }
        PauseAnimation { duration: 500 }
        NumberAnimation { target: percentText; property: "pct"; from: 18; to: 34; duration: 550;  easing.type: Easing.OutQuad }
        PauseAnimation { duration: 800 }
        NumberAnimation { target: percentText; property: "pct"; from: 34; to: 52; duration: 600;  easing.type: Easing.OutQuad }
        PauseAnimation { duration: 400 }
        NumberAnimation { target: percentText; property: "pct"; from: 52; to: 66; duration: 450;  easing.type: Easing.OutQuad }
        PauseAnimation { duration: 300 }

        // Stop code scrambles → CHIEF
        ScriptAction { script: stopCode.scrambling = true }
        PauseAnimation { duration: 650 }

        // Main message scrambles → FUCK WINDOWS
        ScriptAction { script: mainMsgScrambler.running = true }
        PauseAnimation { duration: 700 }

        // Sad face turns evil
        ScriptAction { script: sadFaceMain.text = ">:)" }
        PauseAnimation { duration: 300 }

        // Pre-drop flickers
        ScriptAction    { script: flashRect.color = "#ffffff" }
        PauseAnimation  { duration: 45 }
        ScriptAction    { script: flashRect.color = "transparent" }
        NumberAnimation { target: content; property: "opacity"; to: 0.15; duration: 35 }
        NumberAnimation { target: content; property: "opacity"; to: 1;    duration: 45 }
        ScriptAction    { script: flashRect.color = "#ff0000" }
        PauseAnimation  { duration: 40 }
        ScriptAction    { script: flashRect.color = "transparent" }
        NumberAnimation { target: content; property: "opacity"; to: 0;    duration: 30 }
        NumberAnimation { target: content; property: "opacity"; to: 1;    duration: 55 }
        ScriptAction    { script: flashRect.color = "#00ff41" }
        PauseAnimation  { duration: 50 }
        ScriptAction    { script: flashRect.color = "transparent" }

        // DROP
        ScriptAction { script: {
            noiseCanvas.opacity   = 1
            content.chromaOffset  = 20
            content.dropping      = true
            tearOverlay.opacity   = 1
            bgSeizure.running     = true
        }}

        PauseAnimation { duration: 4200 }

        ScriptAction { script: bgSeizure.running = false }
        NumberAnimation { target: fadeOverlay; property: "opacity"; to: 1; duration: 300; easing.type: Easing.InCubic }
        PauseAnimation { duration: 400 }
        ScriptAction { script: { audioProc.running = false; splash.visible = false } }
    }
}
