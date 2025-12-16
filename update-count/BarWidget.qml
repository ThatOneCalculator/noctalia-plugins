import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property bool hovered: false
    property int updateInterval: pluginApi?.pluginSettings.updateInterval || pluginApi?.manifest?.metadata.defaultSettings?.updateInterval
    property string configuredTerminal: pluginApi?.pluginSettings.configuredTerminal || pluginApi?.manifest?.metadata.defaultSettings?.configuredTerminal
    property int count: checkForUpdates() || 0
    property bool hideOnZero: pluginApi?.pluginSettings.hideOnZero || pluginApi?.manifest?.metadata.defaultSettings?.hideOnZero
    
    readonly property bool isVisible: (root.count > 0) || !root.hideOnZero
    readonly property string barPosition: Settings.data.bar.position
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property string updateScriptDir: (pluginApi?.pluginDir || Settings.configDir + "/plugins/update-count") + "/scripts"

    implicitWidth: isVertical ? Style.capsuleHeight : layout.implicitWidth + Style.marginS * 2
    implicitHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : Style.capsuleHeight

    color: root.hovered ? Color.mHover : Style.capsuleColor
    radius: Style.radiusM
    visible: root.isVisible
    
    // also set opacity to zero when invisible as we use opacity to hide the barWidgetLoader
    opacity: root.isVisible ? 1.0 : 0.0

    function checkForUpdates() {
        updateDataHandler.running = true;
    }

    function updateSystemPopup() {
        updateSystemHandler.running = true;
    }

    function buildTooltip() {
        if (root.count == 0) {
            TooltipService.show(root, pluginApi?.tr("tooltip.no-update"), BarService.getTooltipDirection());
        } else {
            TooltipService.show(root, pluginApi?.tr("tooltip.available-update"), BarService.getTooltipDirection());
        }
    }

    Process {
        id: updateDataHandler
        command: ["sh", "-c", root.updateScriptDir + "/update-count.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var count = parseInt(text.trim());
                root.count = isNaN(count) ? 0 : count;
            }
        }
    }

    Process {
        id: updateSystemHandler
        command: ["sh", "-c", root.configuredTerminal + " " + (pluginApi?.pluginDir || Settings.configDir + "/plugins/update-count") + "/scripts/update.sh"]
    }

    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: root.checkForUpdates()
    }

    Item {
        id: layout
        anchors.centerIn: parent
        implicitWidth: rowLayout.visible ? rowLayout.implicitWidth : colLayout.implicitWidth
        implicitHeight: rowLayout.visible ? rowLayout.implicitHeight : colLayout.implicitHeight

        RowLayout {
            id: rowLayout
            visible: !root.isVertical
            spacing: Style.marginS

            NIcon {
                icon: pluginApi?.pluginSettings?.configuredIcon || pluginApi?.manifest?.metadata?.defaultSettings?.configuredIcon
                color: root.hovered ? Color.mOnHover : Color.mOnSurface
            }

            NText {
                text: root.count.toString()
                color: root.hovered ? Color.mOnHover : Color.mOnSurface
                pointSize: Style.fontSizeS
            }
        }

        ColumnLayout {
            id: colLayout
            visible: root.isVertical
            spacing: Style.marginS

            NIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: pluginApi?.pluginSettings?.configuredIcon || pluginApi?.manifest?.metadata?.defaultSettings?.configuredIcon
                color: root.hovered ? Color.mOnHover : Color.mOnSurface
            }

            NText {
                Layout.alignment: Qt.AlignHCenter
                text: root.count.toString()
                color: root.hovered ? Color.mOnHover : Color.mOnSurface
                pointSize: Style.fontSizeS
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                updateSystemPopup();
            }

            onEntered: {
                root.hovered = true;
                buildTooltip();
            }

            onExited: {
                root.hovered = false;
                TooltipService.hide();
            }
        }
    }
}
