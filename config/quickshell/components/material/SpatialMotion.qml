import QtQuick
import "../../theme" as Palette

NumberAnimation {
    property bool fast: false
    property bool bouncy: false

    duration: fast ? Palette.Theme.motionFast : Palette.Theme.motionDefault
    easing.type: Easing.OutBack
    easing.overshoot: bouncy ? Palette.Theme.springBouncy : Palette.Theme.springOvershoot
}
