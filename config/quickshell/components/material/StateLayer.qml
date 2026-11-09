import QtQuick
import "../../theme" as Palette

Rectangle {
    property bool hovered: false
    property bool pressed: false
    property color tone: Palette.Theme.textPrimary

    anchors.fill: parent
    color: tone
    opacity: pressed ? Palette.Theme.statePressed : (hovered ? Palette.Theme.stateHover : 0)

    Behavior on opacity {
        EffectMotion {}
    }
}
