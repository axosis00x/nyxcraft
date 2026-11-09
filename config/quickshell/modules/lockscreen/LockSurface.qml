import Quickshell.Wayland
import QtQuick

WlSessionLockSurface {
    id: root

    required property var lockScreen

    color: "#000000"

    LockContent {
        anchors.fill: parent
        lockScreen: root.lockScreen
    }
}
