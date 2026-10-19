import QtQuick
import qs.config
import qs.services
import qs.widgets

// Карточка с живыми обоями на рабочем столе (рамку «live-wallpaper.exe» рисует angelOS). Без звука.
Item {
    id: root
    property var plugin
    property string screenName
    property var widget

    implicitWidth: Skin.px(240)
    implicitHeight: Skin.px(135)

    readonly property bool on: plugin ? plugin.get("enabled", true) : true
    readonly property string file: on && plugin ? plugin.get("file", "") : ""

    LiveVideo {
        anchors.fill: parent
        file: root.file
        paused: (plugin ? plugin.get("paused", false) : false) || Motion.still
        loop: plugin ? plugin.get("loop", true) : true
        speed: plugin ? plugin.get("speed", 1.0) : 1.0
        scale: plugin ? plugin.get("scale", "Fill") : "Fill"
        fps: plugin ? plugin.get("fps", 0) : 0
        zoom: plugin ? plugin.get("zoom", 1.0) : 1.0
        offsetX: (plugin ? plugin.get("offsetX", 0) : 0) / 100
        offsetY: (plugin ? plugin.get("offsetY", 0) : 0) / 100
    }
    PxText {
        anchors.centerIn: parent
        visible: root.file === ""
        text: root.on ? I18n.t("Выбери файл в настройках плагина", "Pick a file in the plugin settings") : I18n.t("Живые обои выключены", "Live wallpaper is off")
        color: Skin.textDim
    }
}
