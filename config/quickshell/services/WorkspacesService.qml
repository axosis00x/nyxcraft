pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Item {
    id: root
    visible: false

    readonly property int slotCount: 10

    property bool active: false

    property int selected: 0

    property var workspacesById: ({})

    function workspaceFor(id) {
        return root.workspacesById[id] || null;
    }

    function step(delta) {
        if (!root.active) {
            root.active = true;
            var current = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
            root.selected = Math.max(0, Math.min(root.slotCount - 1, current - 1));
            return;
        }
        root.selected = (root.selected + delta + root.slotCount) % root.slotCount;
    }

    function selectIndex(index) {
        if (index < 0 || index >= root.slotCount)
            return;
        root.selected = index;
    }

    function openAt(index) {
        root.selectIndex(index);
        root.active = true;
    }

    function confirm() {
        if (root.active)
            root.focusWorkspace(root.selected + 1);
        root.active = false;
    }

    function cancel() {
        root.active = false;
    }

    function dispatchWithoutWarp(dispatch) {
        dispatchProcess.exec(["hyprctl", "eval", "local w = hl.get_config('cursor.no_warps') " + "hl.config({ cursor = { no_warps = true } }) " + "hl.dispatch(" + dispatch + ") " + "hl.config({ cursor = { no_warps = w } })"]);
    }

    function focusWorkspace(id) {
        dispatchWithoutWarp("hl.dsp.focus({workspace = " + id + "})");
    }

    function moveWindowToWorkspace(address, id) {
        var addr = address.indexOf("0x") === 0 ? address : "0x" + address;
        dispatchWithoutWarp("hl.dsp.window.move({workspace = " + id + ", window = \"address:" + addr + "\"})");
    }

    Process {
        id: dispatchProcess
    }

    Instantiator {
        model: Hyprland.workspaces

        delegate: Item {
            id: entry
            required property var modelData

            function sync() {
                var next = Object.assign({}, root.workspacesById);
                next[entry.modelData.id] = entry.modelData;
                root.workspacesById = next;
            }

            Component.onCompleted: entry.sync()

            Connections {
                target: entry.modelData
                function onIdChanged() {
                    entry.sync();
                }
            }
        }

        onObjectRemoved: (index, object) => {
            var next = Object.assign({}, root.workspacesById);
            delete next[object.modelData.id];
            root.workspacesById = next;
        }
    }
}
