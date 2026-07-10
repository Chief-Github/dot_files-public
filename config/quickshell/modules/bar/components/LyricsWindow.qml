import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs.services
import "../../../services" as QsServices

PanelWindow {
    id: lyricsWindow

    property bool shouldShow: false
    readonly property var player: Players.active
    readonly property var pywal: QsServices.Pywal
    readonly property color cPrimary: pywal.primary

    property var  parsedLines: []
    property int  currentLine: 0
    readonly property bool hasLyrics: parsedLines.length > 0
    readonly property bool isSynced:  hasLyrics && parsedLines[0].time >= 0

    function parseLRC(lrc) {
        const lines = []
        for (const raw of lrc.split('\n')) {
            const m = raw.match(/\[(\d+):(\d+\.?\d*)\](.*)/)
            if (!m) continue
            const sec  = parseInt(m[1]) * 60 + parseFloat(m[2])
            const text = m[3].trim()
            if (text) lines.push({ time: sec, text })
        }
        return lines.sort((a, b) => a.time - b.time)
    }

    function fetch() {
        if (!player || !player.trackTitle) return
        parsedLines = []
        currentLine = 0
        lyricsProc.running = false
        lyricsProc.running = true
    }

    onShouldShowChanged: {
        if (shouldShow && parsedLines.length === 0) fetch()
    }

    Connections {
        target: player
        function onTrackTitleChanged() {
            lyricsWindow.parsedLines = []
            lyricsWindow.currentLine = 0
            if (lyricsWindow.shouldShow) lyricsWindow.fetch()
        }
    }

    // Advance current line while playing
    Timer {
        interval: 200
        running: lyricsWindow.shouldShow && lyricsWindow.isSynced && (player?.isPlaying ?? false)
        repeat: true
        onTriggered: {
            const pos   = player?.position ?? 0
            const lines = lyricsWindow.parsedLines
            let idx = 0
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].time <= pos) idx = i
                else break
            }
            lyricsWindow.currentLine = idx
        }
    }

    // LRCLIB fetch — pass args directly to curl (no shell, safe special chars)
    Process {
        id: lyricsProc
        property string buf: ""
        command: [
            "curl", "-sf", "--max-time", "8", "-G",
            "https://lrclib.net/api/get",
            "--data-urlencode", `artist_name=${player?.trackArtist ?? ""}`,
            "--data-urlencode", `track_name=${player?.trackTitle ?? ""}`,
            "--data-urlencode", `album_name=${player?.trackAlbum ?? ""}`,
            "--data-urlencode", `duration=${Math.round(player?.length ?? 0)}`
        ]
        running: false
        stdout: SplitParser { onRead: data => lyricsProc.buf += data }
        onExited: {
            try {
                const j = JSON.parse(lyricsProc.buf)
                if (j.syncedLyrics && j.syncedLyrics.trim()) {
                    lyricsWindow.parsedLines = lyricsWindow.parseLRC(j.syncedLyrics)
                } else if (j.plainLyrics && j.plainLyrics.trim()) {
                    lyricsWindow.parsedLines = j.plainLyrics
                        .split('\n').filter(l => l.trim())
                        .map(l => ({ time: -1, text: l }))
                }
            } catch(e) {}
            lyricsProc.buf = ""
        }
    }

    visible: shouldShow
    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins { top: 10; left: 417 }
    implicitWidth: 290
    implicitHeight: 520
    color: "transparent"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "popup"

    Rectangle {
        id: lyricsOuter
        anchors.fill: parent
        radius: 24
        clip: true
        color: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 0.55)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle { width: lyricsOuter.width; height: lyricsOuter.height; radius: 24 }
        }

        // Blurred album art bg (same style as media popup)
        Item {
            anchors.fill: parent
            Image {
                id: lyricsBg
                anchors.centerIn: parent
                width: parent.width + 80; height: parent.height + 80
                source: player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
            }
            FastBlur {
                anchors.fill: lyricsBg; source: lyricsBg; radius: 80
                opacity: (lyricsBg.source !== "" && lyricsBg.status === Image.Ready) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.68) }

        // Empty / loading state
        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: !lyricsWindow.hasLyrics

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "♫"
                font.pixelSize: 32; color: Qt.rgba(1,1,1,0.15)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: lyricsProc.running ? "Finding lyrics…" : "No lyrics found"
                color: Qt.rgba(1,1,1,0.30); font.pixelSize: 13; font.family: "Inter"
            }
        }

        // Lyrics
        Item {
            anchors.fill: parent
            visible: lyricsWindow.hasLyrics

            ListView {
                id: lyricsView
                anchors { fill: parent; topMargin: 52; bottomMargin: 52 }
                model: lyricsWindow.parsedLines
                clip: true
                currentIndex: lyricsWindow.currentLine
                preferredHighlightBegin: height * 0.40
                preferredHighlightEnd:   height * 0.60
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 550
                highlightFollowsCurrentItem: true
                highlight: Item {}

                delegate: Item {
                    required property var modelData
                    required property int index
                    width: lyricsView.width
                    height: lineText.implicitHeight + 22

                    readonly property bool isCurrent: index === lyricsWindow.currentLine
                    readonly property int  dist:      Math.abs(index - lyricsWindow.currentLine)

                    // Accent bar for current line
                    Rectangle {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                        width: 3; height: isCurrent ? 28 : 0; radius: 1.5
                        color: cPrimary; opacity: 0.85
                        Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        id: lineText
                        anchors { left: parent.left; right: parent.right
                                  leftMargin: 24; rightMargin: 20; verticalCenter: parent.verticalCenter }
                        text: modelData.text ?? ""
                        color: "white"
                        opacity: isCurrent ? 1.0 : Math.max(0.12, 0.50 - dist * 0.06)
                        font.pixelSize: 13; font.family: "Inter"
                        font.weight: isCurrent ? Font.Bold : Font.Normal
                        wrapMode: Text.WordWrap
                        horizontalAlignment: isSynced ? Text.AlignLeft : Text.AlignHCenter
                        Behavior on opacity { NumberAnimation { duration: 280 } }
                    }
                }
            }

            // Top fade
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 80
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.90) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Bottom fade
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 80
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.90) }
                }
            }

            // Header bar (song label + close)
            Item {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 48

                Text {
                    anchors { left: parent.left; right: closeBtn.left
                              verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 8 }
                    text: (player?.trackTitle ?? "") + (player?.trackArtist ? "  ·  " + player.trackArtist : "")
                    color: Qt.rgba(1,1,1,0.50); font.pixelSize: 11; font.family: "Inter"
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeBtn
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                    width: 26; height: 26; radius: 13
                    color: closeMouse.containsMouse ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.06)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.55) }
                    MouseArea {
                        id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: lyricsWindow.shouldShow = false
                    }
                }
            }
        }
    }
}
