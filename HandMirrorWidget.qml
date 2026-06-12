import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: root

    property var popoutService: null

    // ── Config properties (reactive: update when settings change) ──
    readonly property int   cfg_windowWidth:   pluginData.windowSize    ?? 360
    readonly property int   cfg_cameraIndex:   parseInt(pluginData.cameraIndex ?? "0")
    readonly property real  cfg_zoomFactor:    (pluginData.zoomFactor ?? 100) / 100.0
    readonly property int   cfg_borderRadius:  pluginData.borderRadius  ?? 16
    readonly property string cfg_penColor:     pluginData.penColor      ?? "#e91e63"
    readonly property int   cfg_penWidth:      pluginData.penWidth      ?? 4

    // Dynamic aspect ratio calculation
    property real cameraRatio: {
        if (videoOutput && videoOutput.sourceRect.width > 0 && videoOutput.sourceRect.height > 0) {
            return videoOutput.sourceRect.width / videoOutput.sourceRect.height;
        }
        return 4.0 / 3.0; // Fallback to classic 4:3
    }

    popoutWidth:  cfg_windowWidth
    popoutHeight: Math.round(cfg_windowWidth / cameraRatio)

    onCfg_windowWidthChanged: {
        root.popoutWidth = cfg_windowWidth;
        root.popoutHeight = Math.round(cfg_windowWidth / cameraRatio);
    }
    
    onCameraRatioChanged: {
        root.popoutHeight = Math.round(root.popoutWidth / cameraRatio);
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: Theme.iconSizeSmall
            implicitHeight: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "camera_front"
                size: Theme.iconSizeSmall
                color: (pluginPopout && pluginPopout.shouldBeVisible) ? Theme.primary : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        root.triggerPopout();
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: Theme.iconSize
            implicitHeight: Theme.iconSizeSmall
            anchors.horizontalCenter: parent.horizontalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "camera_front"
                size: Theme.iconSizeSmall
                color: (pluginPopout && pluginPopout.shouldBeVisible) ? Theme.primary : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        root.triggerPopout();
                    }
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutComp
            headerText: I18n.tr("Hand Mirror")
            showCloseButton: true

            Item {
                width: parent.width
                height: root.popoutHeight - 80

                // 1. Camera View panel
                StyledRect {
                    id: cameraViewPanel
                    anchors.fill: parent
                    radius: pluginData.borderRadius ?? 16
                    color: Theme.surfaceContainer
                    clip: true
                    visible: !snapOverlay.visible

                    // Camera Device Binding
                    CaptureSession {
                        id: captureSession
                        camera: Camera {
                            id: camera
                            active: (pluginPopout && pluginPopout.shouldBeVisible) && !snapOverlay.visible
                            cameraDevice: {
                                const index = pluginData.cameraIndex ?? 0;
                                const devices = MediaDevices.videoInputs;
                                if (devices && devices.length > index) {
                                    return devices[index];
                                }
                                return MediaDevices.defaultVideoInput;
                            }
                        }
                        videoOutput: videoOutput
                    }

                    VideoOutput {
                        id: videoOutput
                        width: parent.width * (pluginData.zoomFactor ?? 1.0)
                        height: parent.height * (pluginData.zoomFactor ?? 1.0)
                        anchors.centerIn: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: cameraViewPanel.width
                                    height: cameraViewPanel.height
                                    radius: cameraViewPanel.radius
                                }
                            }
                        }
                    }

                    // Control actions row overlay (bottom center)
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 12
                        spacing: 12

                        // Snapshot button
                        StyledRect {
                            width: 36
                            height: 36
                            radius: 18
                            color: Qt.rgba(0, 0, 0, 0.6)
                            border.color: "white"
                            border.width: 1.5

                            DankIcon {
                                anchors.centerIn: parent
                                name: "photo_camera"
                                size: 16
                                color: "white"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.color = Qt.rgba(0, 0, 0, 0.8)
                                onExited: parent.color = Qt.rgba(0, 0, 0, 0.6)
                                onClicked: {
                                    videoOutput.grabToImage(function(result) {
                                        snapImage.source = result.url;
                                        snapOverlay.visible = true;
                                        drawingCanvas.clear();
                                    });
                                }
                            }
                        }
                    }

                    // Premium Canvas Resize Grip (bottom right)
                    Canvas {
                        id: resizeCanvas
                        width: 12
                        height: 12
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 6
                        anchors.bottomMargin: 6

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                            ctx.lineWidth = 1.5;
                            ctx.beginPath();
                            ctx.moveTo(12, 0); ctx.lineTo(0, 12);
                            ctx.moveTo(12, 4); ctx.lineTo(4, 12);
                            ctx.moveTo(12, 8); ctx.lineTo(8, 12);
                            ctx.stroke();
                        }

                        MouseArea {
                            id: resizeGrip
                            anchors.fill: parent
                            cursorShape: Qt.SizeFDiagCursor
                            
                            property real startX
                            property real startY
                            property real startWidth

                            onPressed: (mouse) => {
                                startX = mouse.x;
                                startY = mouse.y;
                                startWidth = root.popoutWidth;
                            }

                            onPositionChanged: (mouse) => {
                                const deltaX = mouse.x - startX;
                                
                                root.popoutWidth = Math.max(160, Math.min(800, startWidth + deltaX));
                                root.popoutHeight = Math.round(root.popoutWidth / root.cameraRatio);
                            }

                            onReleased: {
                                if (pluginService) {
                                    pluginService.savePluginData(pluginId, "windowSize", root.popoutWidth);
                                }
                            }
                        }
                    }
                }

                // 2. Polaroid snap and draw overlay
                StyledRect {
                    id: snapOverlay
                    anchors.fill: parent
                    color: Theme.surfaceContainerHighest
                    visible: false
                    radius: pluginData.borderRadius ?? 16

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        // Polaroid layout representation
                        Rectangle {
                            id: polaroidCard
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "white"
                            radius: 8
                            border.color: "#d0d0d0"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                // Taken snapshot image area
                                Item {
                                    id: imageContainer
                                    width: parent.width
                                    height: parent.height - 36 // whitespace

                                    Image {
                                        id: snapImage
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        cache: false
                                    }

                                    // Annotation Canvas
                                    Canvas {
                                        id: drawingCanvas
                                        anchors.fill: parent
                                        property real lastX: 0
                                        property real lastY: 0

                                        function clear() {
                                            const ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            requestPaint();
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onPressed: (mouse) => {
                                                drawingCanvas.lastX = mouse.x;
                                                drawingCanvas.lastY = mouse.y;
                                            }
                                            onPositionChanged: (mouse) => {
                                                const ctx = drawingCanvas.getContext("2d");
                                                ctx.strokeStyle = pluginData.penColor ?? "#e91e63";
                                                ctx.lineWidth = pluginData.penWidth ?? 4;
                                                ctx.lineCap = "round";
                                                ctx.lineJoin = "round";

                                                ctx.beginPath();
                                                ctx.moveTo(drawingCanvas.lastX, drawingCanvas.lastY);
                                                ctx.lineTo(mouse.x, mouse.y);
                                                ctx.stroke();

                                                drawingCanvas.lastX = mouse.x;
                                                drawingCanvas.lastY = mouse.y;
                                                drawingCanvas.requestPaint();
                                            }
                                        }
                                    }
                                }

                                // Bottom polaroid write space
                                Item {
                                    width: parent.width
                                    height: 20
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: I18n.tr("Snap!")
                                        color: "#777777"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.italic: true
                                    }
                                }
                            }
                        }

                        // Polaroid control action buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            DankButton {
                                Layout.fillWidth: true
                                text: I18n.tr("Clear")
                                onClicked: drawingCanvas.clear()
                            }

                            DankButton {
                                Layout.fillWidth: true
                                text: I18n.tr("Save")
                                onClicked: {
                                    const filename = "Snap_" + new Date().getTime() + ".png";
                                    const saveDir = Quickshell.env("HOME") + "/Pictures/Snaps";
                                    
                                    Proc.runCommand("mkdir-snaps", ["mkdir", "-p", saveDir], function(stdout, exitCode) {
                                        if (exitCode === 0) {
                                            polaroidCard.grabToImage(function(result) {
                                                const fullPath = saveDir + "/" + filename;
                                                result.saveToFile(fullPath);
                                                if (typeof ToastService !== "undefined" && ToastService) {
                                                    ToastService.showInfo(I18n.tr("Snapshot saved"), fullPath);
                                                }
                                                snapOverlay.visible = false;
                                            });
                                        } else {
                                            if (typeof ToastService !== "undefined" && ToastService) {
                                                ToastService.showError(I18n.tr("Error"), I18n.tr("Could not create snaps directory."));
                                            }
                                        }
                                    });
                                }
                            }

                            DankButton {
                                Layout.fillWidth: true
                                text: I18n.tr("Cancel")
                                onClicked: snapOverlay.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
