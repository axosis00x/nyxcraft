import QtQuick
import QtQuick.Shapes
import "../../theme" as Palette

Item {
    id: root

    property real slabWidth: 200
    property real slabHeight: 44
    property real slabRadius: 16
    property real wingSize: 14
    property real contentBottomPadding: 0
    property bool clipContent: true
    property bool bottomAligned: false

    property bool island: false
    property real islandGap: 6
    property real islandRadius: slabRadius
    property real islandness: island ? 1 : 0
    Behavior on islandness {
        SpatialMotion {}
    }
    readonly property real islandOffset: islandGap * islandness

    property color color: Palette.Theme.surfaceContainer
    property color tint: Palette.Theme.surfaceTint
    property real tintOpacity: Palette.Theme.surfaceTintOpacity
    property color outlineColor: Palette.Theme.outlineVariant
    property real outlineWidth: 1

    default property alias content: contentHolder.data

    implicitWidth: slabWidth + wingSize * 2

    implicitHeight: slabHeight + islandOffset

    readonly property real wing: Math.max(0, Math.min(wingSize, height))
    readonly property real effectiveRadius: Math.max(0, Math.min(slabRadius, height - wing, slabWidth / 2))

    Shape {
        anchors.fill: parent
        opacity: 1 - root.islandness
        visible: opacity > 0.01
        antialiasing: true

        preferredRendererType: Shape.CurveRenderer

        rotation: root.bottomAligned ? 180 : 0

        ShapePath {

            fillColor: Qt.tint(root.color, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.tintOpacity))
            strokeColor: "transparent"
            strokeWidth: 0

            startX: 0
            startY: 0

            PathLine {
                x: 2 * root.wing + root.slabWidth
                y: 0
            }

            PathArc {
                x: root.wing + root.slabWidth
                y: root.wing
                radiusX: root.wing
                radiusY: root.wing
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: root.wing + root.slabWidth
                y: root.slabHeight - root.effectiveRadius
            }

            PathArc {
                x: root.wing + root.slabWidth - root.effectiveRadius
                y: root.slabHeight
                radiusX: root.effectiveRadius
                radiusY: root.effectiveRadius
                direction: PathArc.Clockwise
            }

            PathLine {
                x: root.wing + root.effectiveRadius
                y: root.slabHeight
            }

            PathArc {
                x: root.wing
                y: root.slabHeight - root.effectiveRadius
                radiusX: root.effectiveRadius
                radiusY: root.effectiveRadius
                direction: PathArc.Clockwise
            }

            PathLine {
                x: root.wing
                y: root.wing
            }

            PathArc {
                x: 0
                y: 0
                radiusX: root.wing
                radiusY: root.wing
                direction: PathArc.Counterclockwise
            }
        }
    }

    Rectangle {
        x: root.wing
        y: root.bottomAligned ? 0 : root.islandOffset
        width: root.slabWidth
        height: root.slabHeight
        radius: Math.min(root.islandRadius, root.slabWidth / 2, root.slabHeight / 2)
        color: Qt.tint(root.color, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.tintOpacity))
        opacity: root.islandness
        visible: opacity > 0.01
    }

    Item {
        id: contentHolder
        x: root.wing

        y: root.bottomAligned ? root.contentBottomPadding : root.islandOffset
        width: root.slabWidth
        height: Math.max(0, root.slabHeight - root.contentBottomPadding)
        clip: root.clipContent
    }
}
