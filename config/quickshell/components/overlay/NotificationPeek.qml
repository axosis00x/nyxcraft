import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../material"
import "../../theme" as Palette

// A new notification, morphing out of the top notch (CenterOverlay puts it
// on the top stage while no top panel is open). Minimal: sender image, title,
// and a short body preview. Hovering holds it open and unfolds the rest of
// the body and any actions; clicking runs its default action.
Item {
    id: root

    property var center: null

    readonly property var notification: center ? center.toastNotification : null
    // CenterOverlay shows this on the stage while true.
    readonly property bool wanted: center !== null && center.toastVisible && notification !== null
    readonly property bool critical: notification !== null && notification.urgency === NotificationUrgency.Critical
    readonly property bool open: hover.hovered
    readonly property var actions: notification ? Array.prototype.filter.call(notification.actions, a => a.identifier !== "default") : []

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 28

    // Don't take clicks while faded out on the stage.
    enabled: wanted
    // Hidden once faded out: a transparent item still catches hover, which
    // blocked the power and tool menus beneath it on the top stage.
    visible: opacity > 0.01

    function hide() {
        if (center)
            center.hideToast();
    }

    function invokeAction(action) {
        var current = root.notification;
        if (!current || !action)
            return;
        var dismiss = !current.resident;
        root.hide();
        action.invoke();
        if (dismiss && current && current.tracked)
            current.dismiss();
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (root.center)
            root.center.holdToast(hovered)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var list = root.notification ? root.notification.actions : [];
            for (var i = 0; i < list.length; i++) {
                if (list[i].identifier === "default") {
                    root.invokeAction(list[i]);
                    break;
                }
            }
            root.hide();
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Fill the notification row with the sender avatar, and badge it
            // with the source app icon. If there is no avatar, show the app
            // icon in the full tile.
            ClippingRectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 48
                implicitWidth: 48
                implicitHeight: 48
                radius: Palette.Theme.radiusSmall
                color: "transparent"

                Image {
                    id: avatar
                    anchors.fill: parent
                    source: root.center && root.notification ? root.center.notificationImage(root.notification) : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 64
                    sourceSize.height: 64
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Image {
                    id: sourceIcon
                    anchors.fill: parent
                    source: root.center && root.notification ? root.center.notificationSourceIcon(root.notification) : ""
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 64
                    sourceSize.height: 64
                    asynchronous: true
                    visible: avatar.status !== Image.Ready && status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    visible: avatar.status !== Image.Ready && sourceIcon.status !== Image.Ready
                    radius: Palette.Theme.radiusSmall
                    color: Qt.tint(Palette.Theme.surfaceContainerHigh, Qt.alpha(root.critical ? Palette.Theme.errorColor : Palette.Theme.hueFor(root.notification ? root.notification.appName : ""), Palette.Theme.stateSelected))
                    border.width: 1
                    border.color: Palette.Theme.outlineSoft
                }

                Text {
                    anchors.centerIn: parent
                    visible: avatar.status !== Image.Ready && sourceIcon.status !== Image.Ready
                    text: root.critical ? "priority_high" : "notifications"
                    // Each app gets its own stable hue.
                    color: root.critical ? Palette.Theme.errorColor : Palette.Theme.hueFor(root.notification ? root.notification.appName : "")
                    font.family: Palette.Theme.fontIcons
                    font.weight: Palette.Theme.iconWeight
                    font.pixelSize: Palette.Theme.iconSizeSmall
                }

                Item {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 22
                    height: 22
                    visible: avatar.status === Image.Ready && sourceIcon.status === Image.Ready

                    Image {
                        anchors.fill: parent
                        source: root.center && root.notification ? root.center.notificationSourceIcon(root.notification) : ""
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: 48
                        sourceSize.height: 48
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: root.notification ? (root.notification.summary || "Notification") : ""
                        color: Palette.Theme.textPrimary
                        font.family: Palette.Theme.fontSans
                        font.pixelSize: Palette.Theme.fontSizeBody
                        font.weight: Font.DemiBold
                        wrapMode: Text.WrapAnywhere
                        // Notification titles often contain the sender's full
                        // name. Give them enough lines to wrap before eliding.
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: text !== ""
                    text: root.center && root.notification ? root.center.scrub(root.notification.body) : ""
                    textFormat: Text.PlainText
                    color: Palette.Theme.textSecondary
                    font.family: Palette.Theme.fontSans
                    font.pixelSize: Palette.Theme.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: root.open ? 4 : 2
                    elide: Text.ElideRight
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                icon: "close"
                implicitWidth: 24
                implicitHeight: 24
                iconSize: Palette.Theme.iconSizeSmall
                opacity: root.open ? 1 : 0
                onClicked: {
                    if (root.notification)
                        root.notification.dismiss();
                    root.hide();
                }

                Behavior on opacity {
                    EffectMotion {}
                }
            }
        }

        // Actions, unfolded while hovered.
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 60
            visible: root.open && root.actions.length > 0
            spacing: 6

            Repeater {
                model: root.open ? root.actions : []

                ActionChip {
                    required property var modelData
                    label: modelData.text
                    chipHeight: 24
                    fontPixelSize: Palette.Theme.fontSizeXs
                    horizontalPadding: 12
                    // Hide first: invoking can close the notification,
                    // which destroys this chip mid-handler.
                    onClicked: {
                        var action = modelData;
                        root.invokeAction(action);
                    }
                }
            }
        }
    }
}
