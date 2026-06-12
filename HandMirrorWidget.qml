import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: pluginRoot

    property var popoutService: null

    MirrorWindow {
        id: mirrorWin
        plugin: pluginRoot
        visible: false
    }

    horizontalBarPill: Component {
        StyledRect {
            id: pill
            width: Theme.iconSizeSmall + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: mirrorWin.visible ? Theme.primaryContainer : Theme.surfaceContainerHigh

            DankIcon {
                anchors.centerIn: parent
                name: "camera_front"
                size: Theme.iconSizeSmall
                color: mirrorWin.visible ? Theme.onPrimaryContainer : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    mirrorWin.visible = !mirrorWin.visible;
                    if (mirrorWin.visible) {
                        mirrorWin.updatePosition();
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            height: Theme.iconSizeSmall + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: mirrorWin.visible ? Theme.primaryContainer : Theme.surfaceContainerHigh

            DankIcon {
                anchors.centerIn: parent
                name: "camera_front"
                size: Theme.iconSizeSmall
                color: mirrorWin.visible ? Theme.onPrimaryContainer : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    mirrorWin.visible = !mirrorWin.visible;
                    if (mirrorWin.visible) {
                        mirrorWin.updatePosition();
                    }
                }
            }
        }
    }
}
