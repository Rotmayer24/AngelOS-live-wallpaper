import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

Column {
    id: root
    property var plugin
    width: parent ? parent.width : 400
    spacing: Skin.px(10)

    function g(k, d) {
        return plugin ? plugin.get(k, d) : d;
    }
    function s(k, v) {
        if (plugin)
            plugin.set(k, v);
    }
    function expand(p) {
        return p.startsWith("~/") ? Quickshell.env("HOME") + p.slice(1) : p === "~" ? Quickshell.env("HOME") : p;
    }

    // ---- автопоиск живых обоев ----
    property var found: []
    property bool scanning: false
    readonly property string scanDir: expand(g("dir", "~/Pictures")).replace(/\/+$/, "")
    function scan() {
        if (!plugin || finder.running)
            return;
        const e = ["mp4", "webm", "mkv", "mov"].concat(g("scanGif", true) ? ["gif"] : []).concat(g("scanWebp", false) ? ["webp"] : []);
        const args = ["find", "-L", scanDir, "-maxdepth", g("recursive", true) ? "8" : "1", "-type", "f", "-not", "-path", "*/.*", "("];
        e.forEach((x, i) => {
            if (i)
                args.push("-o");
            args.push("-iname", "*." + x);
        });
        args.push(")");
        scanning = true;
        finder.command = args;
        finder.running = true;
    }
    onPluginChanged: scan()
    Component.onCompleted: scan()
    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: root.found = text.split("\n").filter(l => l !== "").sort()
        }
        onExited: root.scanning = false
    }

    PxGroup {
        title: I18n.t("Живые обои", "Live wallpaper")
        icon: "power"
        width: parent.width

        SettingRow {
            label: I18n.t("Включены", "Enabled")
            hint: I18n.t("Выключено — слой, карточка и проигрыватель полностью остановлены и выгружены", "Off — the layer, the card and the player are fully stopped and unloaded")
            PxToggle {
                checked: root.g("enabled", true)
                onToggled: c => root.s("enabled", c)
            }
        }
    }

    PxGroup {
        title: I18n.t("Библиотека", "Library")
        icon: "image"
        width: parent.width

        SettingRow {
            label: I18n.t("Папка поиска", "Search folder")
            PxField {
                width: parent.width
                text: root.g("dir", "~/Pictures")
                placeholder: "~/Pictures"
                onAccepted: {
                    root.s("dir", text.trim() === "" ? "~/Pictures" : text.trim());
                    root.scan();
                }
            }
        }
        SettingRow {
            label: I18n.t("Искать в подпапках", "Search subfolders")
            PxToggle {
                checked: root.g("recursive", true)
                onToggled: c => {
                    root.s("recursive", c);
                    root.scan();
                }
            }
        }
        SettingRow {
            label: I18n.t("Включать GIF", "Include GIF")
            PxToggle {
                checked: root.g("scanGif", true)
                onToggled: c => {
                    root.s("scanGif", c);
                    root.scan();
                }
            }
        }
        SettingRow {
            label: I18n.t("Включать WebP", "Include WebP")
            hint: I18n.t("В папке картинок это часто статичные файлы", "In a pictures folder these are often still images")
            PxToggle {
                checked: root.g("scanWebp", false)
                onToggled: c => {
                    root.s("scanWebp", c);
                    root.scan();
                }
            }
        }
        SettingRow {
            label: I18n.t("Найдено", "Found") + ": " + root.found.length
            PxCombo {
                width: parent.width
                placeholder: root.scanning ? I18n.t("Ищу…", "Scanning…") : I18n.t("Выбери обои", "Pick a wallpaper")
                model: root.found.map(p => ({
                            "value": p,
                            "label": p.startsWith(root.scanDir + "/") ? p.slice(root.scanDir.length + 1) : p
                        }))
                currentValue: root.g("file", "")
                onActivated: v => {
                    root.s("file", v);
                    pathField.text = v;
                }
            }
        }
        Row {
            spacing: Skin.px(6)
            PxButton {
                text: I18n.t("Обновить", "Rescan")
                onClicked: root.scan()
            }
            PxButton {
                text: I18n.t("Случайные", "Random")
                enabled: root.found.length > 0
                onClicked: {
                    const p = root.found[Math.floor(Math.random() * root.found.length)];
                    root.s("file", p);
                    pathField.text = p;
                }
            }
        }
        SettingRow {
            label: I18n.t("Или путь вручную", "Or a path by hand")
            PxField {
                id: pathField
                width: parent.width
                text: root.g("file", "")
                placeholder: "~/Videos/wallpaper.mp4"
                onAccepted: apply.clicked()
            }
        }
        PxButton {
            id: apply
            text: I18n.t("Применить", "Apply")
            accent: true
            onClicked: {
                const p = root.expand(pathField.text.trim());
                if (p !== "" && !/\.(mp4|webm|mkv|mov|gif|webp)$/i.test(p)) {
                    status.text = I18n.t("Формат не поддерживается", "Unsupported format");
                    return;
                }
                root.s("file", p);
                status.text = p === "" ? I18n.t("Файл сброшен", "File cleared") : I18n.t("Применено", "Applied");
            }
        }
        PxText {
            id: status
            text: ""
            color: Skin.textDim
        }
    }

    PxGroup {
        title: I18n.t("Показ", "Display")
        icon: "monitor"
        width: parent.width

        SettingRow {
            label: I18n.t("На весь экран (слой за окнами)", "Fullscreen layer (behind windows)")
            hint: I18n.t("Выключено — только карточка-виджет (ПКМ → Вид)", "Off — only the desktop card widget (right-click → View)")
            PxToggle {
                checked: root.g("fullscreen", false)
                onToggled: c => root.s("fullscreen", c)
            }
        }
        SettingRow {
            label: I18n.t("Виджеты рабочего стола поверх видео", "Desktop widgets above the video")
            PxToggle {
                checked: root.g("showWidgets", true)
                onToggled: c => root.s("showWidgets", c)
            }
        }
        SettingRow {
            label: I18n.t("Масштаб", "Scale")
            PxCombo {
                width: Skin.px(160)
                model: [
                    {
                        "value": "Fill",
                        "label": I18n.t("Заполнить", "Fill")
                    },
                    {
                        "value": "Fit",
                        "label": I18n.t("Вписать", "Fit")
                    },
                    {
                        "value": "Stretch",
                        "label": I18n.t("Растянуть", "Stretch")
                    }
                ]
                currentValue: root.g("scale", "Fill")
                onActivated: v => root.s("scale", v)
            }
        }
        SettingRow {
            label: I18n.t("Увеличение", "Zoom") + " " + Math.round(root.g("zoom", 1.0) * 100) + "%"
            PxSlider {
                width: parent.width
                from: 0.25
                to: 3
                stepSize: 0.05
                decimals: 2
                suffix: "×"
                value: root.g("zoom", 1.0)
                onReleased: v => root.s("zoom", v)
            }
        }
        SettingRow {
            label: I18n.t("Сдвиг по горизонтали", "Horizontal shift")
            PxSlider {
                width: parent.width
                from: -50
                to: 50
                stepSize: 1
                suffix: "%"
                value: root.g("offsetX", 0)
                onReleased: v => root.s("offsetX", Math.round(v))
            }
        }
        SettingRow {
            label: I18n.t("Сдвиг по вертикали", "Vertical shift")
            PxSlider {
                width: parent.width
                from: -50
                to: 50
                stepSize: 1
                suffix: "%"
                value: root.g("offsetY", 0)
                onReleased: v => root.s("offsetY", Math.round(v))
            }
        }
        PxButton {
            text: I18n.t("Сбросить масштаб и сдвиг", "Reset zoom and shift")
            onClicked: {
                root.s("zoom", 1.0);
                root.s("offsetX", 0);
                root.s("offsetY", 0);
            }
        }
    }

    PxGroup {
        title: I18n.t("Воспроизведение", "Playback")
        icon: "play"
        width: parent.width

        SettingRow {
            label: I18n.t("Пауза", "Paused")
            PxToggle {
                checked: root.g("paused", false)
                onToggled: c => root.s("paused", c)
            }
        }
        SettingRow {
            label: I18n.t("Повтор", "Loop")
            PxToggle {
                checked: root.g("loop", true)
                onToggled: c => root.s("loop", c)
            }
        }
        SettingRow {
            label: I18n.t("Скорость (видео)", "Speed (video)")
            PxSlider {
                width: parent.width
                from: 0.25
                to: 2
                stepSize: 0.25
                decimals: 2
                suffix: "×"
                value: root.g("speed", 1.0)
                onReleased: v => root.s("speed", v)
            }
        }
        SettingRow {
            label: I18n.t("Лимит FPS", "FPS limit")
            hint: I18n.t("Меньше обновлений картинки — меньше нагрузка на GPU; частота кадров самого файла не растёт", "Fewer picture updates, less GPU load; it never raises the file's own frame rate")
            PxCombo {
                width: Skin.px(160)
                model: [
                    {
                        "value": 0,
                        "label": I18n.t("Без ограничения", "Unlimited")
                    },
                    {
                        "value": 10,
                        "label": "10"
                    },
                    {
                        "value": 15,
                        "label": "15"
                    },
                    {
                        "value": 20,
                        "label": "20"
                    },
                    {
                        "value": 24,
                        "label": "24"
                    },
                    {
                        "value": 30,
                        "label": "30"
                    },
                    {
                        "value": 45,
                        "label": "45"
                    },
                    {
                        "value": 60,
                        "label": "60"
                    }
                ]
                currentValue: root.g("fps", 0)
                onActivated: v => root.s("fps", v)
            }
        }
        SettingRow {
            label: I18n.t("Только на первом экране", "First screen only")
            hint: I18n.t("На каждом экране видео декодируется отдельно — это главный источник фризов", "Every screen decodes the video on its own, a common cause of stutter")
            PxToggle {
                checked: root.g("primaryOnly", false)
                onToggled: c => root.s("primaryOnly", c)
            }
        }
        SettingRow {
            label: I18n.t("Пауза при полноэкранном окне", "Pause on a fullscreen window")
            PxToggle {
                checked: root.g("pauseFullscreen", true)
                onToggled: c => root.s("pauseFullscreen", c)
            }
        }
    }

    PxGroup {
        title: I18n.t("Звук (только полноэкранный слой)", "Audio (fullscreen layer only)")
        icon: "speaker"
        width: parent.width

        SettingRow {
            label: I18n.t("Включить звук", "Sound on")
            hint: I18n.t("Выключено — у обоев нет аудиовыхода, плеер и спектр их не видят", "Off — the wallpaper has no audio output, the player and spectrum don't see it")
            PxToggle {
                checked: root.g("sound", false)
                onToggled: c => root.s("sound", c)
            }
        }
        SettingRow {
            label: I18n.t("Громкость", "Volume")
            PxSlider {
                width: parent.width
                from: 0
                to: 100
                stepSize: 1
                value: root.g("volume", 80)
                onReleased: v => root.s("volume", Math.round(v))
            }
        }
        SettingRow {
            label: I18n.t("Без звука на полном экране", "Mute on a fullscreen window")
            PxToggle {
                checked: root.g("muteFullscreen", true)
                onToggled: c => root.s("muteFullscreen", c)
            }
        }
    }
}
