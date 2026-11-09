import QtQuick
import QtQuick.Layouts
import "../../theme" as Palette

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string iconSource: ""
    property bool active: false
    property bool iconOnly: false
    property color tint: Palette.Theme.accent
    readonly property color onTint: Qt.colorEqual(tint, Palette.Theme.accent) ? Palette.Theme.accentText : Palette.Theme.surfaceSolid
    property real shapeRadius: -1
    property var pulseKey: undefined
    signal clicked
    signal rightClicked

    implicitWidth: iconOnly ? 54 : 180
    implicitHeight: iconOnly ? 54 : 64

    readonly property real restRadius: shapeRadius >= 0 ? shapeRadius : (active ? Palette.Theme.radiusLarge : Palette.Theme.radiusLarge - 3)

    SequentialAnimation {
        id: pulse
        NumberAnimation {
            target: root
            property: "scale"
            to: 1.03
            duration: Palette.Theme.effectFast
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: Palette.Theme.motionDefault
            easing.type: Easing.OutBack
            easing.overshoot: Palette.Theme.springBouncy
        }
    }

    onActiveChanged: pulse.restart()
    onPulseKeyChanged: pulse.restart()

    scale: tileMouse.pressed ? 0.95 : 1
    Behavior on scale {
        enabled: !pulse.running
        SpatialMotion {
            fast: true
            bouncy: true
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: tileMouse.pressed ? Math.min(root.restRadius, Palette.Theme.radiusSmall) : root.restRadius
        color: root.iconOnly ? (root.active ? root.tint : Palette.Theme.surfaceContainerHigh) : (root.active ? Qt.alpha(root.tint, Palette.Theme.stateSelected) : Palette.Theme.surfaceContainerHigh)
        border.width: root.iconOnly || !root.active ? 0 : 1
        border.color: root.active ? Qt.alpha(root.tint, 0.1) : Palette.Theme.outlineSoft

        Behavior on radius {
            SpatialMotion {}
        }
        Behavior on color {
            ColorMotion {}
        }
        Behavior on border.color {
            ColorMotion {}
        }
    }

    StateLayer {
        radius: bg.radius
        tone: root.iconOnly && root.active ? root.onTint : Palette.Theme.textPrimary
        hovered: tileMouse.containsMouse
        pressed: tileMouse.pressed
    }

    Text {
        visible: root.iconOnly
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.onTint : Palette.Theme.textSecondary
        font.family: Palette.Theme.fontIcons
        font.weight: Palette.Theme.iconWeight
        font.pixelSize: Palette.Theme.iconSizeLarge

        Behavior on color {
            ColorMotion {}
        }
    }

    RowLayout {
        visible: !root.iconOnly
        anchors.fill: parent
        anchors.leftMargin: (root.height - 36) / 2
        anchors.rightMargin: Palette.Theme.spacingLarge
        spacing: Palette.Theme.spacingMedium

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: root.active ? 18 : Palette.Theme.radiusSmall
            color: root.active ? root.tint : Palette.Theme.surfaceContainerHighest

            Behavior on radius {
                SpatialMotion {}
            }
            Behavior on color {
                ColorMotion {}
            }

            Image {
                anchors.centerIn: parent
                width: Palette.Theme.iconSize
                height: width
                visible: root.iconSource !== ""
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Text {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                text: root.icon
                color: root.active ? root.onTint : Palette.Theme.textSecondary
                font.family: Palette.Theme.fontIcons
                font.weight: Palette.Theme.iconWeight
                font.pixelSize: Palette.Theme.iconSize

                Behavior on color {
                    ColorMotion {}
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Palette.Theme.textPrimary
                font.family: Palette.Theme.fontSans
                font.pixelSize: Palette.Theme.fontSizeBody
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: root.active ? root.tint : Palette.Theme.textMuted
                font.family: Palette.Theme.fontSans
                font.pixelSize: Palette.Theme.fontSizeXs
                elide: Text.ElideRight

                Behavior on color {
                    ColorMotion {}
                }
            }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }
}
