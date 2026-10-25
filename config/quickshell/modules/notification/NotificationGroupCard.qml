import QtQuick
import QtQuick.Layouts
import "../../components/material"
import "../../theme" as Palette

ColumnLayout {
    id: root

    required property var notificationCenter
    required property var group // { appName, items: [...] }
    // The newest group shows its top card in full; the rest are compact
    // (they open on hover), so the list has a clear size hierarchy.
    property bool featured: true
    readonly property bool expanded: notificationCenter ? notificationCenter.isExpanded(group.appName) : false
    readonly property bool hasStack: group.items.length > 1

    spacing: 8

    Item {
        Layout.fillWidth: true
        // The two offset stack layers extend below the main card. Include that
        // depth in the delegate size so they cannot overlap the next group.
        implicitHeight: topCard.implicitHeight + (!root.expanded ? Math.min(2, root.group.items.length - 1) * 6 : 0)

        Repeater {
            model: root.expanded ? 0 : Math.min(2, root.group.items.length - 1)
            delegate: Rectangle {
                required property int index
                property int depth: index + 1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: depth * 6
                    rightMargin: depth * 6
                    topMargin: depth * 6
                }
                height: topCard.implicitHeight
                radius: Palette.Theme.radiusMedium
                color: Palette.Theme.surfaceContainer
                opacity: 0.6 - depth * 0.2
                z: -depth
            }
        }

        NotificationCard {
            id: topCard
            width: parent.width
            notification: root.group.items[0]
            iconSource: root.notificationCenter ? root.notificationCenter.notificationImage(root.group.items[0]) : ""
            sourceIconSource: root.notificationCenter ? root.notificationCenter.notificationSourceIcon(root.group.items[0]) : ""
            bodyText: root.notificationCenter ? root.notificationCenter.scrub(root.group.items[0].body) : ""
            actionTarget: root.notificationCenter ? root.notificationCenter.liveNotification(root.group.items[0]) : null
            canDismiss: root.group.items[0].live
            dismissOnActivate: !root.hasStack
                && root.notificationCenter
                && root.notificationCenter.hasDefaultAction(root.group.items[0])
            expandable: root.hasStack
            expanded: root.expanded
            onDismissed: root.notificationCenter.dismissRecord(root.group.items[0])
            compact: (root.hasStack && !root.expanded) || !root.featured
            count: root.group.items.length
            onActivated: {
                if (root.hasStack)
                    root.notificationCenter.toggleGroup(root.group.appName);
                else
                    root.notificationCenter.invokeDefaultAction(root.group.items[0]);
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: root.expanded && root.hasStack

        Repeater {
            model: root.expanded ? root.group.items.slice(1) : []
            delegate: NotificationCard {
                required property var modelData
                Layout.fillWidth: true
                notification: modelData
                iconSource: root.notificationCenter ? root.notificationCenter.notificationImage(modelData) : ""
                sourceIconSource: root.notificationCenter ? root.notificationCenter.notificationSourceIcon(modelData) : ""
                bodyText: root.notificationCenter ? root.notificationCenter.scrub(modelData.body) : ""
                actionTarget: root.notificationCenter ? root.notificationCenter.liveNotification(modelData) : null
                canDismiss: modelData.live
                dismissOnActivate: root.notificationCenter && root.notificationCenter.hasDefaultAction(modelData)
                onActivated: root.notificationCenter.invokeDefaultAction(modelData)
                onDismissed: root.notificationCenter.dismissRecord(modelData)
            }
        }
    }

}
