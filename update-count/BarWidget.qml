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
    property bool hideOnZero: pluginApi?.pluginSettings.hideOnZero || pluginApi?.manifest?.metadata.defaultSettings?.hideOnZero

    property bool hasCommandYay: false
    property bool hasCommandParu: false
    property bool hasCommandCheckupdates: false
    property bool hasCommandDnf: false

    property int count: 0
    property string distro: ""

    property string customCmdGetNumUpdate: pluginApi?.pluginSettings.customCmdGetNumUpdate || ""
    property string customCmdDoSystemUpdate: pluginApi?.pluginSettings.customCmdDoSystemUpdate || ""

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

    // ------ Initialization -----

    Process {
        id: checkAvailableCommands
        running: true

        command: ["sh", "-c", "command -v paru >/dev/null 2>&1; cmd_paru=$?;" +
                              "command -v yay >/dev/null 2>&1; cmd_yay=$?;" +
                              "command -v checkupdates >/dev/null 2>&1; cmd_chkupd=$?;" +
                              "command -v dnf >/dev/null 2>&1; cmd_dnf=$?;" +
                              "printf '%s %s\n' $((cmd_paru==0)) $((cmd_yay==0)) $((cmd_chkupd==0)) $((cmd_dnf==0))"]

        stdout: StdioCollector {
              onStreamFinished: {
                  root.checkForUpdater(text)
                  console.log(root.distro)
                  getNumUpdates.running = true

              }
          }
    }

    function checkForUpdater(text) {
      const checks = text.trim().split(/\s+/);

      root.hasCommandParu = (checks[0] === "1");
      root.hasCommandYay  = (checks[1] === "1");
      root.hasCommandCheckupdates = (checks[2] === "1");
      root.hasCommandDnf = (checks[3] === "1");

      if (root.hasCommandParu || root.hasCommandYay || root.hasCommandCheckupdates) {
        root.distro = "arch";
      } else if (root.hasCommandDnf) {
        root.distro = "fedora";
      } else {
        root.distro = "unknown"
      }

    }

    // ------ Functionality ------

    Timer {
        id: timerGetNumUpdates

        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: function() {
          if (root.distro != "unknown") {
            getNumUpdates.running = true
          }
        }
    }

    function cmdGetNumUpdates() {
      if (root.customCmdGetNumUpdate != "") { return root.customCmdGetNumUpdate; }

      switch (root.distro) {
        case "arch":
          if (root.hasCommandParu) { return "paru -Quq 2>/dev/null | wc -l"; }
          else if (root.hasCommandYay) { return "yay -Quq 2>/dev/null | wc -l"; }
          else { return "checkupdates 2>/dev/null | wc -l"; }

        case "fedora":
          return "dnf check-update -q | grep -c ^[a-z0-9])";

        case "void":
          return "$(/usr/sbin/xbps-install -Mnu 2>&1 | grep -v '^$' | wc -l)"

        default:
          return "printf '0\n'";
        }
    }

    Process {
        id: getNumUpdates
        command: ["sh", "-c", root.cmdGetNumUpdates()]
        stdout: StdioCollector {
            onStreamFinished: {
              var count = parseInt(text.trim());
              root.count = isNaN(count) ? 0 : count;
            }
        }
    }

    function cmdDoSystemUpdate() {
      if (root.customCmdDoSystemUpdate != "") { return root.customCmdDoSystemUpdate; }

      switch (root.distro) {
        case "arch":
          if (root.hasCommandParu) { return "paru -Syu"; }
          else if (root.hasCommandYay) { return "yay -Syu"; }
          else { return "sudo pacman -Syu"; }

        case "fedora":
          return "sudo dnf upgrade -y --refresh";

        case "void":
          return "sudo xbps-install -Su";

        default:
          return "printf 'No supported updater for this distro\\n' >&2; exit 1";
      }
    }

    Process {
        id: doSystemUpdate
        command: ["sh", "-c", root.configuredTerminal + " " + root.cmdDoSystemUpdate()]
    }

    // ------ Widget ------

    function buildTooltip() {
        if (root.count == 0) {
            TooltipService.show(root, pluginApi?.tr("tooltip.no-update"), BarService.getTooltipDirection());
        } else {
            TooltipService.show(root, pluginApi?.tr("tooltip.available-update"), BarService.getTooltipDirection());
        }
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
                doSystemUpdate.running = true
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
