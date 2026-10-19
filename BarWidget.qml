import QtQuick
import qs.config
import qs.services
import qs.widgets

Item {
    id: root
    property var plugin
    property string screenName
    property var barWindow
    readonly property bool on: plugin ? plugin.get("enabled", true) : true
    readonly property bool paused: plugin ? plugin.get("paused", false) : false

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: Skin.px(2)
        PxButton {
            compact: true
            icon: "power"
            checkable: true
            checked: root.on
            onClicked: if (root.plugin)
                root.plugin.set("enabled", !root.on)
        }
        PxButton {
            visible: root.on
            compact: true
            icon: root.paused ? "play" : "pause"
            onClicked: if (root.plugin)
                root.plugin.set("paused", !root.paused)
        }
    }
}
