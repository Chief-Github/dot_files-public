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
        command: ["mpv", "--no-video", "--af=afade=t=in:st=0:d=3,afade=t=out:st=14:d=2.5", "/home/chief/Documents/boot_2wav.wav"]
        running: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: 0
    }

    Item {
        id: content
        anchors.fill: parent
        z: 1

        property real chromaOffset: 0
        property bool jittering: false

        Rectangle {
            id: flashRect
            anchors.fill: parent
            color: "transparent"
            z: 9
        }
        // Chroma oscillation during drop
        Timer {
            interval: 60
            running: content.chromaOffset > 0
            repeat: true
            onTriggered: content.chromaOffset = Math.random() * 28 + 8
        }

        // ── Terminal + CHIEF centered block ──────────────────────────
        Column {
            anchors.centerIn: parent
            spacing: 40

            Column {
                id: terminal
                spacing: 6

                property var lines: [
                    "CHIEF SYSTEMS — BIOS v2.4.1",
                    "Initializing kernel modules .............. [OK]",
                    "Loading cryptographic subsystem ......... [OK]",
                    "Mounting encrypted volumes .............. [OK]",
                    "Speeding to boot .............. [OK]",
                    "> exec /boot/chief.sh --mode=stealth",
                    "0xDEAD  0xBEEF  0xCAFE  0xBABE  0xF00D",
                    "Scanning neural interfaces .............. 5 found",
                    "WARNING: anomalous signal on channel 0xFF",
                    "Bypassing perimeter firewall ............ [DONE]",
                    "Loading identity module: CHIEF",
                    "ALL SYSTEMS NOMINAL. READY. GO!",
                ]

                Repeater {
                    model: terminal.lines
                    Text {
                        id: termLine
                        text: modelData
                        color: {
                            if (index === terminal.lines.length - 1) return "#00ff41"
                            if (modelData.startsWith(">"))       return "#ffcc00"
                            if (modelData.startsWith("WARNING")) return "#ff4444"
                            return "#00cc33"
                        }
                        font.pixelSize: 13
                        font.family: "monospace"
                        font.weight: (index === 0 || index === terminal.lines.length - 1) ? Font.Bold : Font.Normal
                        opacity: 0

                        Component.onCompleted: lineAnim.start()
                        SequentialAnimation {
                            id: lineAnim
                            PauseAnimation { duration: index * 280 }
                            NumberAnimation { target: termLine; property: "opacity"; from: 0; to: 1; duration: 60 }
                        }
                    }
                }
            }

            // CHIEF — scramble + chroma + jitter
            Row {
                id: chiefRow
                spacing: 10

                Repeater {
                    model: ["C", "H", "I", "E", "F"]

                    Item {
                        id: letterItem
                        width: letterText.implicitWidth
                        height: letterText.implicitHeight

                        property bool scrambling: false
                        property bool locked: false
                        property string displayed: " "
                        property real jitterX: 0
                        property real jitterY: 0

                        transform: Translate { x: letterItem.jitterX; y: letterItem.jitterY }

                        // Jitter during drop
                        Timer {
                            interval: 30
                            running: content.jittering
                            repeat: true
                            onTriggered: {
                                letterItem.jitterX = (Math.random() - 0.5) * 18
                                letterItem.jitterY = (Math.random() - 0.5) * 10
                            }
                        }

                        // Scramble
                        Timer {
                            interval: 50
                            running: letterItem.scrambling && !letterItem.locked
                            repeat: true
                            onTriggered: {
                                const chars = "!@#$%^&*[]{}\\/<>?ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                                letterItem.displayed = chars[Math.floor(Math.random() * chars.length)]
                            }
                        }

                        // Appear
                        Timer {
                            interval: 800 + index * 350
                            running: true; repeat: false
                            onTriggered: { letterItem.scrambling = true; appearAnim.start() }
                        }

                        // Lock in
                        Timer {
                            interval: 1400 + index * 450
                            running: true; repeat: false
                            onTriggered: { letterItem.locked = true; letterItem.displayed = modelData }
                        }

                        // Cyan channel
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -content.chromaOffset
                            text: letterItem.displayed
                            color: "#00ffff"
                            font.pixelSize: 120; font.weight: Font.Bold; font.family: "monospace"
                            opacity: letterText.opacity * 0.6
                        }

                        // Magenta channel
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: content.chromaOffset
                            text: letterItem.displayed
                            color: "#ff00ff"
                            font.pixelSize: 120; font.weight: Font.Bold; font.family: "monospace"
                            opacity: letterText.opacity * 0.6
                        }

                        // Main letter
                        Text {
                            id: letterText
                            anchors.centerIn: parent
                            text: letterItem.displayed
                            color: "#00ff41"
                            font.pixelSize: 120; font.weight: Font.Bold; font.family: "monospace"
                            opacity: 0

                            NumberAnimation {
                                id: appearAnim
                                target: letterText; property: "opacity"
                                from: 0; to: 1; duration: 120
                            }
                        }
                    }
                }
            }
        }

        // ── ERROR overlay ─────────────────────────────────────────────
        Item {
            id: errorText
            anchors.centerIn: parent
            opacity: 0
            z: 10

            width: errorMain.implicitWidth
            height: errorMain.implicitHeight

            property string baseText: "!! SYSTEM ERROR !!"
            property string displayed: baseText
            property real jitterX: 0
            property real jitterY: 0
            property real chroma: 6

            transform: Translate { x: errorText.jitterX; y: errorText.jitterY }

            Timer {
                interval: 55
                running: errorText.opacity > 0
                repeat: true
                onTriggered: {
                    const glitch = "!@#$%^&*[]{}|<>?/\\~X"
                    let out = ""
                    for (let i = 0; i < errorText.baseText.length; i++) {
                        const c = errorText.baseText[i]
                        out += (c !== " " && Math.random() < 0.18)
                            ? glitch[Math.floor(Math.random() * glitch.length)]
                            : c
                    }
                    errorText.displayed = out
                }
            }

            Timer {
                interval: 35
                running: errorText.opacity > 0
                repeat: true
                onTriggered: {
                    errorText.jitterX = (Math.random() - 0.5) * 14
                    errorText.jitterY = (Math.random() - 0.5) * 7
                    errorText.chroma = Math.random() * 10 + 4
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -errorText.chroma
                text: errorText.displayed
                color: "#ff6699"
                font.pixelSize: 72; font.weight: Font.Bold; font.family: "monospace"
                opacity: 0.55
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: errorText.chroma
                text: errorText.displayed
                color: "#ff00aa"
                font.pixelSize: 72; font.weight: Font.Bold; font.family: "monospace"
                opacity: 0.55
            }
            Text {
                id: errorMain
                anchors.centerIn: parent
                text: errorText.displayed
                color: "#ff0000"
                font.pixelSize: 72; font.weight: Font.Bold; font.family: "monospace"
            }
        }


        Text {
            id: goodbyetext
            anchors.centerIn: parent
            opacity: 0
            z: 10
            text: "!! GOODBYE !!"
            color: "#ff0000"
            font.pixelSize: 72
            font.weight: Font.Bold
            font.family: "monospace"
        }


        // ── Code rain — z:1 behind letters ───────────────────────────
        Canvas {
            id: codeRain
            anchors.fill: parent
            opacity: 0
            z: 1

            property var streams: []

            onOpacityChanged: {
                if (opacity > 0 && streams.length === 0) {
                    const cols = Math.floor(width / 14)
                    for (let i = 0; i < cols; i++) {
                        streams.push({
                            x: i * 14,
                            y: Math.random() * -height,
                            speed: Math.random() * 4 + 2
                        })
                    }
                }
            }

            Timer {
                interval: 40
                running: codeRain.opacity > 0
                repeat: true
                onTriggered: codeRain.requestPaint()
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.fillStyle = "rgba(0,0,0,0.08)"
                ctx.fillRect(0, 0, width, height)

                const chars = "01{}[]()<>!@#$%^&*;:./\\|~ABCDEF"
                ctx.font = "13px monospace"

                for (let s of codeRain.streams) {
                    const bright = Math.random() > 0.95
                    ctx.fillStyle = bright
                        ? "#ffffff"
                        : `rgba(0,${Math.floor(Math.random() * 100 + 155)},65,${Math.random() * 0.4 + 0.6})`
                    ctx.fillText(chars[Math.floor(Math.random() * chars.length)], s.x, s.y)
                    s.y += s.speed
                    if (s.y > height) {
                        s.y = Math.random() * -200
                        s.speed = Math.random() * 4 + 2
                    }
                }
            }
        }

        // ── Glitch blocks — z:2 ──────────────────────────────────────
        Repeater {
            model: 15
            Rectangle {
                x: 0
                y: Math.random() * splash.height
                width: splash.width
                height: Math.random() * 6 + 1
                color: Qt.rgba(0, Math.random() * 0.6 + 0.2, 0.15, 0.35)
                visible: content.jittering
                z: 2
                Timer {
                    interval: Math.floor(Math.random() * 80 + 25)
                    running: parent.visible
                    repeat: true
                    onTriggered: {
                        parent.y = Math.random() * splash.height
                        parent.height = Math.random() * 8 + 1
                    }
                }
            }
        }

        // ── Noise — z:3 ──────────────────────────────────────────────
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
                const count = Math.floor(width * height * 0.008)
                for (let i = 0; i < count; i++) {
                    const x = Math.random() * width
                    const y = Math.random() * height
                    const v = Math.floor(Math.random() * 200 + 55)
                    ctx.fillStyle = `rgba(${v},${v},${v},0.8)`
                    ctx.fillRect(x, y, 1, Math.random() > 0.7 ? 3 : 1)
                }
            }
        }

        // ── Scanlines — z:4 ──────────────────────────────────────────
        Item {
            id: scanlines
            anchors.fill: parent
            opacity: 0
            z: 4
            Repeater {
                model: Math.floor(parent.height / 3)
                Rectangle {
                    y: index * 3; width: parent.width; height: 1
                    color: "#000000"; opacity: 0.35
                }
            }
        }
    }

    // Play-once check — only runs the animation on first boot, skips on reloads
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
                    audioProc.running = false
                }
            }
        }
    }
    
    // ── Main sequence ─────────────────────────────────────────────────
    SequentialAnimation {
        id: mainSequence
        running: true

        // Wait for last letter to lock in + buffer
        PauseAnimation { duration: 3500 }

        // ERROR flash
        NumberAnimation { target: errorText; property: "opacity"; to: 1;   duration: 60  }
        PauseAnimation  { duration: 80 }
        NumberAnimation { target: errorText; property: "opacity"; to: 0.1; duration: 40  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 1; duration: 40  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 0.1; duration: 40  }
        
        NumberAnimation { target: errorText; property: "opacity"; to: 1;   duration: 50  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 1; duration: 10  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 0.1; duration: 10  }
        PauseAnimation  { duration: 60 }
        NumberAnimation { target: errorText; property: "opacity"; to: 0.3; duration: 30  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 1; duration: 40  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 0.1; duration: 40  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 1; duration: 10  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 0.1; duration: 10  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 1; duration: 10  }
        NumberAnimation { target: goodbyetext; property: "opacity"; to: 0.1; duration: 10  }

        NumberAnimation { target: errorText; property: "opacity"; to: 1;   duration: 60  }

        // red flash and screen stufff
        ScriptAction { script: flashRect.color = "#cc0000" }
        NumberAnimation { target: content; property: "opacity"; to: 0.1; duration: 40 }
        NumberAnimation { target: content; property: "opacity"; to: 1;   duration: 50 }
        ScriptAction { script: flashRect.color = "transparent" }
        NumberAnimation { target: content; property: "opacity"; to: 0;   duration: 30 }
        NumberAnimation { target: content; property: "opacity"; to: 1;   duration: 60 }
        NumberAnimation { target: content; property: "opacity"; to: 0.2; duration: 35 }
        NumberAnimation { target: content; property: "opacity"; to: 1;   duration: 50 }
        ScriptAction { script: flashRect.color = "#cc0000" }
        PauseAnimation  { duration: 60 }
        ScriptAction { script: flashRect.color = "transparent" }

        // DROP — everything goes mental
        ScriptAction { script: {
            codeRain.opacity = 1
            noiseCanvas.opacity = 1
            scanlines.opacity = 1
            content.chromaOffset = 20
            content.jittering = true
        }}

        PauseAnimation { duration: 4200 }

        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 600 }
        ScriptAction { script: { audioProc.running = false; splash.visible = false } }
    }
}
