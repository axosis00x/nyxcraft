import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../material"
import "../../theme" as Palette

Variants {
    id: root

    required property var barLayout

    readonly property real border: Palette.Theme.screenFrameBorder
    readonly property real radius: Palette.Theme.screenFrameRadius
    readonly property bool shown: barLayout ? (barLayout.loaded && !barLayout.island) : false
    readonly property bool vertical: barLayout ? barLayout.vertical : false

    model: Quickshell.screens

    Scope {
        id: perScreen

        required property var modelData

        PanelWindow {
            id: frame

            screen: perScreen.modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-screen-frame"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            visible: shape.opacity > 0

            Shape {
                id: shape
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: root.shown ? 1 : 0

                Behavior on opacity {
                    EffectMotion {}
                }

                ShapePath {
                    fillColor: Palette.Theme.bg
                    strokeColor: "transparent"
                    strokeWidth: 0
                    fillRule: ShapePath.OddEvenFill

                    Behavior on fillColor {
                        ColorMotion {}
                    }

                    PathRectangle {
                        x: 0
                        y: 0
                        width: frame.width
                        height: frame.height
                    }
                    PathRectangle {
                        x: root.border
                        y: root.border
                        width: frame.width - 2 * root.border
                        height: frame.height - 2 * root.border
                        radius: root.radius
                    }
                }
            }
        }

        Variants {
            model: root.shown ? (root.vertical ? ["top", "bottom", "right"] : ["left", "bottom", "right"]) : []

            PanelWindow {
                required property string modelData

                screen: perScreen.modelData
                anchors {
                    top: modelData !== "bottom"
                    bottom: modelData !== "top"
                    left: modelData !== "right"
                    right: modelData !== "left"
                }
                implicitHeight: root.border
                implicitWidth: root.border
                exclusiveZone: root.border
                color: "transparent"
                mask: Region {}

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-screen-frame-reserve"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            }
        }
    }
}
