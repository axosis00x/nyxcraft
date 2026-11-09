import QtQuick
import "../../theme" as Palette

Rectangle {
    id: root

    property Item target: null
    property real insetX: 0
    property real insetY: 0

    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0
    property bool instant: true

    radius: Palette.Theme.radiusMedium
    color: Palette.Theme.surfaceContainerHigh

    x: targetX
    y: targetY
    width: targetWidth
    height: targetHeight
    opacity: target ? 1 : 0
    visible: opacity > 0.01

    Behavior on targetX {
        enabled: !root.instant
        SpatialMotion {}
    }
    Behavior on targetY {
        enabled: !root.instant
        SpatialMotion {}
    }
    Behavior on opacity {
        EffectMotion {}
    }

    function snap() {
        instant = true;
        sync();
        instant = false;
    }
    onVisibleChanged: if (visible)
        snap()

    function sync() {
        if (!target || !parent)
            return;
        var p = target.mapToItem(parent, 0, 0);
        targetX = p.x + insetX;
        targetY = p.y + insetY;
        targetWidth = Math.max(0, target.width - insetX * 2);
        targetHeight = Math.max(0, target.height - insetY * 2);
    }

    onTargetChanged: {
        instant = opacity < 0.05;
        sync();
        instant = false;
    }

    Connections {
        target: root.target
        ignoreUnknownSignals: true
        function onXChanged() {
            root.snap();
        }
        function onYChanged() {
            root.snap();
        }
        function onWidthChanged() {
            root.snap();
        }
        function onHeightChanged() {
            root.snap();
        }
    }
}
