// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick 6.10

// NIGHT CITY — neon sign ignition
// palette: ice blue #aebfff · cyan #00d5ff · pink #ff6ec7 · navy #0a0e1a

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
        command: ["mpv", "--no-video", "--af=afade=t=in:st=0:d=1,afade=t=out:st=8:d=2", "/home/chief/Documents/quiter_hotlien_startupwav.wav"]
        running: false
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0e1a"
        z: 0
    }

    Item {
        id: content
        anchors.fill: parent
        z: 1

        property bool glitching: false

        // ── Neon pixel rain — pink/cyan drizzle ──────────────────
        Canvas {
            id: neonRain
            anchors.fill: parent
            opacity: 0
            z: 1

            property var drops: []

            Timer {
                interval: 40
                running: neonRain.opacity > 0
                repeat: true
                onTriggered: neonRain.requestPaint()
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.fillStyle = "rgba(10,14,26,0.15)"
                ctx.fillRect(0, 0, width, height)

                if (drops.length === 0) {
                    for (let i = 0; i < 90; i++) {
                        drops.push({
                            x: Math.random() * width,
                            y: Math.random() * height,
                            speed: Math.random() * 5 + 2,
                            drift: Math.random() * 1.2 - 0.3,
                            len: Math.random() * 14 + 4,
                            c: Math.random()
                        })
                    }
                }

                for (let d of drops) {
                    ctx.fillStyle = d.c < 0.45 ? "rgba(255,110,199,0.5)"
                                  : d.c < 0.85 ? "rgba(0,213,255,0.45)"
                                  : "rgba(174,191,255,0.6)"
                    ctx.fillRect(d.x, d.y, 2, d.len)
                    d.y += d.speed
                    d.x += d.drift
                    if (d.y > height) {
                        d.y = -d.len
                        d.x = Math.random() * width
                        d.speed = Math.random() * 5 + 2
                    }
                }
            }
        }

        // ── Glitch bars during ignition ──────────────────────────
        Repeater {
            model: 8
            Rectangle {
                x: 0
                y: Math.random() * splash.height
                width: splash.width
                height: Math.random() * 4 + 1
                color: index % 2 === 0 ? Qt.rgba(1, 0.43, 0.78, 0.18) : Qt.rgba(0, 0.84, 1, 0.15)
                visible: content.glitching
                z: 2
                Timer {
                    interval: Math.floor(Math.random() * 120 + 40)
                    running: parent.visible
                    repeat: true
                    onTriggered: {
                        parent.y = Math.random() * splash.height
                        parent.height = Math.random() * 5 + 1
                    }
                }
            }
        }

        // ── Centered sign ────────────────────────────────────────
        Column {
            anchors.centerIn: parent
            spacing: 30
            z: 5

            // CHIEF — neon tubes buzzing on one at a time
            Row {
                id: sign
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: ["C", "H", "I", "E", "F"]

                    Item {
                        id: tube
                        width: main.implicitWidth
                        height: main.implicitHeight

                        property bool igniting: false
                        property bool lit: false
                        property real flick: 0

                        // buzz: random brightness while igniting
                        Timer {
                            interval: 45
                            running: tube.igniting && !tube.lit
                            repeat: true
                            onTriggered: tube.flick = Math.random() < 0.4 ? 0 : Math.random() * 0.7 + 0.3
                        }

                        Timer {
                            interval: 600 + index * 450
                            running: true; repeat: false
                            onTriggered: tube.igniting = true
                        }

                        Timer {
                            interval: 1250 + index * 450
                            running: true; repeat: false
                            onTriggered: { tube.lit = true; tube.flick = 1 }
                        }

                        // pink fringe
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 3
                            text: modelData
                            color: "#ff6ec7"
                            font.pixelSize: 130; font.weight: Font.Bold; font.family: "monospace"
                            opacity: tube.flick * 0.45
                        }
                        // cyan fringe
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -3
                            text: modelData
                            color: "#00d5ff"
                            font.pixelSize: 130; font.weight: Font.Bold; font.family: "monospace"
                            opacity: tube.flick * 0.45
                        }
                        // ice blue tube
                        Text {
                            id: main
                            anchors.centerIn: parent
                            text: modelData
                            color: "#aebfff"
                            font.pixelSize: 130; font.weight: Font.Bold; font.family: "monospace"
                            opacity: tube.flick
                        }
                    }
                }
            }

            // motto — typewriter in pink
            Text {
                id: motto
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#ff6ec7"
                font.pixelSize: 22
                font.family: "monospace"
                text: ""

                property string full: "Go fast. Avoid Police."
                property int idx: 0

                Timer {
                    interval: 65
                    running: motto.idx > 0 && motto.idx <= motto.full.length
                    repeat: true
                    onTriggered: {
                        motto.text = motto.full.substring(0, motto.idx) + "_"
                        motto.idx++
                        if (motto.idx > motto.full.length) motto.text = motto.full
                    }
                }

                Timer {
                    interval: 3600
                    running: true; repeat: false
                    onTriggered: motto.idx = 1
                }
            }
        }

        // ── Boot bar — bottom, like the year-progress widget ─────
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 120
            spacing: 10
            z: 5

            Text {
                id: bootStatus
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#00d5ff"
                font.pixelSize: 13
                font.family: "monospace"
                text: {
                    const p = bootFill.pct
                    if (p < 20)  return "> waking neon grid ..."
                    if (p < 45)  return "> tuning chrome ..."
                    if (p < 70)  return "> charging night city ..."
                    if (p < 95)  return "> never go slow ..."
                    return "> GO."
                }
            }

            Rectangle {
                width: 420; height: 6
                radius: 3
                color: Qt.rgba(0.68, 0.75, 1, 0.15)

                Rectangle {
                    id: bootFill
                    property real pct: 0
                    width: parent.width * pct / 100
                    height: parent.height
                    radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00d5ff" }
                        GradientStop { position: 1.0; color: "#ff6ec7" }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#aebfff"
                font.pixelSize: 12
                font.family: "monospace"
                text: Math.floor(bootFill.pct) + "% through boot, never go slow!"
            }
        }

        // ── Scanlines ────────────────────────────────────────────
        Item {
            anchors.fill: parent
            opacity: 0.25
            z: 8
            Repeater {
                model: Math.floor(splash.height / 4)
                Rectangle {
                    y: index * 4; width: parent.width; height: 1
                    color: "#000000"; opacity: 0.5
                }
            }
        }

        // full-brightness flash at the end
        Rectangle {
            id: flashRect
            anchors.fill: parent
            color: "#aebfff"
            opacity: 0
            z: 9
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

    // ── Main sequence ────────────────────────────────────────────
    SequentialAnimation {
        id: mainSequence
        running: false

        // rain fades in, glitch during tube ignition
        ParallelAnimation {
            NumberAnimation { target: neonRain; property: "opacity"; to: 1; duration: 900 }
            ScriptAction { script: content.glitching = true }
        }

        // boot bar fills while the sign ignites
        NumberAnimation { target: bootFill; property: "pct"; from: 0; to: 62; duration: 3400; easing.type: Easing.OutQuad }

        // sign is lit — calm down the glitch, finish the bar
        ScriptAction { script: content.glitching = false }
        NumberAnimation { target: bootFill; property: "pct"; to: 100; duration: 2600; easing.type: Easing.InOutQuad }

        PauseAnimation { duration: 500 }

        // neon surge — flash to full brightness twice
        NumberAnimation { target: flashRect; property: "opacity"; to: 0.35; duration: 70 }
        NumberAnimation { target: flashRect; property: "opacity"; to: 0;    duration: 90 }
        PauseAnimation  { duration: 120 }
        NumberAnimation { target: flashRect; property: "opacity"; to: 0.55; duration: 60 }
        NumberAnimation { target: flashRect; property: "opacity"; to: 0;    duration: 200 }

        PauseAnimation { duration: 900 }

        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 700 }
        ScriptAction { script: { audioProc.running = false; splash.visible = false } }
    }
}
