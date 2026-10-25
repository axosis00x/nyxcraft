import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../../components/material"
import "../../theme" as Palette

Surface {
    id: card
    required property var notification
    property bool compact: false
    property string iconSource: ""
    property string sourceIconSource: ""
    property string bodyText: ""
    property var actionTarget: notification
    property bool canDismiss: true
    property bool dismissOnActivate: true
    property bool expandable: false
    property bool expanded: false
    property int clockTick: 0
    signal dismissed
    signal activated
    function actionLabel(action) {
        var label = action && action.text ? action.text.trim() : "";
        return /^(activate|default)$/i.test(label) ? "Open" : label;
    }
    function dismissNotification() {
        card.dismissed();
        // A handler of `dismissed` (the notification center's record
        // removal) may already have closed it; dismissing a closed
        // notification again logs "Cannot close destroyed notification".
        if (card.canDismiss && card.actionTarget && card.actionTarget.tracked)
            card.actionTarget.dismiss();
    }
    // Notification history records carry a receivedAt (ms since epoch) set
    // when captured; the live toast passes the raw Notification object
    // instead, which has no such field, so it just shows nothing.
    function timeAgo(receivedAt) {
        if (!receivedAt)
            return "";
        var diffSec = Math.max(0, (Date.now() - receivedAt) / 1000);
        if (diffSec < 60)
            return "now";
        if (diffSec < 3600)
            return Math.floor(diffSec / 60) + "m ago";
        if (diffSec < 86400)
            return Math.floor(diffSec / 3600) + "h ago";
        return Math.floor(diffSec / 86400) + "d ago";
    }
    // Compact cards morph open on hover: the full text springs into view
    // and the corners round out, then they settle back when the pointer
    // leaves. Full cards always show everything.
    readonly property bool open: !compact || cardHover.hovered
    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical
    // How many notifications this card stands for (a stacked group), shown
    // as a pill beside the title.
    property int count: 1

    height: implicitHeight
    implicitHeight: content.implicitHeight + 24
    radius: open && compact ? Palette.Theme.radiusLarge : Palette.Theme.radiusMedium
    color: Palette.Theme.surfaceContainer
    tint: critical ? Palette.Theme.errorColor : Palette.Theme.surfaceTint
    tintOpacity: critical ? 0.12 : 0.03
    outlineWidth: critical ? 1 : 0
    outlineColor: Qt.alpha(Palette.Theme.errorColor, 0.5)

    Behavior on height {
        SpatialMotion {
            fast: true
        }
    }
    Behavior on radius {
        SpatialMotion {}
    }

    // Refresh the time binding periodically. Keeping this as a property
    // change means ListView can safely reuse a card for another notification.
    Timer {
        interval: 30000
        running: !!(card.notification && card.notification.receivedAt)
        repeat: true
        triggeredOnStart: false
        onTriggered: card.clockTick++
    }

    // Hover over the whole card, including its buttons.
    HoverHandler {
        id: cardHover
    }

    StateLayer {
        radius: card.radius
        hovered: cardHover.hovered
        pressed: cardMouse.pressed
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: card.expandable || card.dismissOnActivate ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            var dismiss = card.dismissOnActivate;
            card.activated();
            if (dismiss)
                card.dismissNotification();
        }
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
            rightMargin: 44
        }
        spacing: 12

        // Use the sender avatar as the full tile and badge it with the source
        // app icon. The source icon fills the tile when there is no avatar.
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
                source: card.iconSource
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    EffectMotion {
                        fast: false
                    }
                }
            }

            Image {
                id: sourceIcon
                anchors.fill: parent
                source: card.sourceIconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                sourceSize.width: 128
                sourceSize.height: 128
                visible: avatar.status !== Image.Ready && status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                visible: avatar.status !== Image.Ready && sourceIcon.status !== Image.Ready
                radius: Palette.Theme.radiusSmall
                color: Qt.tint(Palette.Theme.surfaceContainerHigh, Qt.alpha(card.critical ? Palette.Theme.errorColor : Palette.Theme.hueFor(card.notification ? card.notification.appName : ""), Palette.Theme.stateSelected))
                border.width: 1
                border.color: Palette.Theme.outlineSoft
            }

            Text {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready && sourceIcon.status !== Image.Ready
                text: card.critical ? "priority_high" : "notifications"
                // Each app gets its own stable hue.
                    color: card.critical ? Palette.Theme.errorColor : Palette.Theme.hueFor(card.notification ? card.notification.appName : "")
                font.family: Palette.Theme.fontIcons
                font.weight: Palette.Theme.iconWeight
                font.pixelSize: Palette.Theme.iconSize
            }

            Item {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 22
                height: 22
                visible: avatar.status === Image.Ready && sourceIcon.status === Image.Ready

                Image {
                    anchors.fill: parent
                    source: card.sourceIconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    sourceSize.width: 64
                    sourceSize.height: 64
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 2

            // Title .......... time  [count]  ✕
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: card.notification ? (card.notification.summary || "Notification") : ""
                    color: Palette.Theme.textPrimary
                    font.family: Palette.Theme.fontSans
                    font.pixelSize: Palette.Theme.fontSizeBody
                    font.weight: Font.DemiBold
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                Text {
                    id: timeAgoText
                    visible: text !== ""
                    text: {
                        card.clockTick;
                        return card.notification ? card.timeAgo(card.notification.receivedAt) : "";
                    }
                    color: Palette.Theme.textMuted
                    font.family: Palette.Theme.fontSans
                    font.pixelSize: Palette.Theme.fontSizeXs
                }

                Rectangle {
                    visible: card.count > 1
                    implicitWidth: Math.max(22, countText.implicitWidth + (card.expandable ? 30 : 10))
                    implicitHeight: 18
                    radius: height / 2
                    color: Palette.Theme.accentTonal

                    Text {
                        id: countText
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        text: card.count
                        color: Palette.Theme.accent
                        font.family: Palette.Theme.fontSans
                        font.pixelSize: Palette.Theme.fontSizeXs
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: card.expandable
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: card.expanded ? "expand_less" : "expand_more"
                        color: Palette.Theme.accent
                        font.family: Palette.Theme.fontIcons
                        font.weight: Palette.Theme.iconWeight
                        font.pixelSize: Palette.Theme.iconSizeSmall
                    }
                }

            }

            Text {
                text: card.bodyText
                textFormat: Text.PlainText
                Layout.minimumWidth: 0
                color: Palette.Theme.textSecondary
                font.family: Palette.Theme.fontSans
                font.pixelSize: Palette.Theme.fontSizeSmall
                lineHeight: 1.15
                wrapMode: Text.WrapAnywhere
                maximumLineCount: card.open ? 5 : 3
                elide: Text.ElideRight
                visible: text !== ""
                Layout.fillWidth: true
                Layout.rightMargin: 4
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8
                visible: card.actionTarget && card.actionTarget.actions && card.actionTarget.actions.length > 0
                Repeater {
                    model: card.actionTarget && card.actionTarget.actions ? card.actionTarget.actions : []
                    delegate: ActionChip {
                        required property var modelData
                        label: card.actionLabel(modelData)
                        chipHeight: 24
                        fontPixelSize: Palette.Theme.fontSizeXs
                        horizontalPadding: 14
                        // The action goes first (an app expects it before
                        // the close), and it may destroy this chip by closing
                        // the notification, so only plain references are
                        // used after it.
                        onClicked: {
                            var c = card;
                            var dismiss = c.canDismiss && c.actionTarget && !c.actionTarget.resident;
                            modelData.invoke();
                            if (dismiss)
                                c.dismissNotification();
                        }
                    }
                }
            }
        }
    }

    // Dismiss, centred on the card's right; faded in on hover.
    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        icon: "close"
        implicitWidth: 26
        implicitHeight: 26
        iconSize: Palette.Theme.iconSizeSmall
        opacity: cardHover.hovered ? 1 : 0
        onClicked: card.dismissNotification()

        Behavior on opacity {
            EffectMotion {}
        }
    }
}
