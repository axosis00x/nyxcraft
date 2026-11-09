import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import "../../theme" as Palette

ClippingRectangle {
    id: root

    property real initialSize: height * 0.4

    readonly property string userFile: Quickshell.env("HOME") + "/.face"
    readonly property url defaultFile: Qt.resolvedUrl("../../assets/pfp.png")
    property bool hasUserFile: false

    property int revision: 0

    radius: width / 2
    color: Palette.Theme.surfaceContainerHigh

    FileView {
        path: root.userFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.hasUserFile = true;
            root.revision++;
        }
        onLoadFailed: root.hasUserFile = false
    }

    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
        color: Palette.Theme.textPrimary
        font.family: Palette.Theme.fontSans
        font.pixelSize: root.initialSize
        font.weight: Font.DemiBold
    }

    Image {
        id: image
        anchors.fill: parent
        source: root.hasUserFile ? "file://" + root.userFile + "?r=" + root.revision : root.defaultFile
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
    }
}
