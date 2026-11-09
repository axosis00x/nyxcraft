import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme" as Palette
import "../../components/material"

GridLayout {
    id: root

    required property var parentWindow
    property bool vertical: false
    property real cellSize: 24
    property real cellRadius: Palette.Theme.radiusSmall - 3

    columns: vertical ? 1 : 999
    rowSpacing: 0
    columnSpacing: 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayIcon
            required property SystemTrayItem modelData

            implicitWidth: root.cellSize
            implicitHeight: root.cellSize
            Layout.alignment: Qt.AlignCenter

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: trayIcon.modelData.icon
                smooth: true
                mipmap: true
            }

            StateLayer {
                radius: root.cellRadius
                hovered: ma.containsMouse
                pressed: ma.pressed
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        trayIcon.modelData.activate();
                    else if (mouse.button === Qt.MiddleButton)
                        trayIcon.modelData.secondaryActivate();
                    else if (mouse.button === Qt.RightButton && trayIcon.modelData.hasMenu)
                        trayIcon.modelData.display(root.parentWindow, trayIcon.x + mouse.x, trayIcon.y + mouse.y);
                }
            }

            ToolTip {
                visible: ma.containsMouse && trayIcon.modelData.tooltipTitle !== ""
                text: {
                    var t = trayIcon.modelData.tooltipTitle;
                    var d = trayIcon.modelData.tooltipDescription;
                    return d !== "" ? t + "\n" + d : t;
                }
                delay: 600
                font.family: Palette.Theme.fontMono
                font.pixelSize: Palette.Theme.fontSizeXs
            }
        }
    }
}
