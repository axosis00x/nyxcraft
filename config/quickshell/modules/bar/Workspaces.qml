import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../theme" as Palette
import "../../components/material"

Item {
    id: root
    property bool vertical: false
    property var service: null
    property bool trimToUsed: false
    readonly property int count: {
        if (!trimToUsed)
            return 10;
        var highest = Math.max(3, activeIndex + 1);
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id >= 1 && list[i].id <= 10)
                highest = Math.max(highest, list[i].id);
        }
        return highest;
    }
    property real dotSize: 10
    property real activeLength: 45
    property real gap: 3

    readonly property int activeIndex: {
        var id = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        return id >= 1 && id <= 10 ? id - 1 : -1;
    }
    function openAtPosition(px, py) {
        if (!service)
            return;
        for (var i = 0; i < dots.count; i++) {
            var d = dots.itemAt(i);
            if (!d)
                continue;
            var p = d.mapToItem(root, 0, 0);
            if (px >= p.x - 4 && px <= p.x + d.width + 4 && py >= p.y - 6 && py <= p.y + d.height + 6) {
                service.openAt(i);
                return;
            }
        }
        service.openAt(Math.max(0, activeIndex));
    }

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        columns: root.vertical ? 1 : 999
        rowSpacing: root.gap
        columnSpacing: root.gap

        Repeater {
            id: dots
            model: root.count

            Rectangle {
                id: dot

                required property int index
                readonly property bool isActive: root.activeIndex === index
                readonly property bool isUrgent: {
                    var list = Hyprland.workspaces.values;
                    for (var i = 0; i < list.length; i++) {
                        if (list[i].id === index + 1)
                            return list[i].urgent;
                    }
                    return false;
                }
                readonly property real length: isActive ? root.activeLength : root.dotSize
                Layout.preferredWidth: root.vertical ? root.dotSize : length
                Layout.preferredHeight: root.vertical ? length : root.dotSize
                radius: root.dotSize / 2
                color: isUrgent ? Palette.Theme.errorColor : (isActive ? Palette.Theme.accent : (dotMouse.containsMouse ? Palette.Theme.textSecondary : Palette.Theme.textMuted))
                scale: isActive ? 1 : 0.9

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: Palette.Theme.motionDefault
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Palette.Theme.motionDefault
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorMotion {
                        fast: false
                    }
                }
                Behavior on scale {
                    SpatialMotion {}
                }

                MouseArea {
                    id: dotMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.service)
                            root.service.openAt(dot.index);
                    }
                }
            }
        }
    }
}
