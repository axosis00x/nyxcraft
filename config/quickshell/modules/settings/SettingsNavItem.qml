import QtQuick
import "../../components/material"
import "../../theme" as Palette

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool selected: false

    property color hue: Palette.Theme.accent

    readonly property bool hovered: mouse.containsMouse
    signal clicked

    implicitHeight: 40

    StateLayer {
        radius: Palette.Theme.radiusSmall
        hovered: false
        pressed: mouse.pressed
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Palette.Theme.spacingMedium
        spacing: Palette.Theme.spacingMedium

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.hue
            font.family: Palette.Theme.fontIcons
            font.weight: Palette.Theme.iconWeight
            font.pixelSize: Palette.Theme.iconSize

            Behavior on color {
                ColorMotion {}
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.selected ? Palette.Theme.textPrimary : Palette.Theme.textSecondary
            font.family: Palette.Theme.fontSans
            font.pixelSize: Palette.Theme.fontSizeBody
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
