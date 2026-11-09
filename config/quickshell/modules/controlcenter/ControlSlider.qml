import QtQuick
import "../../components/material"
import "../../theme" as Palette

Item {
    id: root

    property string iconGlyph: ""
    property real value: 0

    property color accent: Palette.Theme.accent

    signal iconClicked
    signal iconRightClicked
    signal valueRequested(real value)

    implicitWidth: 1
    implicitHeight: 40

    Slider {
        id: slider
        accent: root.accent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        trackHeight: 24
        showValue: false

        minimum: 0.05
        icon: root.iconGlyph
        value: root.value
        onMoved: value => root.valueRequested(value)
    }

    MouseArea {

        x: slider.x
        width: slider.iconZone
        enabled: !slider.pressed
        height: slider.trackHeight
        anchors.verticalCenter: parent.verticalCenter
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.iconRightClicked();
            else
                root.iconClicked();
        }
    }
}
