// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import Quickshell.Io

PanelWindow {
    id: splash
    WlrLayershell.namespace: "boot"
    exclusiveZone: -1
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay

    Process {
        id: audioProc
        command: ["mpv", "--no-video", "--af=afade=t=in:st=0:d=3,afade=t=out:st=14:d=2.5", "/home/chief/Documents/BOOT.wav"]
        running: false
    }
    
    Item {
        id: content
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "#000000"
        }

        property real chromaOffset: 0

        // Oscillate the chroma offset randomly during glitch phase
        Timer {
            id: chromaTimer
            interval: 80
            repeat: true
            running: content.chromaOffset > 0
            onTriggered: content.chromaOffset = Math.random() * 20 + 5
        }

        // Click to dismiss while testing
        MouseArea {
            anchors.fill: parent
            onClicked: { audioProc.running = false; splash.visible = false }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: ["C", "H", "I", "E", "F"]

                Item {
                    width: letter.implicitWidth
                    height: letter.implicitHeight

                    // Red channel — shifted left
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -content.chromaOffset
                        text: modelData
                        font.pixelSize: 120
                        font.weight: Font.Bold
                        color: "#00ffff"
                        opacity: letter.opacity * 0.6
                        property real _angle: 180

                        transform: Rotation {
                            origin.x: letter.width / 2
                            origin.y: letter.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: letter._angle
                        }
                    }

                    // Blue channel — shifted right
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: content.chromaOffset
                        text: modelData
                        font.pixelSize: 120
                        font.weight: Font.Bold
                        color: "#ff00ff"
                        opacity: letter.opacity * 0.6
                        property real _angle: 180

                        transform: Rotation {
                            origin.x: letter.width / 2
                            origin.y: letter.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: letter._angle
                        }
                    }

                    // Main letter 
                    Text {
                        id: letter
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 120
                        font.weight: Font.Bold
                        color: "#550299"

                        opacity: 0
                        property real _angle: 180

                        transform: Rotation {
                            origin.x: letter.width / 2
                            origin.y: letter.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: letter._angle
                        }

                        Component.onCompleted: letterAnim.start()

                        SequentialAnimation {
                            id: letterAnim
                            PauseAnimation { duration: index * 700 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: letter
                                    property: "_angle"
                                    from: 180; to: 0
                                    duration: 1000
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: letter
                                    property: "opacity"
                                    from: 0; to: 1
                                    duration: 600
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }

        //glitchy type blocks
        Repeater {
            model: 12

            Rectangle {
                x: 0
                y: Math.random() * splash.height
                width: splash.width
                height: Math.random() * 6 + 1
                color: Qt.rgba(Math.random() * 0.4, 0, Math.random() * 0.4, 0.25)
                visible: content.chromaOffset > 0  // reuse this as the "glitching" flag
                z: 1

                Timer {
                    interval: Math.floor(Math.random() * 100 + 40)
                    running: parent.visible
                    repeat: true
                    onTriggered: {
                        parent.y = Math.random() * splash.height
                        parent.height = Math.random() * 8 + 1
                    }
                }
            }
        }
        // Noise canvas — z:2 so it sits above the letters
        Canvas {
            id: noiseCanvas
            anchors.fill: parent
            opacity: 0
            z: 2

            Timer {
                interval: 50
                running: noiseCanvas.opacity > 0
                repeat: true
                onTriggered: noiseCanvas.requestPaint()
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const count = Math.floor(width * height * 0.015)
                for (let i = 0; i < count; i++) {
                    const x = Math.random() * width
                    const y = Math.random() * height
                    const v = Math.floor(Math.random() * 200 + 55)
                    ctx.fillStyle = `rgba(${v},${v},${v},0.8)`
                    ctx.fillRect(x, y, 1, Math.random() > 0.7 ? 3 : 1)
                }
            }
        }


        // Scanlines — z:3 on top of everything
        Item {
            id: scanlines
            anchors.fill: parent
            opacity: 0
            z: 3

            Repeater {
                model: Math.floor(parent.height / 3)
                Rectangle {
                    y: index * 3
                    width: parent.width
                    height: 1
                    color: "#000000"
                    opacity: 0.4
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
                }
            }
        }
    }

    // Main sequence
    SequentialAnimation {
        id: mainSequence
        running: false

        PauseAnimation { duration: 3735 } //was at 4000

        // Flicker burst at the drop
        SequentialAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 0.1; duration: 40 }
            NumberAnimation { target: content; property: "opacity"; to: 1;   duration: 50 }
            NumberAnimation { target: content; property: "opacity"; to: 0;   duration: 30 }
            NumberAnimation { target: content; property: "opacity"; to: 1;   duration: 60 }
            NumberAnimation { target: content; property: "opacity"; to: 0.2; duration: 35 }
            NumberAnimation { target: content; property: "opacity"; to: 1;   duration: 50 }
        }

        // Drop — kick off the chaos
        ScriptAction { script: {
            noiseCanvas.opacity = 1
            scanlines.opacity = 1
            content.chromaOffset = 15
        }}

        PauseAnimation { duration: 3800 }

        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 500 }
        PauseAnimation { duration: 600 }

        ScriptAction { script: audioProc.running = false }
        ScriptAction { script: splash.visible = false }

    }
}
