import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import QtMultimedia
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "handMirror"

    SettingsCard {
        id: cameraSection
        SectionTitle { 
            text: I18n.tr("Camera & Layout")
            icon: "videocam" 
            showReset: cameraIndex.isDirty || zoomFactor.isDirty || borderRadius.isDirty
            onResetClicked: {
                cameraIndex.resetToDefault();
                zoomFactor.resetToDefault();
                borderRadius.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: cameraIndex
            settingKey: "cameraIndex"
            label: I18n.tr("Select Camera")
            options: {
                const devices = MediaDevices.videoInputs;
                if (!devices || devices.length === 0) {
                    return [{ label: I18n.tr("Default Camera"), value: 0 }];
                }
                let opts = [];
                for (let i = 0; i < devices.length; i++) {
                    opts.push({ label: devices[i].description || ("Camera " + i), value: i });
                }
                return opts;
            }
            defaultValue: 0
        }

        Separator {}

        SliderSettingPlus {
            id: zoomFactor
            settingKey: "zoomFactor"
            label: I18n.tr("Digital Zoom")
            defaultValue: 1.0
            minimum: 1.0
            maximum: 3.0
            unit: "x"
            leftLabel: "1.0"
            rightLabel: "3.0"
        }

        Separator {}

        SliderSettingPlus {
            id: borderRadius
            settingKey: "borderRadius"
            label: I18n.tr("Corner Radius")
            defaultValue: 16
            minimum: 0
            maximum: 64
            unit: "px"
            leftLabel: "0"
            rightLabel: "64"
        }
    }

    SettingsCard {
        id: windowSection
        SectionTitle { 
            text: I18n.tr("Window Configuration")
            icon: "aspect_ratio" 
            showReset: windowWidth.isDirty || windowHeight.isDirty || spawnPosition.isDirty
            onResetClicked: {
                windowWidth.resetToDefault();
                windowHeight.resetToDefault();
                spawnPosition.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: windowWidth
            settingKey: "windowWidth"
            label: I18n.tr("Window Width")
            defaultValue: 360
            minimum: 160
            maximum: 800
            unit: "px"
            leftLabel: "160"
            rightLabel: "800"
        }

        Separator {}

        SliderSettingPlus {
            id: windowHeight
            settingKey: "windowHeight"
            label: I18n.tr("Window Height")
            defaultValue: 270
            minimum: 120
            maximum: 600
            unit: "px"
            leftLabel: "120"
            rightLabel: "600"
        }

        Separator {}

        SelectionSettingPlus {
            id: spawnPosition
            settingKey: "spawnPosition"
            label: I18n.tr("Default Spawn Position")
            options: [
                { label: I18n.tr("Center"), value: "center" },
                { label: I18n.tr("Top Left"), value: "top-left" },
                { label: I18n.tr("Top Right"), value: "top-right" },
                { label: I18n.tr("Bottom Left"), value: "bottom-left" },
                { label: I18n.tr("Bottom Right"), value: "bottom-right" }
            ]
            defaultValue: "center"
        }
    }

    SettingsCard {
        id: utilitiesSection
        SectionTitle { 
            text: I18n.tr("Audio & Snapshot Features")
            icon: "mic" 
            showReset: micCheckEnabled.isDirty || penColor.isDirty || penWidth.isDirty
            onResetClicked: {
                micCheckEnabled.resetToDefault();
                penColor.resetToDefault();
                penWidth.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: micCheckEnabled
            settingKey: "micCheckEnabled"
            label: I18n.tr("Microphone Check")
            description: I18n.tr("Show mic levels on the side of the mirror window.")
            defaultValue: true
        }

        Separator {}

        SelectionSettingPlus {
            id: penColor
            settingKey: "penColor"
            label: I18n.tr("Snap Drawing Pen Color")
            options: [
                { label: I18n.tr("Pink"), value: "#e91e63" },
                { label: I18n.tr("Red"), value: "#f44336" },
                { label: I18n.tr("Blue"), value: "#2196f3" },
                { label: I18n.tr("Green"), value: "#4caf50" },
                { label: I18n.tr("Yellow"), value: "#ffeb3b" },
                { label: I18n.tr("White"), value: "#ffffff" }
            ]
            defaultValue: "#e91e63"
        }

        Separator {}

        SliderSettingPlus {
            id: penWidth
            settingKey: "penWidth"
            label: I18n.tr("Snap Drawing Pen Thickness")
            defaultValue: 4
            minimum: 1
            maximum: 10
            unit: "px"
            leftLabel: "1"
            rightLabel: "10"
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-hand-mirror"
    }
}
