import Quickshell.Widgets
import QtQuick
import "../../components/material"
import "../../theme" as Palette

Item {
    id: root

    required property var bar

    readonly property int percent: Math.max(0, Math.min(100, bar.batteryPercent))
    readonly property real level: percent / 100
    readonly property bool charging: bar.batteryCharging
    readonly property bool low: percent <= 15 && !charging
    readonly property color fillColor: charging ? Palette.Theme.accent : (low ? Palette.Theme.errorColor : Palette.Theme.textPrimary)

    visible: bar.batteryAvailable
    implicitWidth: body.width + 3
    implicitHeight: 12

    ClippingRectangle {
        id: body
        width: 28
        height: parent.height
        radius: 4
        color: Qt.alpha(Palette.Theme.textPrimary, 0.18)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.level
            color: root.fillColor

            Behavior on width {
                SpatialMotion {}
            }
            Behavior on color {
                ColorMotion {}
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.charging
                text: "electric_bolt"
                color: label.color
                font.family: Palette.Theme.fontIcons
                font.weight: Palette.Theme.iconWeight
                font.pixelSize: 10
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: root.percent

                color: root.level > 0.5 ? Palette.Theme.surfaceSolid : Palette.Theme.textPrimary
                font.family: Palette.Theme.fontSans
                font.pixelSize: 8
                font.weight: Font.Bold
            }
        }
    }

    Rectangle {
        anchors.left: body.right
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 5
        radius: 1
        color: Qt.alpha(Palette.Theme.textPrimary, 0.4)
    }
}
