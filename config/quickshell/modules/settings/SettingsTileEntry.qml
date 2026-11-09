import QtQuick
import "../../components/material"

Tile {
    id: entry

    required property var panel
    required property var spec

    icon: spec.icon || ""
    title: spec.title
    active: panel.flag(spec.key)
    subtitle: active ? "On" : "Off"
    onClicked: panel.setFlag(spec.key, !active)
}
