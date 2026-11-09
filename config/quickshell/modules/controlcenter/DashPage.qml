import QtQuick
import "../../components/material"

Item {
    id: root

    property int index: 0
    property int current: 0

    property real drift: 28

    readonly property bool shown: index === current

    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    enabled: shown

    Behavior on opacity {
        EffectMotion {}
    }

    transform: Translate {
        x: root.shown ? 0 : (root.index < root.current ? -root.drift : root.drift)

        Behavior on x {
            SpatialMotion {}
        }
    }
}
