pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.desktop

// Фоновый сервис: полноэкранный слой с видео на каждом экране (если включено в настройках).
// Поверх видео заново рисуются «лица» виджетов рабочего стола (иначе их закрывает видео).
Item {
    id: root
    property var plugin

    function opt(k, d) {
        return plugin ? plugin.get(k, d) : d;
    }
    readonly property string file: opt("file", "")
    readonly property bool wanted: opt("enabled", true) && opt("fullscreen", false) && file !== ""

    Variants {
        model: !root.wanted ? [] : root.opt("primaryOnly", false) ? Shell.screens.slice(0, 1) : Shell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            color: "black"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "angelos-livewall"
            mask: Region {}   // ввод проходит сквозь слой

            readonly property bool full: Shell.fullscreenOn(modelData.name)
            readonly property bool rest: root.opt("paused", false) || Motion.still || (root.opt("pauseFullscreen", true) && full)

            LiveVideo {
                anchors.fill: parent
                file: root.file
                paused: win.rest
                loop: root.opt("loop", true)
                speed: root.opt("speed", 1.0)
                scale: root.opt("scale", "Fill")
                fps: root.opt("fps", 0)
                zoom: root.opt("zoom", 1.0)
                offsetX: root.opt("offsetX", 0) / 100
                offsetY: root.opt("offsetY", 0) / 100
                // звук — только если включён явно; без него у плеера вообще нет аудиовыхода
                audio: root.opt("sound", false) && win.modelData === Shell.screens[0]
                muted: root.opt("muteFullscreen", true) && win.full
                volume: root.opt("volume", 80)
            }

            // виджеты рабочего стола поверх видео
            Item {
                id: faceArea
                anchors.fill: parent
                visible: root.opt("showWidgets", true)
                Repeater {
                    model: faceArea.visible ? DesktopWidgets.uidsFor(win.modelData.name) : []
                    DesktopWidgetHost {
                        required property string modelData
                        role: "face"
                        uid: modelData
                        screenName: win.modelData.name
                        area: faceArea
                    }
                }
            }
        }
    }
}
