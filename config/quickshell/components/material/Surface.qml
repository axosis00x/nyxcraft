import QtQuick
import "../../theme" as Palette

Rectangle {
    id: root

    property color tint: Palette.Theme.surfaceTint
    property real tintOpacity: Palette.Theme.surfaceTintOpacity
    property color outlineColor: Palette.Theme.outlineSoft
    property real outlineWidth: 0

    radius: Palette.Theme.radiusLarge
    color: Palette.Theme.surfaceContainer
    border.color: root.outlineColor
    border.width: root.outlineWidth
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outlineWidth
        radius: parent.radius
        color: root.tint
        opacity: root.tintOpacity
        visible: root.tintOpacity > 0
    }
}
