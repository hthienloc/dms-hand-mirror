import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: window
    color: "transparent"

    property var plugin: null
    readonly property var pluginData: plugin ? plugin.pluginData : ({})

    // Configuration properties
    readonly property int initialWidth: pluginData.windowWidth ?? 360
    readonly property int initialHeight: pluginData.windowHeight ?? 270
    readonly property real zoomFactor: pluginData.zoomFactor ?? 1.0
    readonly property int cameraRadius: pluginData.borderRadius ?? 16
    readonly property bool micCheckEnabled: pluginData.micCheckEnabled ?? true
    readonly property string penColor: pluginData.penColor ?? "#e91e63"
    readonly property int penWidth: pluginData.penWidth ?? 4

    // Dynamic sizes
    property real targetWidth: initialWidth
    property real targetHeight: initialHeight
    property bool manuallyMoved: false

    // Position coordinates
    property int xPos: 400
    property int yPos: 400

    anchors { top: true; left: true }
    WlrLayershell.namespace: "dms-hand-mirror"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    WlrLayershell.margins {
        left: xPos
        top: yPos
    }

    implicitWidth: targetWidth
    implicitHeight: targetHeight

    // Position helper: aligns window on show
    function updatePosition() {
        if (manuallyMoved) return;

        const workArea = {
            x: 0,
            y: 0,
            width: window.screen.width,
            height: window.screen.height
        };

        const spawnPos = pluginData.spawnPosition ?? "center";
        const edgeSpacing = Appearance?.spacing?.normal ?? 16;

        let newX = workArea.x + (workArea.width - targetWidth) / 2;
        let newY = workArea.y + (workArea.height - targetHeight) / 2;

        if (spawnPos === "top-right") {
            newX = workArea.x + workArea.width - targetWidth - edgeSpacing;
            newY = workArea.y + edgeSpacing;
        } else if (spawnPos === "top-left") {
            newX = workArea.x + edgeSpacing;
            newY = workArea.y + edgeSpacing;
        } else if (spawnPos === "bottom-right") {
            newX = workArea.x + workArea.width - targetWidth - edgeSpacing;
            newY = workArea.y + workArea.height - targetHeight - edgeSpacing;
        } else if (spawnPos === "bottom-left") {
            newX = workArea.x + edgeSpacing;
            newY = workArea.y + workArea.height - targetHeight - edgeSpacing;
        }

        xPos = Math.max(workArea.x + edgeSpacing, Math.min(workArea.x + workArea.width - targetWidth - edgeSpacing, newX));
        yPos = Math.max(workArea.y + edgeSpacing, Math.min(workArea.y + workArea.height - targetHeight - edgeSpacing, newY));
    }

    // Window Drag Engine
    Item {
        id: dragTarget
        x: window.xPos
        y: window.yPos
        onXChanged: {
            if (dragArea.drag.active) {
                window.xPos = x;
                window.manuallyMoved = true;
            }
        }
        onYChanged: {
            if (dragArea.drag.active) {
                window.yPos = y;
                window.manuallyMoved = true;
            }
        }
    }

    // Camera pipeline
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: window.visible && !snapOverlay.visible
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

    // Real-time microphone VU Meter levels collector
    property int micLevel: 0
    Process {
        id: micProcess
        command: ["arecord", "-D", "default", "-f", "S16_LE", "-r", "8000", "-t", "raw", "/dev/null", "-V", "mono"]
        running: window.visible && window.micCheckEnabled && !snapOverlay.visible
        
        stderr: SplitParser {
            splitMarker: "\r"
            onRead: (data) => {
                const match = data.match(/(\d+)%/);
                if (match) {
                    window.micLevel = parseInt(match[1]);
                }
            }
        }
    }

    // Main window card structure
    StyledRect {
        id: mainCard
        anchors.fill: parent
        radius: window.cameraRadius
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true

        // 1. Camera View container
        Item {
            id: cameraViewContainer
            anchors.fill: parent
            clip: true

            VideoOutput {
                id: videoOutput
                width: parent.width * window.zoomFactor
                height: parent.height * window.zoomFactor
                anchors.centerIn: parent
                fillMode: VideoOutput.PreserveAspectCrop
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: cameraViewContainer.width
                            height: cameraViewContainer.height
                            radius: window.cameraRadius
                        }
                    }
                }
            }

            // Draggable Area for moving window
            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                drag.target: dragTarget
                drag.axis: Drag.XAndYAxis
                drag.threshold: 0

                onDoubleClicked: {
                    // Reset position and center
                    window.manuallyMoved = false;
                    window.updatePosition();
                }
            }

            // Microphone Level visual bar overlay
            StyledRect {
                id: micBar
                width: 6
                height: parent.height - 80
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.4)
                visible: window.micCheckEnabled

                Rectangle {
                    width: parent.width
                    height: parent.height * (window.micLevel / 100.0)
                    anchors.bottom: parent.bottom
                    radius: parent.radius
                    color: window.micLevel > 70 ? Theme.error : (window.micLevel > 40 ? Theme.warning : Theme.primary)
                    
                    Behavior on height {
                        NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
                    }
                }
            }

            // Control Buttons Overlay
            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 12
                spacing: 12

                // Polaroid snapshot button
                StyledRect {
                    width: 42
                    height: 42
                    radius: 21
                    color: Qt.rgba(0, 0, 0, 0.6)
                    border.color: "white"
                    border.width: 2

                    DankIcon {
                        anchors.centerIn: parent
                        name: "photo_camera"
                        size: 20
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

                // Close Button
                StyledRect {
                    width: 42
                    height: 42
                    radius: 21
                    color: Qt.rgba(0, 0, 0, 0.6)
                    border.color: "white"
                    border.width: 2

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 20
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(0, 0, 0, 0.8)
                        onExited: parent.color = Qt.rgba(0, 0, 0, 0.6)
                        onClicked: window.visible = false
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
            radius: window.cameraRadius

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Polaroid frame representation
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
                        anchors.margins: 12
                        spacing: 12

                        // Snapshot image area
                        Item {
                            id: imageContainer
                            width: parent.width
                            height: parent.height - 48 // Bottom whitespace

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
                                        ctx.strokeStyle = window.penColor;
                                        ctx.lineWidth = window.penWidth;
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

                        // Polaroid white bottom spacer
                        Item {
                            width: parent.width
                            height: 36
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

                // Controls row
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
                            
                            // Create directories first
                            Proc.runCommand("mkdir-snaps", ["mkdir", "-p", saveDir], function(stdout, exitCode) {
                                if (exitCode === 0) {
                                    polaroidCard.grabToImage(function(result) {
                                        const fullPath = saveDir + "/" + filename;
                                        result.saveToFile(fullPath);
                                        ToastService?.showInfo(I18n.tr("Snapshot saved"), fullPath);
                                        snapOverlay.visible = false;
                                    });
                                } else {
                                    ToastService?.showError(I18n.tr("Error"), I18n.tr("Could not create snaps directory."));
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
