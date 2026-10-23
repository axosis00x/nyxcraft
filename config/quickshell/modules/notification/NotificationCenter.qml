import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../../theme" as Palette
import "../../components/material"

Scope {
    id: root
    property var expandedGroups: ({})
    // Keep a local, immutable copy of each notification. Some web apps update a
    // single notification id for every new message, which otherwise replaces the
    // previous message in NotificationServer.trackedNotifications.
    property var notificationHistory: []
    // Keep image://qsimage handles alive after the notification closes so the
    // sender avatar remains available in the notification center.
    property var retainedNotificationLocks: ({})
    property int nextHistoryId: 0

    Component {
        id: notificationLockFactory
        RetainableLock {}
    }

    function isExpanded(appName) {
        return !!expandedGroups[appName];
    }

    function toggleGroup(appName) {
        var copy = Object.create(null);
        Object.keys(expandedGroups).forEach(key => copy[key] = expandedGroups[key]);
        copy[appName] = !copy[appName];
        expandedGroups = copy;
    }

    function buildGroups() {
        var list = notificationHistory;
        var groups = [];
        var index = Object.create(null);
        // notificationHistory is newest first, so keep the newest item at the
        // front of every app group as well.
        for (var i = 0; i < list.length; i++) {
            var n = list[i];
            var key = n.appName || "Notifications";
            if (index[key] === undefined) {
                index[key] = groups.length;
                groups.push({
                    appName: key,
                    items: [n]
                });
            } else {
                groups[index[key]].items.push(n);
            }
        }
        return groups;
    }

    readonly property var groupedNotifications: buildGroups()
    property bool doNotDisturb: false
    property var toastNotification: null
    property bool toastHeld: false
    readonly property var rawNotifications: server.trackedNotifications.values
    readonly property var notifications: notificationHistory
    readonly property int count: notifications.length

    function scrub(text) {
        return String(text || "")
            .replace(/<br\s*\/?\s*>/gi, "\n")
            .replace(/<\/p\s*>/gi, "\n")
            .replace(/<[^>]*>/g, "")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "'")
            .replace(/&nbsp;/g, " ")
            // Browsers often prepend the website origin to web-app
            // notifications. It's source metadata, not the message body.
            .replace(/^[ \t]*(?:(?:https?:\/\/)?(?:www\.)?[\w-]+(?:\.[\w-]+)+(?:\/[^\s]*)?)[ \t]*$/gim, "")
            .replace(/\n[ \t]*\n(?:[ \t]*\n)+/g, "\n\n")
            .replace(/^[ \t\n]+|[ \t\n]+$/g, "");
    }

    // Browser notifications often put the web-app origin on its own body
    // line. Use that origin to identify the site while keeping it out of the
    // displayed message and grouping web apps separately from the browser.
    function websiteApp(notification) {
        if (!notification)
            return null;
        var lines = String(notification.body || "")
            .replace(/<br\s*\/?\s*>/gi, "\n")
            .replace(/<\/p\s*>/gi, "\n")
            .replace(/<[^>]*>/g, "")
            .replace(/&amp;/g, "&")
            .replace(/&nbsp;/g, " ")
            .split(/\r?\n/);
        var knownSites = [
            { host: "whatsapp.com", name: "WhatsApp", icon: "whatsapp" },
            { host: "instagram.com", name: "Instagram", icon: "instagram" },
            { host: "facebook.com", name: "Facebook", icon: "facebook" },
            { host: "messenger.com", name: "Messenger", icon: "fbmessenger" },
            { host: "telegram.org", name: "Telegram", icon: "telegram" },
            { host: "discord.com", name: "Discord", icon: "discord" },
            { host: "signal.org", name: "Signal", icon: "signal-desktop" },
            { host: "slack.com", name: "Slack", icon: "slack" },
            { host: "reddit.com", name: "Reddit", icon: "reddit" },
            { host: "x.com", name: "X", icon: "twitter-x" },
            { host: "twitter.com", name: "X", icon: "twitter-x" },
            { host: "youtube.com", name: "YouTube", icon: "youtube" },
            { host: "tiktok.com", name: "TikTok", icon: "tiktok" },
            { host: "gmail.com", name: "Gmail", icon: "gmail" }
        ];
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].trim().match(/^(?:https?:\/\/)?(?:www\.)?([a-z0-9-]+(?:\.[a-z0-9-]+)+)(?:\/[^\s]*)?$/i);
            if (!match)
                continue;
            var host = match[1].toLowerCase();
            for (var j = 0; j < knownSites.length; j++) {
                var site = knownSites[j];
                if (host === site.host || host.endsWith("." + site.host))
                    return site;
            }
        }
        return null;
    }

    function notificationSourceName(notification) {
        if (!notification)
            return "Notifications";
        if (notification.sourceName)
            return notification.sourceName;
        var site = websiteApp(notification);
        return site ? site.name : (notification.appName || notification.desktopEntry || "Notifications");
    }

    function notificationSourceIconName(notification) {
        if (!notification)
            return "";
        if (notification.sourceIconName)
            return notification.sourceIconName;
        var site = websiteApp(notification);
        if (site)
            return site.icon;
        return notification.appIcon || browserIconName(notification) || notification.desktopEntry || notification.appName || "";
    }

    function browserIconName(notification) {
        var identity = String((notification.desktopEntry || "") + " " + (notification.appName || "")).toLowerCase();
        if (/helium/.test(identity))
            return "helium";
        if (/zen/.test(identity))
            return "zen-browser";
        if (/firefox/.test(identity))
            return "firefox";
        if (/chromium/.test(identity))
            return "chromium";
        if (/brave/.test(identity))
            return "brave-browser";
        if (/chrome|google-chrome/.test(identity))
            return "google-chrome";
        if (/edge/.test(identity))
            return "microsoft-edge";
        return "";
    }

    function releaseNotificationLock(historyId) {
        var locks = Object.assign({}, retainedNotificationLocks);
        var lock = locks[historyId];
        if (!lock)
            return;
        delete locks[historyId];
        lock.locked = false;
        lock.destroy();
        retainedNotificationLocks = locks;
    }

    function notificationImage(notification) {
        if (!notification)
            return "";
        // RetainableLock keeps image://qsimage handles valid after close.
        if (notification.historyId !== undefined) {
            return notification.image || "";
        } else if (notification.image) {
            return notification.image;
        }
        return "";
    }

    function themeIconPath(iconName) {
        if (!iconName || !Quickshell.hasThemeIcon(iconName))
            return "";
        return Quickshell.iconPath(iconName);
    }

    function notificationSourceIcon(notification) {
        if (!notification)
            return "";
        var iconName = notificationSourceIconName(notification);
        if (!iconName)
            return "";
        if (/^(\/|file:|qrc:)/.test(iconName))
            return iconName;
        // Notification appIcon should be a theme name or a file URL. Treat
        // image-provider URLs as untrusted here: a stale qsimage handle can
        // render Quickshell's purple missing-texture tile.
        if (/^image:/i.test(iconName))
            iconName = "";
        var icon = themeIconPath(iconName);
        if (icon)
            return icon;
        var browserIcon = browserIconName(notification);
        return themeIconPath(browserIcon);
    }

    function remember(notification) {
        if (!notification)
            return;
        var records = notificationHistory.slice();
        // A replacement uses the same id. Preserve its old text, but make only
        // the newest record eligible to dismiss the live system notification.
        for (var i = 0; i < records.length; i++) {
            if (records[i].notificationId === notification.id)
                records[i].live = false;
        }

        var historyId = ++nextHistoryId;
        if (String(notification.image || "").indexOf("image://qsimage") === 0) {
            var lock = notificationLockFactory.createObject(root, {
                object: notification,
                locked: true
            });
            if (lock) {
                var locks = Object.assign({}, retainedNotificationLocks);
                locks[historyId] = lock;
                retainedNotificationLocks = locks;
            }
        }

        records.unshift({
            historyId: historyId,
            notificationId: notification.id,
            appName: notificationSourceName(notification),
            sourceName: notificationSourceName(notification),
            sourceIconName: notificationSourceIconName(notification),
            image: notification.image || "",
            summary: notification.summary || "Notification",
            body: notification.body || "",
            urgency: notification.urgency,
            resident: notification.resident,
            receivedAt: notification.lastGeneration ? 0 : Date.now(),
            live: true
        });

        // Bound the local history so a busy chat cannot grow the control center
        // without limit. Keep the most recent 20 messages per application.
        var perApp = Object.create(null);
        records = records.filter(record => {
            var count = (perApp[record.appName] || 0) + 1;
            perApp[record.appName] = count;
            return count <= 20;
        }).slice(0, 120);
        var keptHistoryIds = Object.create(null);
        records.forEach(record => keptHistoryIds[record.historyId] = true);
        Object.keys(retainedNotificationLocks).forEach(id => {
            if (!keptHistoryIds[id])
                root.releaseNotificationLock(id);
        });
        notificationHistory = records;
    }

    function dismissRecord(record) {
        if (!record)
            return;
        var notification = liveNotification(record);
        notificationHistory = notificationHistory.filter(item => item.historyId !== record.historyId);
        releaseNotificationLock(record.historyId);
        if (notification)
            notification.dismiss();
    }

    // Keep live QObject values out of notificationHistory. History is passed to
    // ListView as a JS model; placing actions/QObjects in it can crash Qt while
    // it converts the nested notification-action sequence.
    function liveNotification(record) {
        if (!record || !record.live)
            return null;
        for (var i = 0; i < rawNotifications.length; i++) {
            if (rawNotifications[i].id === record.notificationId)
                return rawNotifications[i];
        }
        return null;
    }

    function hasDefaultAction(record) {
        var notification = liveNotification(record);
        if (!notification)
            return false;
        var actions = notification.actions || [];
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                return true;
        }
        return false;
    }

    function invokeDefaultAction(record) {
        var notification = liveNotification(record);
        if (!notification)
            return false;
        var actions = notification.actions || [];
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default") {
                actions[i].invoke();
                return true;
            }
        }
        return false;
    }

    function clearAll() {
        toastTimer.stop();
        toastHeld = false;
        toastVisible = false;
        toastNotification = null;
        notificationHistory = [];

        var items = rawNotifications.slice();
        for (var i = 0; i < items.length; i++)
            items[i].dismiss();
        Object.keys(retainedNotificationLocks).forEach(id => releaseNotificationLock(id));
    }

    function hideToast() {
        toastTimer.stop();
        toastHeld = false;
        toastVisible = false;
        toastNotification = null;
    }

    // A destroyed notification object reads back as null — never show an
    // empty popup for it.
    onToastNotificationChanged: if (!toastNotification)
        toastVisible = false

    function toggleDnd() {
        root.doNotDisturb = !root.doNotDisturb;
    }

    onDoNotDisturbChanged: {
        if (doNotDisturb)
            hideToast();
    }

    function setDnd(enabled) {
        root.doNotDisturb = enabled;
        hideToast();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.remember(notification);
            root.toastNotification = notification;
            // If the sender closes or replaces it (or it expires) while the
            // popup is up, hide the popup instead of leaving an empty card.
            notification.closed.connect(() => {
                if (root.toastNotification === notification)
                    root.hideToast();
            });

            if (!root.doNotDisturb && !notification.lastGeneration) {
                root.toastVisible = true;
                if (root.toastHeld)
                    toastTimer.stop();
                else
                    toastTimer.restart();
            }
        }
    }

    IpcHandler {
        target: "notifications"
        function clear(): void {
            root.clearAll();
        }
        function toggleDnd(): void {
            root.toggleDnd();
        }
        function setDnd(enabled: bool): void {
            root.setDnd(enabled);
        }
    }

    // The popup itself is drawn by the central notch (NotificationPeek in
    // components/overlay); this only decides when it's up. Hovering it
    // holds it open.
    property bool toastVisible: false

    function holdToast(held) {
        toastHeld = held;
        if (held)
            toastTimer.stop();
        else if (toastVisible)
            toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: root.toastNotification && root.toastNotification.urgency === NotificationUrgency.Critical ? 6000 : 2500
        onTriggered: root.toastVisible = false
    }
}
