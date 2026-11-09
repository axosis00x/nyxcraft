import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    readonly property bool vertical: state.vertical

    readonly property bool island: state.island

    readonly property bool compact: !state.vertical && state.compact

    readonly property string style: state.vertical ? "left" : (state.compact ? "compact" : "top")

    property bool missing: false
    readonly property bool loaded: stateFile.loaded || missing

    function setStyle(value) {
        if (value !== "top" && value !== "left" && value !== "compact")
            return;
        state.compact = value === "compact";
        if (state.vertical !== (value === "left"))
            setVertical(value === "left");
        else
            stateFile.writeAdapter();
    }

    function setIsland(value) {
        state.island = value;
        stateFile.writeAdapter();
    }

    function setVertical(value) {
        state.vertical = value;
        stateFile.writeAdapter();

        applyOrientation.exec([Quickshell.env("HOME") + "/.config/quickshell/scripts/bar-style.sh", value ? "vertical" : "horizontal"]);
    }

    Process {
        id: applyOrientation
    }

    IpcHandler {
        target: "bar"
        function toggle(): void {
            root.setVertical(!root.vertical);
        }
        function setVertical(value: bool): void {
            root.setVertical(value);
        }
        function setIsland(value: bool): void {
            root.setIsland(value);
        }
        function setStyle(value: string): void {
            root.setStyle(value);
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.cachePath("bar-layout.json")
        watchChanges: false
        blockLoading: true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.missing = true;
                writeAdapter();
            }
        }

        JsonAdapter {
            id: state

            property bool vertical: false
            property bool island: false
            property bool compact: false
        }
    }
}
