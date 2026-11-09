import QtQuick
import "../../theme" as Palette

NumberAnimation {
    property bool fast: true

    duration: fast ? Palette.Theme.effectFast : Palette.Theme.effectDefault
    easing.type: Easing.OutCubic
}
