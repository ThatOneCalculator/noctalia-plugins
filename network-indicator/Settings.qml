import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string arrowType: cfg.arrowType || defaults.arrowType
    property int minWidth: cfg.minWidth || defaults.minWidth

    property bool useCustomColors: cfg.useCustomColors || defaults.useCustomColors
    property bool showNumbers: cfg.showNumbers || defaults.showNumbers
    property bool forceMegabytes: cfg.forceMegabytes || defaults.forceMegabytes

    property color colorSilent: root.useCustomColors && (cfg.colorSilent || defaults.colorSilent) || Color.mSurfaceVariant
    property color colorTx: cfg.colorTx || defaults.colorTx || Color.mSecondary
    property color colorRx: cfg.colorRx || defaults.colorRx || Color.mPrimary
    property color colorText: cfg.colorText || defaults.colorText || Qt.alpha(Color.mOnSurfaceVariant, 0.3)

    property int byteThresholdActive: cfg.byteThresholdActive || defaults.byteThresholdActive
    property real fontSizeModifier: cfg.fontSizeModifier || defaults.fontSizeModifier
    property real iconSizeModifier: cfg.iconSizeModifier || defaults.iconSizeModifier
    property real spacingInbetween: cfg.spacingInbetween || defaults.spacingInbetween

    property string barPosition: Settings.data.bar.position || "top"
    property string barDensity: Settings.data.bar.density || "compact"
    property bool barIsSpacious: root.barDensity != "mini"
    property bool barIsVertical: root.barPosition === "left" || barPosition === "right"

    spacing: Style.marginL

    Component.onCompleted: {
        Logger.i("NetworkIndicator", "Settings UI loaded");
    }

    function toIntOr(defaultValue, text) {
        const v = parseInt(String(text).trim(), 10);
        return isNaN(v) ? defaultValue : v;
    }

    // ---------- General ----------

    RowLayout {
        NComboBox {
            label: "Icon Type"
            description: "Choose the icon style used for the TX/RX indicators."

            model: [
                {
                    "key": "arrow",
                    "name": "arrow"
                },
                {
                    "key": "arrow-narrow",
                    "name": "arrow-narrow"
                },
                {
                    "key": "caret",
                    "name": "caret"
                },
                {
                    "key": "chevron",
                    "name": "chevron"
                },
            ]

            currentKey: root.arrowType
            onSelected: key => root.arrowType = key
        }

        NIcon {
            icon: root.arrowType + "-up"
            color: Color.mPrimary
            pointSize: Style.fontSizeL * 2
        }
    }

    NTextInput {
        label: "Minimum Widget Width"
        description: "Set a minimum width for the widget (in px)."
        placeholderText: String(root.minWidth)
        text: String(root.minWidth)
        onTextChanged: root.minWidth = root.toIntOr(0, text)
    }

    NTextInput {
        label: "Show Active Threshold"
        description: "Set the activity threshold in bytes per second (B/s)."
        placeholderText: root.byteThresholdActive + " bytes"
        text: String(root.byteThresholdActive)
        onTextChanged: root.byteThresholdActive = root.toIntOr(0, text)
    }

    NToggle {
        label: "Show Values"
        description: "Display the current RX/TX speeds as numbers."
        visible: barIsSpacious && !barIsVertical

        checked: root.showNumbers
        onToggled: function (checked) {
            if (checked) {
                root.showNumbers = true;
            } else {
                root.showNumbers = false;
            }
        }
    }

    NToggle {
        label: "Force megabytes (MB)"
        description: "Show all traffic values in MB instead of switching to KB for low usage."
        visible: barIsSpacious && !barIsVertical

        checked: root.forceMegabytes
        onToggled: function (checked) {
            if (checked) {
                root.forceMegabytes = true;
            } else {
                root.forceMegabytes = false;
            }
        }
    }

    NDivider {
        visible: true
        Layout.fillWidth: true
        Layout.topMargin: Style.marginL
        Layout.bottomMargin: Style.marginL
    }

    // ---------- Slider ----------

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: "Vertical Spacing"
            description: "Adjust the spacing between RX/TX elements."
        }

        NValueSlider {
            Layout.fillWidth: true
            from: -5
            to: 5
            stepSize: 1
            value: root.spacingInbetween
            onMoved: value => root.spacingInbetween = value
            text: root.spacingInbetween.toFixed(0)
        }
    }

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: "Font Size Modifier"
            description: "Scale the text size relative to the default."
        }

        NValueSlider {
            Layout.fillWidth: true
            from: 0.5
            to: 1.5
            stepSize: 0.05
            value: root.fontSizeModifier
            onMoved: value => root.fontSizeModifier = value
            text: fontSizeModifier.toFixed(2)
        }
    }

    ColumnLayout {
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NLabel {
            label: "Icon Size Modifier"
            description: "Scale the icon size relative to the default."
        }

        NValueSlider {
            Layout.fillWidth: true
            from: 0.5
            to: 1.5
            stepSize: 0.05
            value: root.iconSizeModifier
            onMoved: value => root.iconSizeModifier = value
            text: root.iconSizeModifier.toFixed(2)
        }
    }

    NDivider {
        visible: true
        Layout.fillWidth: true
        Layout.topMargin: Style.marginL
        Layout.bottomMargin: Style.marginL
    }

    // ---------- Colors ----------

    NToggle {
        label: "Custom Colors"
        description: "Enable custom colors instead of theme defaults."
        checked: root.useCustomColors
        onToggled: function (checked) {
            if (checked) {
                root.useCustomColors = true;
            } else {
                root.useCustomColors = false;
            }
        }
    }

    ColumnLayout {
        visible: root.useCustomColors

        RowLayout {
            NLabel {
                label: "TX Active"
                description: "Set the upload (TX) icon color when above the threshold."
                Layout.alignment: Qt.AlignTop
            }

            NColorPicker {
                selectedColor: root.colorTx
                onColorSelected: color => root.colorTx = color
            }
        }

        RowLayout {
            NLabel {
                label: "RX Active"
                description: "Set the download (RX) icon color when above the threshold."
            }

            NColorPicker {
                selectedColor: root.colorRx
                onColorSelected: color => root.colorRx = color
            }
        }

        RowLayout {
            NLabel {
                label: "RX/TX Inactive"
                description: "Set the icon color when traffic is below the threshold."
            }

            NColorPicker {
                selectedColor: root.colorSilent
                onColorSelected: color => root.colorSilent = color
            }
        }

        RowLayout {
            NLabel {
                label: "Text"
                description: "Set the text color used for both RX and TX values."
            }

            NColorPicker {
                selectedColor: root.colorText
                onColorSelected: color => root.colorText = color
            }
        }
    }

    // ---------- Saving ----------

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("NetworkIndicator", "Cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.useCustomColors = root.useCustomColors;
        pluginApi.pluginSettings.showNumbers = root.showNumbers;
        pluginApi.pluginSettings.forceMegabytes = root.forceMegabytes;

        pluginApi.pluginSettings.arrowType = root.arrowType;
        pluginApi.pluginSettings.minWidth = root.minWidth;
        pluginApi.pluginSettings.byteThresholdActive = root.byteThresholdActive;
        pluginApi.pluginSettings.fontSizeModifier = root.fontSizeModifier;
        pluginApi.pluginSettings.iconSizeModifier = root.iconSizeModifier;
        pluginApi.pluginSettings.spacingInbetween = root.spacingInbetween;

        pluginApi.pluginSettings.colorSilent = root.colorSilent.toString();
        pluginApi.pluginSettings.colorTx = root.colorTx.toString();
        pluginApi.pluginSettings.colorRx = root.colorRx.toString();
        pluginApi.pluginSettings.colorText = root.colorText.toString();

        pluginApi.saveSettings();

        Logger.i("NetworkIndicator", "Settings saved successfully");
    }
}
