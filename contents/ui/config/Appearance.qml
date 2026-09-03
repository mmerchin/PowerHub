import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCMUtils
import QtQuick.Dialogs

KCMUtils.SimpleKCM {
	id: root

	property alias cfg_panelIconWidth: iconWidthSpinBox.value
	property alias cfg_panelIconRadius: iconRadiusSpinBox.value
	property alias cfg_panelLeftMargin: leftMarginSpinBox.value
	property alias cfg_panelRightMargin: rightMarginSpinBox.value
	property alias cfg_useAutoFontSize: useAutoFontSize.checked
	property alias cfg_customFontSize: customFontSize.value
	
	property alias cfg_profileDisplayStyle: displayStyleCombo.currentIndex
	property alias cfg_chargingHighlightColor: chargingHighlightColor.text
	
	property alias cfg_useAutoTextColor: useAutoTextColor.checked
	property alias cfg_customTextColor: customTextColor.text
	
	property alias cfg_useAutoProfileColors: useAutoProfileColors.checked
	property alias cfg_customEcoColor: customEcoColor.text
	property alias cfg_customBalancedColor: customBalancedColor.text
	property alias cfg_customPerformanceColor: customPerformanceColor.text
	
	property alias cfg_customEcoTextColor: ecoTextColor.text
	property alias cfg_customBalancedTextColor: balTextColor.text
	property alias cfg_customPerformanceTextColor: perfTextColor.text

	property alias cfg_customEcoChargingColor: ecoChargeColor.text
	property alias cfg_customBalancedChargingColor: balChargeColor.text
	property alias cfg_customPerformanceChargingColor: perfChargeColor.text

	property alias cfg_showMainBattery: showMainBattery.checked
	property alias cfg_showPowerProfile: showPowerProfile.checked
	property alias cfg_showSleepInhibitor: showSleepInhibitor.checked
	property alias cfg_smartSortDevices: smartSortDevices.checked
	property alias cfg_showDeviceSerials: showDeviceSerials.checked

	property alias cfg_deviceIconMap: hiddenIconMapField.text
	property alias cfg_knownDevices: hiddenKnownDevicesField.text

	QQC2.TextField { id: hiddenIconMapField; visible: false }
	QQC2.TextField { id: hiddenKnownDevicesField; visible: false }

	ColumnLayout {
		anchors.left: parent.left
		anchors.right: parent.right
		spacing: Kirigami.Units.smallSpacing

		QQC2.TabBar {
			id: tabBar
			Layout.fillWidth: true
			
			QQC2.TabButton { text: i18n("Panel Icon"); icon.name: "plasma" }
			QQC2.TabButton { text: i18n("Dropdown Menu"); icon.name: "window-pop-out" }
			QQC2.TabButton { text: i18n("Support"); icon.name: "love" }
		}

		StackLayout {
			currentIndex: tabBar.currentIndex
			Layout.fillWidth: true

			Kirigami.FormLayout {
				Layout.fillWidth: true
				Layout.topMargin: Kirigami.Units.largeSpacing

				QQC2.SpinBox { id: iconWidthSpinBox; Kirigami.FormData.label: i18n("Width (px):"); from: 30; to: 200; stepSize: 1 }
				QQC2.SpinBox { id: iconRadiusSpinBox; Kirigami.FormData.label: i18n("Corner Radius (px):"); from: 0; to: 50; stepSize: 1 }
				QQC2.SpinBox { id: leftMarginSpinBox; Kirigami.FormData.label: i18n("Left Margin (px):"); from: 0; to: 30; stepSize: 1 }
				QQC2.SpinBox { id: rightMarginSpinBox; Kirigami.FormData.label: i18n("Right Margin (px):"); from: 0; to: 30; stepSize: 1 }

				Kirigami.Separator { Kirigami.FormData.isSection: true }

				QQC2.CheckBox { id: useAutoFontSize; Kirigami.FormData.label: i18n("Font Size:"); text: i18n("Auto Adjust") }
				QQC2.SpinBox { id: customFontSize; Kirigami.FormData.label: i18n("Manual Size (px):"); from: 10; to: 20; stepSize: 1; enabled: !useAutoFontSize.checked }

				Kirigami.Separator { Kirigami.FormData.isSection: true }

				QQC2.ComboBox {
					id: displayStyleCombo
					Kirigami.FormData.label: i18n("Profile Display Style:")
					model: [i18n("With Icons"), i18n("With Colors"), i18n("Both Icon and Color")]
				}

				Kirigami.Separator { Kirigami.FormData.isSection: true }

				ColorDialog { id: textColorDialog; title: i18n("General Text Color"); onAccepted: customTextColor.text = selectedColor.toString() }
				ColorDialog { id: chargingColorDialog; title: i18n("Energy Flow Color (Charging)"); onAccepted: chargingHighlightColor.text = selectedColor.toString() }
				ColorDialog { id: ecoColorDialog; title: i18n("Eco Background"); onAccepted: customEcoColor.text = selectedColor.toString() }
				ColorDialog { id: balColorDialog; title: i18n("Balanced Background"); onAccepted: customBalancedColor.text = selectedColor.toString() }
				ColorDialog { id: perfColorDialog; title: i18n("Performance Background"); onAccepted: customPerformanceColor.text = selectedColor.toString() }
				ColorDialog { id: ecoTextDialog; title: i18n("Eco Text Color"); onAccepted: ecoTextColor.text = selectedColor.toString() }
				ColorDialog { id: balTextDialog; title: i18n("Balanced Text Color"); onAccepted: balTextColor.text = selectedColor.toString() }
				ColorDialog { id: perfTextDialog; title: i18n("Performance Text Color"); onAccepted: perfTextColor.text = selectedColor.toString() }
				ColorDialog { id: ecoChargeDialog; title: i18n("Eco Charging Color"); onAccepted: ecoChargeColor.text = selectedColor.toString() }
				ColorDialog { id: balChargeDialog; title: i18n("Balanced Charging Color"); onAccepted: balChargeColor.text = selectedColor.toString() }
				ColorDialog { id: perfChargeDialog; title: i18n("Performance Charging Color"); onAccepted: perfChargeColor.text = selectedColor.toString() }

				QQC2.CheckBox {
					id: useAutoTextColor
					visible: displayStyleCombo.currentIndex === 0
					Kirigami.FormData.label: i18n("General Text Color:")
					text: i18n("Auto Contrast Color")
				}
				RowLayout {
					visible: displayStyleCombo.currentIndex === 0
					enabled: !useAutoTextColor.checked
					Kirigami.FormData.label: i18n("Manual Color (Hex):")
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: customTextColor.text !== "" ? customTextColor.text : "#ffffff"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { textColorDialog.selectedColor = color; textColorDialog.open() } } }
					QQC2.TextField { id: customTextColor; placeholderText: "#ffffff" }
				}

				RowLayout {
					visible: displayStyleCombo.currentIndex === 0 || displayStyleCombo.currentIndex === 2
					Kirigami.FormData.label: i18n("Energy Flow Color (Charging):")
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: chargingHighlightColor.text !== "" ? chargingHighlightColor.text : "#f1c40f"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { chargingColorDialog.selectedColor = color; chargingColorDialog.open() } } }
					QQC2.TextField { id: chargingHighlightColor; placeholderText: "#f1c40f" }
				}

				QQC2.CheckBox {
					id: useAutoProfileColors
					visible: displayStyleCombo.currentIndex === 1 || displayStyleCombo.currentIndex === 2
					Kirigami.FormData.label: i18n("Profile Colors:")
					text: i18n("Use Default Colors")
				}
				
				RowLayout {
					visible: displayStyleCombo.currentIndex === 1 || displayStyleCombo.currentIndex === 2
					enabled: !useAutoProfileColors.checked
					Kirigami.FormData.label: i18n("Power Save (Eco):")
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: customEcoColor.text !== "" ? customEcoColor.text : "#87b07c"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ecoColorDialog.selectedColor = color; ecoColorDialog.open() } } }
					QQC2.TextField { id: customEcoColor; placeholderText: "#87b07c"; Layout.preferredWidth: 65 }
					Item { width: Kirigami.Units.smallSpacing }
					QQC2.Label { text: i18n("Text:") }
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: ecoTextColor.text !== "" ? ecoTextColor.text : "#ffffff"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ecoTextDialog.selectedColor = color; ecoTextDialog.open() } } }
					QQC2.TextField { id: ecoTextColor; placeholderText: "#ffffff"; Layout.preferredWidth: 65 }
					Item { width: Kirigami.Units.smallSpacing; visible: displayStyleCombo.currentIndex === 2 }
					QQC2.Label { text: i18n("Charge:"); visible: displayStyleCombo.currentIndex === 2 }
					Rectangle { visible: displayStyleCombo.currentIndex === 2; width: 24; height: 24; radius: 4; border.color: "#555"; color: ecoChargeColor.text !== "" ? ecoChargeColor.text : "#f6e58d"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { ecoChargeDialog.selectedColor = color; ecoChargeDialog.open() } } }
					QQC2.TextField { id: ecoChargeColor; visible: displayStyleCombo.currentIndex === 2; placeholderText: "#f6e58d"; Layout.preferredWidth: 65 }
				}

				RowLayout {
					visible: displayStyleCombo.currentIndex === 1 || displayStyleCombo.currentIndex === 2
					enabled: !useAutoProfileColors.checked
					Kirigami.FormData.label: i18n("Balanced (Bal):")
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: customBalancedColor.text !== "" ? customBalancedColor.text : "#ffffff"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { balColorDialog.selectedColor = color; balColorDialog.open() } } }
					QQC2.TextField { id: customBalancedColor; placeholderText: "#ffffff"; Layout.preferredWidth: 65 }
					Item { width: Kirigami.Units.smallSpacing }
					QQC2.Label { text: i18n("Text:") }
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: balTextColor.text !== "" ? balTextColor.text : "#000000"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { balTextDialog.selectedColor = color; balTextDialog.open() } } }
					QQC2.TextField { id: balTextColor; placeholderText: "#000000"; Layout.preferredWidth: 65 }
					Item { width: Kirigami.Units.smallSpacing; visible: displayStyleCombo.currentIndex === 2 }
					QQC2.Label { text: i18n("Charge:"); visible: displayStyleCombo.currentIndex === 2 }
					Rectangle { visible: displayStyleCombo.currentIndex === 2; width: 24; height: 24; radius: 4; border.color: "#555"; color: balChargeColor.text !== "" ? balChargeColor.text : "#f6e58d"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { balChargeDialog.selectedColor = color; balChargeDialog.open() } } }
					QQC2.TextField { id: balChargeColor; visible: displayStyleCombo.currentIndex === 2; placeholderText: "#f6e58d"; Layout.preferredWidth: 65 }
				}

				RowLayout {
					visible: displayStyleCombo.currentIndex === 1 || displayStyleCombo.currentIndex === 2
					enabled: !useAutoProfileColors.checked
					Kirigami.FormData.label: i18n("Performance:")
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: customPerformanceColor.text !== "" ? customPerformanceColor.text : "#3498db"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { perfColorDialog.selectedColor = color; perfColorDialog.open() } } }
					QQC2.TextField { id: customPerformanceColor; placeholderText: "#3498db"; Layout.preferredWidth: 65 }
					Item { width: Kirigami.Units.smallSpacing }
					QQC2.Label { text: i18n("Text:") }
					Rectangle { width: 24; height: 24; radius: 4; border.color: "#555"; color: perfTextColor.text !== "" ? perfTextColor.text : "#ffffff"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { perfTextDialog.selectedColor = color; perfTextDialog.open() } } }
					QQC2.TextField { id: perfTextColor; placeholderText: "#ffffff"; Layout.preferredWidth: 65 }
					Item { width: Kirigami.Units.smallSpacing; visible: displayStyleCombo.currentIndex === 2 }
					QQC2.Label { text: i18n("Charge:"); visible: displayStyleCombo.currentIndex === 2 }
					Rectangle { visible: displayStyleCombo.currentIndex === 2; width: 24; height: 24; radius: 4; border.color: "#555"; color: perfChargeColor.text !== "" ? perfChargeColor.text : "#f6e58d"; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { perfChargeDialog.selectedColor = color; perfChargeDialog.open() } } }
					QQC2.TextField { id: perfChargeColor; visible: displayStyleCombo.currentIndex === 2; placeholderText: "#f6e58d"; Layout.preferredWidth: 65 }
				}
			}

			Kirigami.FormLayout {
				Layout.fillWidth: true
				Layout.topMargin: Kirigami.Units.largeSpacing

				Kirigami.Separator { 
					Kirigami.FormData.isSection: true
					Kirigami.FormData.label: i18n("Visibility (Simplification)") 
				}
				QQC2.CheckBox { id: showMainBattery; text: i18n("Show Main Battery") }
				QQC2.CheckBox { id: showDeviceSerials; text: i18n("Show Device Details (MAC/Serial)") }
				QQC2.CheckBox { id: showPowerProfile; text: i18n("Show Power Profile Setting") }
				QQC2.CheckBox { id: showSleepInhibitor; text: i18n("Show Sleep Inhibitor") }

				Kirigami.Separator { 
					Kirigami.FormData.isSection: true
					Kirigami.FormData.label: i18n("Sorting") 
				}
				QQC2.CheckBox { id: smartSortDevices; text: i18n("Smart Sort (Lowest charge first)") }

				Kirigami.Separator { 
					Kirigami.FormData.isSection: true
					Kirigami.FormData.label: i18n("Visual Signature (Device Icons)") 
				}

				FileDialog {
					id: iconFileDialog
					title: i18n("Select Custom Icon (.png, .svg)")
					nameFilters: ["Images (*.png *.svg *.jpg)"]
					property string targetDevice: ""
					onAccepted: {
						var map = JSON.parse(hiddenIconMapField.text || "{}");
						if (!map[targetDevice]) map[targetDevice] = {};
						map[targetDevice].path = selectedFile.toString();
						hiddenIconMapField.text = JSON.stringify(map);
					}
				}

				Repeater {
					model: hiddenKnownDevicesField.text ? hiddenKnownDevicesField.text.split("|") : []
					delegate: RowLayout {
						Layout.fillWidth: true
						property string devKey: modelData
						property string displayLabel: devKey === "MainComputer" ? i18n("Computer") : devKey
						visible: devKey !== ""

						property var mappingData: {
							try {
								var map = JSON.parse(hiddenIconMapField.text || "{}");
								return map[devKey] || {type: 0, path: ""};
							} catch(e) { return {type: 0, path: ""}; }
						}

						Kirigami.FormData.label: displayLabel + ":"
						
						QQC2.ComboBox {
							model: [
								i18n("Default"), i18n("Laptop"), i18n("Desktop"), i18n("Server"), 
								i18n("Phone"), i18n("Tablet"), i18n("Keyboard"), i18n("Mouse"), 
								i18n("Headphones"), i18n("Earbuds"), 
								i18n("Gamepad"), i18n("Smartwatch"), i18n("Speaker"), 
								i18n("Select Custom Image...")
							]
							currentIndex: mappingData.type || 0
							Layout.preferredWidth: 180
							onActivated: {
								var map = JSON.parse(hiddenIconMapField.text || "{}");
								if (!map[devKey]) map[devKey] = {};
								map[devKey].type = currentIndex;
								hiddenIconMapField.text = JSON.stringify(map);
							}
						}

						QQC2.TextField {
							visible: mappingData.type === 13
							Layout.fillWidth: true
							placeholderText: i18n("Image path...")
							text: mappingData.path
							onEditingFinished: {
								var map = JSON.parse(hiddenIconMapField.text || "{}");
								if (!map[devKey]) map[devKey] = {};
								map[devKey].path = text;
								hiddenIconMapField.text = JSON.stringify(map);
							}
						}

						QQC2.Button {
							visible: mappingData.type === 13
							icon.name: "document-open"
							text: i18n("Browse")
							onClicked: {
								iconFileDialog.targetDevice = devKey;
								iconFileDialog.open();
							}
						}
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: Kirigami.Units.largeSpacing

				Item { Layout.fillHeight: true } 

				Kirigami.Icon {
					source: "love" 
					implicitWidth: 64
					implicitHeight: 64
					Layout.alignment: Qt.AlignHCenter
				}

				QQC2.Label {
					text: i18n("Support PowerHub Development")
					font.bold: true
					font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3
					Layout.alignment: Qt.AlignHCenter
				}

				QQC2.Label {
					text: i18n("If you found this tool useful and want me to continue developing it, you can buy me a coffee!")
					wrapMode: Text.WordWrap
					horizontalAlignment: Text.AlignHCenter
					Layout.fillWidth: true
					Layout.maximumWidth: 350
					Layout.alignment: Qt.AlignHCenter
					opacity: 0.8
				}

				QQC2.Button {
					text: i18n("☕ Buy Me a Coffee")
					font.bold: true
					Layout.alignment: Qt.AlignHCenter
					Layout.topMargin: Kirigami.Units.largeSpacing
					onClicked: {
						Qt.openUrlExternally("https://buymeacoffee.com/merchin")
					}
				}

				Item { Layout.fillHeight: true }
			}
		}
	}
}
