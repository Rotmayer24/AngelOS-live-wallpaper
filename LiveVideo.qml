import QtQuick
import QtMultimedia

// Общий проигрыватель: mp4/webm/mkv/mov через MediaPlayer, gif/webp через AnimatedImage.
// fps > 0 ограничивает частоту обновления картинки (декодирование идёт как обычно, но
// на экран кадр попадает не чаще fps раз в секунду); 0 — без ограничения.
Item {
    id: root
    property string file: ""
    property bool paused: false
    property bool loop: true
    property real speed: 1.0
    property string scale: "Fill"      // Fill | Fit | Stretch
    property int fps: 0
    property real zoom: 1.0            // 0.25..3: поверх режима Fill/Fit/Stretch
    property real offsetX: 0           // сдвиг в долях ширины, -0.5..0.5
    property real offsetY: 0
    property bool audio: false         // подключать ли звук вообще
    property bool muted: true
    property int volume: 80            // 0..100
    // gif/webp сначала через AnimatedImage; если Qt не смог (нет плагина формата) — через ffmpeg-плеер
    property bool imageFailed: false
    readonly property bool isImage: /\.(gif|webp)$/i.test(file) && !imageFailed
    readonly property bool ok: file !== ""
    readonly property url fileUrl: "file://" + file.split("/").map(encodeURIComponent).join("/")
    readonly property bool throttled: fps > 0 && ok
    onFileChanged: imageFailed = false
    clip: true

    Item {
        id: stage
        width: root.width
        height: root.height
        x: root.offsetX * root.width
        y: root.offsetY * root.height
        scale: root.zoom
        transformOrigin: Item.Center

    Item {
        id: box
        anchors.fill: parent

        Loader {
            anchors.fill: parent
            active: root.ok && !root.isImage
            sourceComponent: Item {
                MediaPlayer {
                    id: player
                    source: root.fileUrl
                    loops: root.loop ? MediaPlayer.Infinite : 1
                    playbackRate: root.speed
                    videoOutput: out
                    audioOutput: root.audio ? ao : null
                    onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia && !root.paused)
                        play()
                    onErrorOccurred: (error, msg) => console.warn("live-wallpaper:", msg)
                }
                AudioOutput {
                    id: ao
                    muted: root.muted
                    volume: root.volume / 100
                }
                Connections {
                    target: root
                    function onPausedChanged() {
                        root.paused ? player.pause() : player.play();
                    }
                }
                VideoOutput {
                    id: out
                    anchors.fill: parent
                    fillMode: root.scale === "Fit" ? VideoOutput.PreserveAspectFit : root.scale === "Stretch" ? VideoOutput.Stretch : VideoOutput.PreserveAspectCrop
                }
            }
        }

        Loader {
            anchors.fill: parent
            active: root.ok && root.isImage
            sourceComponent: AnimatedImage {
                source: root.fileUrl
                playing: !root.paused
                onStatusChanged: if (status === Image.Error) {
                    console.warn("live-wallpaper: AnimatedImage failed, falling back to the video player:", root.file);
                    root.imageFailed = true;
                }
                fillMode: root.scale === "Fit" ? Image.PreserveAspectFit : root.scale === "Stretch" ? Image.Stretch : Image.PreserveAspectCrop
            }
        }
    }

    // ограничитель кадров: текстура обновляется по таймеру
    Loader {
        anchors.fill: parent
        active: root.throttled
        sourceComponent: ShaderEffectSource {
            id: ses
            sourceItem: box
            live: false
            hideSource: true
            Timer {
                interval: Math.max(1, Math.round(1000 / root.fps))
                repeat: true
                running: !root.paused
                triggeredOnStart: true
                onTriggered: ses.scheduleUpdate()
            }
        }
    }
    }
}
