// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import "components" as BarComponents
import "../../components"
import "../../components/effects"
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root
    
    property var screen
    property var barWindow
    property var controlCenter
    property var launcher
    property var sidebar
    property var dashboard
    property var brightnessPopup
    property var volumePopup
    property var mediaPlayerPopup
    property var bluetoothPopup
    property var networkPopup
    property var ipPopup
    property var btInfoPopup
    property var sysInfoPopup
    property var weatherPopup
    
    readonly property real popupAreaHeight: 0
    
    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property var pywal: QsServices.Pywal
    
    // ═══════════════════════════════════════════════════════════════════════
    // MINIMAL AESTHETIC BAR
    // Clean, professional, beautiful - inspired by modern Linux rice
    // ═══════════════════════════════════════════════════════════════════════
    
    // Main bar container with floating effect — pinned to top bar strip
    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        anchors.topMargin: 3
        height: config.bar.height - 2  // bar height minus top+bottom margin
        
        // ═══════════════════════════════════════════════════════════════
        // LEFT MODULE - Workspaces
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: leftModule
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: leftContent.implicitWidth + 18

            radius: 20
            color: pywal.surfaceContainerHigh
            colorWaveDelay: 0
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 3

            opacity: 0
            property real _startY: 6
            property real _liftY: 0
            transform: Translate { y: leftModule._startY + leftModule._liftY }
            NumberAnimation { id: leftLift; target: leftModule; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
            HoverHandler { onHoveredChanged: { leftLift.stop(); leftLift.from = leftModule._liftY; leftLift.to = hovered ? -2 : 0; leftLift.start() } }
            Component.onCompleted: leftEntrance.start()
            SequentialAnimation {
                id: leftEntrance
                PauseAnimation { duration: 0 }
                ParallelAnimation {
                    NumberAnimation { target: leftModule; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                    NumberAnimation { target: leftModule; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                }
            }

            Behavior on width {
                NumberAnimation { duration: 350; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            RowLayout {
                id: leftContent
                anchors.centerIn: parent
                spacing: 10
                
                // Workspaces
                Loader {
                    id: workspacesLoader
                    Layout.alignment: Qt.AlignVCenter
                    asynchronous: true
                    source: "components/Workspaces.qml"
                    
                    Binding {
                        target: workspacesLoader.item
                        property: "screen"
                        value: root.screen
                        when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // CENTER MODULE - Clock (Focal Point)
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: centerModule
            //anchors.right: parent.right
            //anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: clockLoader.implicitWidth + 22

            radius: 20
            color: pywal.surfaceContainerHighest
            colorWaveDelay: 150
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 4
            highlighted: true

            opacity: 0
            property real _startY: 6
            property real _liftY: 0
            transform: Translate { y: centerModule._startY + centerModule._liftY }
            NumberAnimation { id: centerLift; target: centerModule; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
            HoverHandler { onHoveredChanged: { centerLift.stop(); centerLift.from = centerModule._liftY; centerLift.to = hovered ? -2 : 0; centerLift.start() } }
            Component.onCompleted: centerEntrance.start()
            SequentialAnimation {
                id: centerEntrance
                PauseAnimation { duration: 80 }
                ParallelAnimation {
                    NumberAnimation { target: centerModule; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                    NumberAnimation { target: centerModule; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                }
            }

            Loader {
                id: clockLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/Clock.qml"

                Binding {
                    target: clockLoader.item
                    property: "launcher"
                    value: root.launcher
                    when: clockLoader.status === Loader.Ready && root.launcher !== undefined
                    restoreMode: Binding.RestoreBinding
                }

                Binding {
                    target: clockLoader.item
                    property: "controlCenter"
                    value: root.controlCenter
                    when: clockLoader.status === Loader.Ready && root.controlCenter !== undefined
                    restoreMode: Binding.RestoreBinding
                }

                Binding {
                    target: clockLoader.item
                    property: "sidebar"
                    value: root.sidebar
                    when: clockLoader.status === Loader.Ready && root.sidebar !== undefined
                    restoreMode: Binding.RestoreBinding
                }

                Binding {
                    target: clockLoader.item
                    property: "dashboard"
                    value: root.dashboard
                    when: clockLoader.status === Loader.Ready && root.dashboard !== undefined
                    restoreMode: Binding.RestoreBinding
                }
            }
        }

        
        // ═══════════════════════════════════════════════════════════════
        // RIGHT SIDE - Three Separate Pills
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: rightPills
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // ═══ PILL 0: System Stats ═══
            AuroraSurface {
                id: statsPill
                height: 32
                width: statsLoader.item ? statsLoader.item.implicitWidth + 18 : 0
                radius: 20
                color: pywal.surfaceContainerHigh
                colorWaveDelay: 220
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.tertiary
                elevation: 3

                opacity: 0
                property real _startY: 6
                property real _liftY: 0
                transform: Translate { y: statsPill._startY + statsPill._liftY }
                NumberAnimation { id: statsLift; target: statsPill; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
                HoverHandler { onHoveredChanged: { statsLift.stop(); statsLift.from = statsPill._liftY; statsLift.to = hovered ? -2 : 0; statsLift.start() } }
                Component.onCompleted: statsEntrance.start()
                SequentialAnimation {
                    id: statsEntrance
                    PauseAnimation { duration: 180 }
                    ParallelAnimation {
                        NumberAnimation { target: statsPill; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: statsPill; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                Loader {
                    id: statsLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/SystemStats.qml"

                    Binding {
                        target: statsLoader.item
                        property: "sysInfoPopup"
                        value: root.sysInfoPopup
                        when: statsLoader.status === Loader.Ready
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }
            
            // ═══ PILL 1: Network + Bluetooth (Connectivity) ═══
            AuroraSurface {
                id: weatherModule
                height: 32
                width: weatherLoader.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                elevation: 3

                opacity: 0
                property real _startY: 6
                property real _liftY: 0
                transform: Translate { y: weatherModule._startY + weatherModule._liftY }
                NumberAnimation { id: weatherLift; target: weatherModule; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
                HoverHandler { onHoveredChanged: { weatherLift.stop(); weatherLift.from = weatherModule._liftY; weatherLift.to = hovered ? -2 : 0; weatherLift.start() } }
                Component.onCompleted: weatherEntrance.start()
                SequentialAnimation {
                    id: weatherEntrance
                    PauseAnimation { duration: 120 }
                    ParallelAnimation {
                        NumberAnimation { target: weatherModule; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: weatherModule; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                Loader {
                    id: weatherLoader
                    anchors.centerIn: parent
                    asynchronous: true
                    source: "components/Weather.qml"

                    Binding {
                        target: weatherLoader.item
                        property: "weatherPopup"
                        value: root.weatherPopup
                        when: weatherLoader.status === Loader.Ready
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }
            AuroraSurface {
                id: connectivityPill
                height: 32
                width: connectivityContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                colorWaveDelay: 280
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.info
                elevation: 3

                opacity: 0
                property real _startY: 6
                property real _liftY: 0
                transform: Translate { y: connectivityPill._startY + connectivityPill._liftY }
                NumberAnimation { id: connLift; target: connectivityPill; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
                HoverHandler { onHoveredChanged: { connLift.stop(); connLift.from = connectivityPill._liftY; connLift.to = hovered ? -2 : 0; connLift.start() } }
                Component.onCompleted: connectivityEntrance.start()
                SequentialAnimation {
                    id: connectivityEntrance
                    PauseAnimation { duration: 230 }
                    ParallelAnimation {
                        NumberAnimation { target: connectivityPill; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: connectivityPill; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                Row {
                    id: connectivityContent
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Loader {
                        id: networkLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Network.qml"

                        Binding {
                            target: networkLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: networkLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: networkLoader.item
                            property: "bar"
                            value: root
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: networkLoader.item
                            property: "networkPopup"
                            value: root.networkPopup
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: networkLoader.item
                            property: "ipPopup"
                            value: root.ipPopup
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }
                    
                    Loader {
                        id: bluetoothLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Bluetooth.qml"

                        Binding {
                            target: bluetoothLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: bluetoothLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: bluetoothLoader.item
                            property: "bar"
                            value: root
                            when: bluetoothLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: bluetoothLoader.item
                            property: "bluetoothPopup"
                            value: root.bluetoothPopup
                            when: bluetoothLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: bluetoothLoader.item
                            property: "btInfoPopup"
                            value: root.btInfoPopup
                            when: bluetoothLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }
            
            // ═══ PILL 2: Brightness + Volume (Audio/Display) ═══
            AuroraSurface {
                id: audioPill
                height: 32
                width: audioContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                colorWaveDelay: 340
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3

                opacity: 0
                property real _startY: 6
                property real _liftY: 0
                transform: Translate { y: audioPill._startY + audioPill._liftY }
                NumberAnimation { id: audioLift; target: audioPill; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
                HoverHandler { onHoveredChanged: { audioLift.stop(); audioLift.from = audioPill._liftY; audioLift.to = hovered ? -2 : 0; audioLift.start() } }
                Component.onCompleted: audioEntrance.start()
                SequentialAnimation {
                    id: audioEntrance
                    PauseAnimation { duration: 280 }
                    ParallelAnimation {
                        NumberAnimation { target: audioPill; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: audioPill; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                Row {
                    id: audioContent
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Loader {
                        id: brightnessLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Brightness.qml"
                        
                        Binding {
                            target: brightnessLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: brightnessLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: brightnessLoader.item
                            property: "brightnessPopup"
                            value: root.brightnessPopup
                            when: brightnessLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }
                    
                    Loader {
                        id: volumeLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Volume.qml"
                        
                        Binding {
                            target: volumeLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: volumeLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }

                        Binding {
                            target: volumeLoader.item
                            property: "volumePopup"
                            value: root.volumePopup
                            when: volumeLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            // ═══ PILL 3: Battery + Control Center + Tray ═══
            AuroraSurface {
                id: powerPill
                height: 32
                width: powerContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                colorWaveDelay: 400
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3

                opacity: 0
                property real _startY: 6
                property real _liftY: 0
                transform: Translate { y: powerPill._startY + powerPill._liftY }
                NumberAnimation { id: powerLift; target: powerPill; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
                HoverHandler { onHoveredChanged: { powerLift.stop(); powerLift.from = powerPill._liftY; powerLift.to = hovered ? -2 : 0; powerLift.start() } }
                Component.onCompleted: powerEntrance.start()
                SequentialAnimation {
                    id: powerEntrance
                    PauseAnimation { duration: 330 }
                    ParallelAnimation {
                        NumberAnimation { target: powerPill; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                        NumberAnimation { target: powerPill; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                Row {
                    id: powerContent
                    anchors.centerIn: parent
                    spacing: 6
                    
                    // Status Indicators (Caffeine, DND)
                    Loader {
                        id: statusIndicatorsLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/StatusIndicators.qml"
                        visible: item?.hasActiveIndicators ?? false
                    }
                    
                    // Separator (only if status indicators visible)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                        visible: statusIndicatorsLoader.item?.hasActiveIndicators ?? false
                    }
                    // Battery
                    Loader {
                        id: batteryLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Battery.qml"
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }

                    
                    // Control Center Toggle
                    Loader {
                        id: controlCenterLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/ControlCenterToggle.qml"
                        
                        Binding {
                            target: controlCenterLoader.item
                            property: "controlCenter"
                            value: root.controlCenter
                            when: controlCenterLoader.status === Loader.Ready && root.controlCenter !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // SYSTEM TRAY
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: trayModule
            anchors.left: leftModule.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            radius: 20
            color: pywal.surfaceContainerHigh
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 3
            visible: systemTrayLoader.item?.hasItems ?? false
            width: visible ? systemTrayLoader.implicitWidth + 18 : 0

            opacity: 0
            property real _startY: 6
            property real _liftY: 0
            transform: Translate { y: trayModule._startY + trayModule._liftY }
            NumberAnimation { id: trayLift; target: trayModule; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
            HoverHandler { onHoveredChanged: { trayLift.stop(); trayLift.from = trayModule._liftY; trayLift.to = hovered ? -2 : 0; trayLift.start() } }
            Component.onCompleted: trayEntrance.start()
            SequentialAnimation {
                id: trayEntrance
                PauseAnimation { duration: 60 }
                ParallelAnimation {
                    NumberAnimation { target: trayModule; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                    NumberAnimation { target: trayModule; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                }
            }

            Loader {
                id: systemTrayLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/SystemTray.qml"

                Binding {
                    target: systemTrayLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: systemTrayLoader.status === Loader.Ready && root.barWindow !== undefined
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // MEDIA MODULE - Always visible (shows "No media" when not playing)
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: mediaModule
            anchors.left: trayModule.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: mediaPlayerLoader.implicitWidth + 18
            
            radius: 20
            color: pywal.surfaceContainerHigh
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.secondary
            elevation: 3

            clip: true

            opacity: 0
            property real _startY: 6
            property real _liftY: 0
            transform: Translate { y: mediaModule._startY + mediaModule._liftY }
            NumberAnimation { id: mediaLift; target: mediaModule; property: "_liftY"; duration: 150; easing.type: Easing.OutCubic }
            HoverHandler { onHoveredChanged: { mediaLift.stop(); mediaLift.from = mediaModule._liftY; mediaLift.to = hovered ? -2 : 0; mediaLift.start() } }
            Component.onCompleted: mediaEntrance.start()
            SequentialAnimation {
                id: mediaEntrance
                PauseAnimation { duration: 100 }
                ParallelAnimation {
                    NumberAnimation { target: mediaModule; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                    NumberAnimation { target: mediaModule; property: "_startY"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                }
            }

            Behavior on width {
                NumberAnimation { 
                    duration: 400
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1]
                }
            }
            
            Loader {
                id: mediaPlayerLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/MediaPlayer.qml"
                
                Binding {
                    target: mediaPlayerLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: mediaPlayerLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
                
                Binding {
                    target: mediaPlayerLoader.item
                    property: "mediaPlayerPopup"
                    value: root.mediaPlayerPopup
                    when: mediaPlayerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }  
            }
        }
    }
    
}
