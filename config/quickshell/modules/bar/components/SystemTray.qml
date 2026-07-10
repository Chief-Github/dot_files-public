import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    spacing: 4

    property var barWindow: null
    readonly property bool hasItems: trayRepeater.count > 0

    Repeater {
        id: trayRepeater
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem
            required property var modelData
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 4
            color: hoverArea.containsMouse
                ? Qt.rgba(1, 1, 1, 0.1)
                : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: trayItem.modelData.icon ?? ""
                smooth: true
                asynchronous: true
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        if (!trayItem.modelData.onlyMenu) {
                            trayItem.modelData.activate()
                        } else {
                            const pos = hoverArea.mapToItem(null, mouse.x, mouse.y)
                            trayItem.modelData.display(root.barWindow, Math.round(pos.x), Math.round(pos.y))
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        const pos = hoverArea.mapToItem(null, mouse.x, mouse.y)
                        trayItem.modelData.display(root.barWindow, Math.round(pos.x), Math.round(pos.y))
                    }
                }
            }
        }
    }
}
