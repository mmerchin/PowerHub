import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import Qt5Compat.GraphicalEffects 6.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import "providers"

PlasmoidItem {
	id: root

	UPowerProvider { 
		id: upowerProvider 
	}
	property var providers: [upowerProvider]

	property var kdeConnectDevicesList: [] 
	property int powerProfileVal: 1 
	property var inhibitorsList: [] 

	property string sysQdbusCmd: "qdbus"
	property bool sysHasPPD: false
	property bool sysHasTLP: false
	property int sysInhibitType: 0
	property bool isSysChecked: false

	P5Support.DataSource {
		id: sysCheckSource
		engine: "executable"
		connectedSources: ["bash -c 'Q=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus); P=$(command -v powerprofilesctl >/dev/null && echo 1 || echo 0); T=$(command -v tlp >/dev/null && echo 1 || echo 0); I=$(command -v systemd-inhibit >/dev/null && echo 2 || (command -v kde-inhibit >/dev/null && echo 1 || echo 0)); echo \"SYSCHECK@@$Q@@$P@@$T@@$I\"'"]
		onNewData: (sourceName, data) => {
			var out = data["stdout"] ? data["stdout"].trim() : "";
			if (out.startsWith("SYSCHECK@@")) {
				var parts = out.split("@@");
				root.sysQdbusCmd = parts[1] || "qdbus";
				root.sysHasPPD = (parts[2] === "1");
				root.sysHasTLP = (parts[3] === "1");
				root.sysInhibitType = parseInt(parts[4] || "0");
				root.isSysChecked = true;
				
				dataPoller.connectSource(root.dynamicPollCmd);
				disconnectSource(sourceName);
			}
		}
	}

	function decodeOctalUTF8(str) { 
		try { 
			var decoded = str.replace(/\\([0-7]{3})/g, function(match, p1) { 
				return '%' + parseInt(p1, 8).toString(16); 
			}); 
			return decodeURIComponent(decoded); 
		} catch(e) { 
			return str; 
		} 
	}
	function formatAppName(appName) { 
		var lower = appName.toLowerCase(); 
		if (lower.indexOf("youtube") !== -1) return "YouTube"; 
		if (lower.indexOf("firefox") !== -1) return "Firefox"; 
		if (lower.indexOf("chrome") !== -1) return "Google Chrome"; 
		if (lower.indexOf("brave") !== -1) return "Brave"; 
		if (lower.indexOf("vlc") !== -1) return "VLC"; 
		if (lower.indexOf("spotify") !== -1) return "Spotify"; 
		return appName.charAt(0).toUpperCase() + appName.slice(1); 
	}
	function getIconForApp(appName, reason) { 
		var lowerApp = appName.toLowerCase(); 
		var lowerReason = reason.toLowerCase(); 
		if (lowerApp.indexOf("youtube") !== -1) return "youtube"; 
		if (lowerApp.indexOf("firefox") !== -1) return "firefox"; 
		if (lowerApp.indexOf("chrome") !== -1) return "google-chrome"; 
		if (lowerApp.indexOf("brave") !== -1) return "brave"; 
		if (lowerApp.indexOf("spotify") !== -1) return "spotify"; 
		if (lowerApp.indexOf("vlc") !== -1) return "vlc"; 
		if (lowerReason.indexOf("ses") !== -1 || lowerReason.indexOf("audio") !== -1) return "audio-volume-high"; 
		if (lowerReason.indexOf("video") !== -1 || lowerReason.indexOf("oynat") !== -1) return "media-playback-start"; 
		return "application-x-executable"; 
	}

	property string dynamicPollCmd: {
		if (!isSysChecked) return "";
		
		var ppdCmd = sysHasPPD ? "powerprofilesctl get 2>/dev/null" : "echo \"none\"";
		var qdbusCmd = "QDBUS=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus); ";
		var kdeCmd = "PH=\"\"; if [ -n \"$QDBUS\" ]; then for ID in $(timeout 1s kdeconnect-cli -a --id-only 2>/dev/null); do C=$(timeout 1s $QDBUS org.kde.kdeconnect /modules/kdeconnect/devices/$ID/battery org.kde.kdeconnect.device.battery.charge 2>/dev/null); N=$(timeout 1s $QDBUS org.kde.kdeconnect /modules/kdeconnect/devices/$ID org.kde.kdeconnect.device.name 2>/dev/null); I=$(timeout 1s $QDBUS org.kde.kdeconnect /modules/kdeconnect/devices/$ID/battery org.kde.kdeconnect.device.battery.isCharging 2>/dev/null); if [ -n \"$C\" ] && [ -n \"$N\" ]; then [ -n \"$PH\" ] && PH=\"${PH};;\"; PH=\"${PH}${N}|${C}|${I}\"; fi; done; fi; [ -z \"$PH\" ] && PH=\"NOT_FOUND\"; ";
		var inhCmd = (sysInhibitType === 2) ? "O2=$(timeout 1s systemd-inhibit --list --no-pager --no-legend 2>/dev/null | awk \"/sleep|idle/ {print \\$1}\"); " : "O2=\"\"; ";
		var inhCleanCmd = "O2_CLEAN=$(echo -e \"$O2\" | grep -viE \"error|method|batterywatch|powerdevil|upower|networkmanager|modemmanager|compositor|realtime|vm_inhibitor|inhibitor|kwin|ksmserver|kded6\" | grep -v \"^$\" | sort -u | paste -sd \", \" -); ";
		var solidCmd = "O3_RAW=$(timeout 1s busctl --user call org.kde.Solid.PowerManagement.PolicyAgent /org/kde/Solid/PowerManagement/PolicyAgent org.kde.Solid.PowerManagement.PolicyAgent ListInhibitions 2>/dev/null); ";
		var echoCmd = "echo \"$P@@$PH@@$O2_CLEAN@@$O3_RAW\"";

		return "bash -c '" + qdbusCmd + "P=$(" + ppdCmd + "); " + kdeCmd + inhCmd + inhCleanCmd + solidCmd + echoCmd + "'";
	}

	P5Support.DataSource {
		id: dataPoller
		engine: "executable"
		connectedSources: []
		interval: 3000
		
		onNewData: (sourceName, data) => {
			var out = data["stdout"] ? data["stdout"].trim() : ""; 
			if (!out) return;
			
			var sections = out.split("@@");
			if (sections.length >= 4) {
				var p = sections[0];
				if (p === "power-saver") root.powerProfileVal = 0;
				else if (p === "performance") root.powerProfileVal = 2;
				else root.powerProfileVal = 1;

				var ph = sections[1]; 
				var parsedDevices = [];
				if (ph && ph !== "NOT_FOUND") {
					var devicesArray = ph.split(";;");
					for (var j = 0; j < devicesArray.length; j++) { 
						var parts = devicesArray[j].split("|"); 
						if (parts.length === 3) {
							parsedDevices.push({ name: parts[0], percentage: parseInt(parts[1]), isCharging: (parts[2] === "true") }); 
						}
					}
				}
				root.kdeConnectDevicesList = parsedDevices;

				var sysInh = sections[2] || ""; 
				var kdeInhRaw = sections[3] || ""; 
				var arr = [];
				function addOrUpdateInhibitor(aName, aReason, aIcon) { 
					for (var i = 0; i < arr.length; i++) { 
						if (arr[i].appName === aName) { 
							if (arr[i].reason.indexOf(aReason) === -1) arr[i].reason += ", " + aReason; 
							return; 
						} 
					} 
					arr.push({ appName: aName, reason: aReason, iconName: aIcon }); 
				}
				
				var regex = /"([^"]+)"/g; 
				var matches = []; 
				var match;
				while ((match = regex.exec(kdeInhRaw)) !== null) { 
					matches.push(root.decodeOctalUTF8(match[1])); 
				}
				
				for (var k = 0; k < matches.length; k += 2) { 
					if (k + 1 < matches.length) { 
						addOrUpdateInhibitor(root.formatAppName(matches[k]), matches[k+1], root.getIconForApp(matches[k], matches[k+1])); 
					} 
				}
				
				if (sysInh) { 
					var sArr = sysInh.split(", "); 
					for (var m = 0; m < sArr.length; m++) { 
						var cleaned = sArr[m].trim(); 
						if (cleaned) addOrUpdateInhibitor(root.formatAppName(cleaned), i18n("Locking system"), root.getIconForApp(cleaned, "")); 
					} 
				}
				root.inhibitorsList = arr;
			}
		}
	}

	P5Support.DataSource { 
		id: cmdRunner
		engine: "executable"
		onNewData: (sourceName, data) => { disconnectSource(sourceName); } 
	}
	
	function runCmd(cmd) { cmdRunner.connectSource(cmd + " # " + new Date().getTime()); }

	property string inhibitCmd: {
		if (sysInhibitType === 2) return "systemd-inhibit --what=idle:sleep --who=\"PowerHub\" --why=\"Manuel\" sleep 999999999";
		else if (sysInhibitType === 1) return "kde-inhibit --power --screenSaver sleep 999999999";
		return "";
	}
	
	P5Support.DataSource { id: inhibitSource; engine: "executable" }

	property var allDevices: mergeDevices(
		providers.map(p => p.devices), 
		kdeConnectDevicesList,
		Plasmoid.configuration.showMainBattery,
		Plasmoid.configuration.smartSortDevices,
		Plasmoid.configuration.deviceIconMap
	)

	function mergeDevices(deviceProviders, kcDevices, showMain, smartSort, iconMapString) {
		var merged = [];
		var seenIds = {};
		
		function resolveIcon(deviceKey, originalIcon) {
			try {
				var map = JSON.parse(iconMapString || "{}");
				var conf = map[deviceKey];
				if (!conf) return originalIcon;
				
				switch(conf.type) {
					case 0: return originalIcon;
					case 1: return "computer-laptop";
					case 2: return "computer";
					case 3: return "network-server";
					case 4: return "smartphone";
					case 5: return "tablet";
					case 6: return "input-keyboard";
					case 7: return "input-mouse";
					case 8: return "audio-headphones";
					case 9: return "audio-headset";
					case 10: return "input-gaming";
					case 11: return "smartwatch";
					case 12: return "audio-speakers";
					case 13: return conf.path !== "" ? conf.path : originalIcon;
					default: return originalIcon;
				}
			} catch(e) { return originalIcon; }
		}

		for (var pIdx = 0; pIdx < deviceProviders.length; pIdx++) {
			var devices = deviceProviders[pIdx];
			for (var i = 0; i < devices.length; i++) {
				var device = devices[i];
				var id = device.serial || device.objectPath || "";
				if (id && !seenIds[id]) {
					var isMain = (device.name === "Primary" || device.name === "Bilgisayar" || device.name === "Computer" || device.name === i18n("Computer") || device.name === "Ordinateur" || device.name === "Ordenador" || device.name === "Computador" || device.name === "Компьютер" || device.name === "电脑" || device.name === "コンピューター");
					if (isMain) {
						if (!showMain) continue;
						device.name = i18n("Computer");
						device.key = "MainComputer";
					} else {
						device.key = device.name;
					}
					device.icon = resolveIcon(device.key, device.icon);
					merged.push(device);
					seenIds[id] = true;
				}
			}
		}

		for (var k = 0; k < kcDevices.length; k++) {
			var kcDev = {
				"name": kcDevices[k].name,
				"percentage": kcDevices[k].percentage,
				"icon": "smartphone",
				"serial": i18n("KDE Connect"),
				"isCharging": kcDevices[k].isCharging,
				"key": kcDevices[k].name
			};
			kcDev.icon = resolveIcon(kcDev.key, kcDev.icon);
			merged.push(kcDev);
		}

		var activeKeys = ["MainComputer"];
		for (var m = 0; m < merged.length; m++) {
			var mKey = merged[m].key;
			if (mKey && mKey !== "MainComputer" && activeKeys.indexOf(mKey) === -1) activeKeys.push(mKey);
		}
		
		var activeKeysStr = activeKeys.join("|");
		if (Plasmoid.configuration.knownDevices !== activeKeysStr) Plasmoid.configuration.knownDevices = activeKeysStr;

		merged.sort((a, b) => {
			if (a.key === "MainComputer") return -1;
			if (b.key === "MainComputer") return 1;
			if (smartSort) return a.percentage - b.percentage;
			return (a.name || "").localeCompare(b.name || "");
		});
		return merged;
	}

	property int mainBatteryLevel: 0
	property bool mainIsCharging: false
	property bool mainIsPlugged: false

	function updateBatteryState() {
		var bData = batterySource.data["Battery"];
		if (bData) {
			if (bData["Percent"] !== undefined) root.mainBatteryLevel = bData["Percent"];
			root.mainIsCharging = (bData["State"] === "Charging");
			root.mainIsPlugged = !root.mainIsCharging && (bData["State"] === "Full" || bData["State"] === "Not Charging" || root.mainBatteryLevel === 100);
		}
	}

	P5Support.DataSource {
		id: batterySource
		engine: "powermanagement"
		connectedSources: ["Battery"]
		onDataChanged: root.updateBatteryState()
		onNewData: (sourceName, data) => root.updateBatteryState()
	}

	Timer {
		id: bootTimer
		property int attempts: 0
		interval: 250
		running: true
		repeat: true
		onTriggered: {
			root.updateBatteryState();
			attempts++;
			if (root.mainBatteryLevel > 0 || attempts > 20) running = false;
		}
	}

	Component.onCompleted: root.updateBatteryState()

	compactRepresentation: Item {
		id: compactRoot
		
		// YÜKSEKLİK AYARI (Kullanıcı değer girmezse varsayılan 24px kalır)
		readonly property int customH: Plasmoid.configuration.panelIconHeight > 0 ? Plasmoid.configuration.panelIconHeight : 24
		readonly property int totalW: Plasmoid.configuration.panelIconWidth + Plasmoid.configuration.panelLeftMargin + Plasmoid.configuration.panelRightMargin
		
		Layout.minimumWidth: totalW
		Layout.preferredWidth: totalW
		Layout.maximumWidth: totalW
		implicitWidth: totalW
		implicitHeight: customH

		property int currentFontSize: Plasmoid.configuration.useAutoFontSize ? 13 : Plasmoid.configuration.customFontSize

		readonly property color batteryColor: {
			var mode = Plasmoid.configuration.profileDisplayStyle;
			var cEco = Plasmoid.configuration.useAutoProfileColors ? "#87b07c" : Plasmoid.configuration.customEcoColor;
			var cBal = Plasmoid.configuration.useAutoProfileColors ? "#ffffff" : Plasmoid.configuration.customBalancedColor;
			var cPerf = Plasmoid.configuration.useAutoProfileColors ? "#3498db" : Plasmoid.configuration.customPerformanceColor;

			if (root.mainBatteryLevel > 0 && root.mainBatteryLevel <= 20) return "#ff4d4d"; 
			if (root.mainIsPlugged && root.mainBatteryLevel < 100) return "#f1c40f"; 
			if (mode === 0) return "#ffffff";
			if (root.powerProfileVal === 0) return cEco; 
			if (root.powerProfileVal === 2) return cPerf; 
			return cBal; 
		}

		Item {
			anchors.fill: parent
			anchors.leftMargin: Plasmoid.configuration.panelLeftMargin
			anchors.rightMargin: Plasmoid.configuration.panelRightMargin
			anchors.topMargin: 2
			anchors.bottomMargin: 2

			Rectangle {
				id: batteryFrame
				anchors.centerIn: parent
				width: Plasmoid.configuration.panelIconWidth
				height: compactRoot.customH > 4 ? compactRoot.customH - 4 : compactRoot.customH
				color: "transparent"
				border.width: 0 
				radius: Plasmoid.configuration.panelIconRadius

				Rectangle {
					anchors.fill: parent
					color: compactRoot.batteryColor
					opacity: 0.15
					radius: Plasmoid.configuration.panelIconRadius
				}

				Rectangle {
					id: batteryFill
					anchors.left: parent.left
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					width: parent.width * (root.mainBatteryLevel / 100)
					color: compactRoot.batteryColor
					radius: Plasmoid.configuration.panelIconRadius
					Behavior on width { NumberAnimation { duration: 400 } }
					opacity: 1.0
				}

				Canvas {
					id: dynamicCanvas
					anchors.fill: parent

					onPaint: {
						var ctx = getContext("2d");
						ctx.reset();

						var fillWidth = batteryFill.width;
						var totalWidth = width;
						var totalHeight = height;

						var fSize = compactRoot.currentFontSize;
						ctx.font = "bold " + fSize + "px sans-serif";
						ctx.textBaseline = "middle";
						ctx.textAlign = "center";

						// YÜZDE GÖSTER/GİZLE KONTROLÜ
						var showPercentage = Plasmoid.configuration.showPercentage !== undefined ? Plasmoid.configuration.showPercentage : true;
						var textStr = (showPercentage && root.mainBatteryLevel > 0) ? root.mainBatteryLevel.toString() : "";
						var textW = textStr !== "" ? ctx.measureText(textStr).width : 0;
						
						var mode = Plasmoid.configuration.profileDisplayStyle;
						var prof = root.powerProfileVal;
						var isCharging = root.mainIsCharging;

						var showIcon = 0; 
						
						// EĞER YÜZDE KAPALIYSA VE ŞARJ OLUYORSA FİŞ (PLUG) İKONU GÖSTER
						if (!showPercentage && isCharging) {
							showIcon = 4;
						} else if (mode === 0) { 
							if (isCharging) showIcon = 1;
							else if (prof === 2) showIcon = 2;
							else if (prof === 0) showIcon = 3;
						} else if (mode === 1) { 
							showIcon = 0; 
						} else if (mode === 2) { 
							if (prof === 2) showIcon = 2;
							else if (prof === 0) showIcon = 3;
						}

						var boltW = fSize * 0.55;
						var boltH = fSize * 0.85;
						var spacing = fSize * 0.2;

						var contentW = 0;
						if (showIcon === 4) {
							contentW = fSize * 0.6; // Fiş ikonu için yer ayrılıyor
						} else if (showIcon > 0 && textStr !== "") {
							contentW = boltW + spacing + textW;
						} else if (showIcon > 0) {
							contentW = boltW;
						} else {
							contentW = textW;
						}

						var startX = (totalWidth - contentW) / 2;
						var textY = (totalHeight / 2) + (fSize * 0.08); 

						function drawContent(color) {
							ctx.fillStyle = color;
							ctx.strokeStyle = color;

							if (showIcon === 4) {
								// MERKEZE ÇİZİLEN FİŞ İKONU (Performans yıldırımı yerine)
								var pW = fSize * 0.5;
								var pH = fSize * 0.7;
								var pX = startX + (contentW - pW) / 2;
								var pY = (totalHeight - pH) / 2;

								ctx.lineWidth = Math.max(1.5, fSize * 0.1);
								ctx.lineCap = "round";
								ctx.lineJoin = "round";

								// Fiş Uçları (Prongs)
								ctx.beginPath();
								ctx.moveTo(pX + pW * 0.25, pY);
								ctx.lineTo(pX + pW * 0.25, pY + pH * 0.3);
								ctx.moveTo(pX + pW * 0.75, pY);
								ctx.lineTo(pX + pW * 0.75, pY + pH * 0.3);
								ctx.stroke();

								// Fiş Gövdesi
								ctx.fillRect(pX, pY + pH * 0.3, pW, pH * 0.4);

								// Alt Kablo
								ctx.beginPath();
								ctx.moveTo(pX + pW * 0.5, pY + pH * 0.7);
								ctx.lineTo(pX + pW * 0.5, pY + pH);
								ctx.stroke();

							} else if (showIcon > 0) {
								var bX = startX;
								var bY = (totalHeight - boltH) / 2;
								
								ctx.beginPath();
								if (showIcon === 1 || showIcon === 2) {
									ctx.moveTo(bX + boltW * 0.6, bY);
									ctx.lineTo(bX, bY + boltH * 0.55);
									ctx.lineTo(bX + boltW * 0.45, bY + boltH * 0.55);
									ctx.lineTo(bX + boltW * 0.3, bY + boltH);
									ctx.lineTo(bX + boltW, bY + boltH * 0.4);
									ctx.lineTo(bX + boltW * 0.55, bY + boltH * 0.4);
								} else if (showIcon === 3) {
									var lX = bX; var lY = bY; var lW = boltW; var lH = boltH;
									ctx.moveTo(lX + lW * 0.2, lY + lH * 0.9);
									ctx.quadraticCurveTo(lX - lW * 0.2, lY + lH * 0.3, lX + lW * 0.8, lY + lH * 0.1);
									ctx.quadraticCurveTo(lX + lW * 0.9, lY + lH * 0.8, lX + lW * 0.2, lY + lH * 0.9);
								}
								ctx.closePath();
								ctx.fill();
								
								if (textStr !== "") {
									var textCenterX = startX + boltW + spacing + (textW / 2);
									ctx.fillText(textStr, textCenterX, textY);
								}
							} else {
								if (textStr !== "") {
									ctx.fillText(textStr, totalWidth / 2, textY);
								}
							}
						}

						var autoContrastColor = (compactRoot.batteryColor === "#ff4d4d" || compactRoot.batteryColor === "#3498db" || compactRoot.batteryColor === "#87b07c") ? "#ffffff" : "#000000";
						var leftSideColor = "#ffffff";
						var rightSideColor = "#000000";

						if (mode === 0) {
							var baseTextC = Plasmoid.configuration.useAutoTextColor ? autoContrastColor : Plasmoid.configuration.customTextColor;
							var baseRightC = Plasmoid.configuration.useAutoTextColor ? compactRoot.batteryColor : Plasmoid.configuration.customTextColor;
							if (isCharging) {
								leftSideColor = Plasmoid.configuration.chargingHighlightColor;
								rightSideColor = Plasmoid.configuration.chargingHighlightColor;
							} else {
								leftSideColor = baseTextC;
								rightSideColor = baseRightC;
							}
						} else if (mode === 1) {
							var textC1 = autoContrastColor;
							if (!Plasmoid.configuration.useAutoProfileColors) {
								if (prof === 0) textC1 = Plasmoid.configuration.customEcoTextColor;
								else if (prof === 2) textC1 = Plasmoid.configuration.customPerformanceTextColor;
								else textC1 = Plasmoid.configuration.customBalancedTextColor;
							}
							if (isCharging) {
								leftSideColor = "#f6e58d"; rightSideColor = "#f6e58d";
							} else {
								leftSideColor = textC1;
								rightSideColor = Plasmoid.configuration.useAutoProfileColors ? compactRoot.batteryColor : textC1;
							}
						} else if (mode === 2) {
							var textC2 = autoContrastColor;
							var chargeC2 = "#f6e58d";
							if (!Plasmoid.configuration.useAutoProfileColors) {
								if (prof === 0) { textC2 = Plasmoid.configuration.customEcoTextColor; chargeC2 = Plasmoid.configuration.customEcoChargingColor; }
								else if (prof === 2) { textC2 = Plasmoid.configuration.customPerformanceTextColor; chargeC2 = Plasmoid.configuration.customPerformanceChargingColor; }
								else { textC2 = Plasmoid.configuration.customBalancedTextColor; chargeC2 = Plasmoid.configuration.customBalancedChargingColor; }
							}
							if (isCharging) {
								leftSideColor = chargeC2; rightSideColor = chargeC2;
							} else {
								leftSideColor = textC2;
								rightSideColor = Plasmoid.configuration.useAutoProfileColors ? compactRoot.batteryColor : textC2;
							}
						}

						ctx.save();
						ctx.beginPath();
						ctx.rect(0, 0, fillWidth, totalHeight);
						ctx.clip();
						drawContent(leftSideColor);
						ctx.restore();

						ctx.save();
						ctx.beginPath();
						ctx.rect(fillWidth, 0, totalWidth - fillWidth, totalHeight);
						ctx.clip();
						drawContent(rightSideColor); 
						ctx.restore();
					}

					Connections {
						target: root
						function onMainBatteryLevelChanged() { dynamicCanvas.requestPaint(); }
						function onMainIsChargingChanged() { dynamicCanvas.requestPaint(); }
						function onPowerProfileValChanged() { dynamicCanvas.requestPaint(); }
					}
					Connections {
						target: batteryFill
						function onWidthChanged() { dynamicCanvas.requestPaint(); }
					}
					Connections {
						target: compactRoot
						function onBatteryColorChanged() { dynamicCanvas.requestPaint(); }
						function onCurrentFontSizeChanged() { dynamicCanvas.requestPaint(); }
						function onCustomHChanged() { dynamicCanvas.requestPaint(); }
					}
					Connections {
						target: Plasmoid.configuration
						function onProfileDisplayStyleChanged() { dynamicCanvas.requestPaint(); }
						function onChargingHighlightColorChanged() { dynamicCanvas.requestPaint(); }
						function onUseAutoTextColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomTextColorChanged() { dynamicCanvas.requestPaint(); }
						function onUseAutoProfileColorsChanged() { dynamicCanvas.requestPaint(); }
						function onCustomEcoColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomBalancedColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomPerformanceColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomEcoTextColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomBalancedTextColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomPerformanceTextColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomEcoChargingColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomBalancedChargingColorChanged() { dynamicCanvas.requestPaint(); }
						function onCustomPerformanceChargingColorChanged() { dynamicCanvas.requestPaint(); }
						function onShowPercentageChanged() { dynamicCanvas.requestPaint(); }
						function onPanelIconHeightChanged() { dynamicCanvas.requestPaint(); }
					}
				}
			}
		}
		MouseArea { 
			anchors.fill: parent
			onClicked: { root.expanded = !root.expanded; } 
		}
	}

	fullRepresentation: Item {
		id: fullRoot
		Layout.minimumWidth: Kirigami.Units.gridUnit * 30
		Layout.preferredWidth: Kirigami.Units.gridUnit * 30
		property int contentHeight: mainColumn.implicitHeight > 0 ? (mainColumn.implicitHeight + Kirigami.Units.largeSpacing * 2) : 200
		Layout.minimumHeight: Math.min(contentHeight, 700)
		Layout.preferredHeight: Math.min(contentHeight, 700)
		Layout.maximumHeight: Math.min(contentHeight, 700)

		ScrollView {
			id: scrollView
			anchors.fill: parent
			clip: true
			ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
			ScrollBar.vertical.policy: ScrollBar.AsNeeded

			ColumnLayout {
				id: mainColumn
				width: scrollView.availableWidth
				spacing: 0

				PlasmaComponents.Label {
					text: i18n("Device Battery Statuses")
					font.bold: true
					font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
					Layout.fillWidth: true
					Layout.margins: Kirigami.Units.largeSpacing
				}

				Repeater {
					model: root.allDevices
					delegate: ColumnLayout {
						Layout.fillWidth: true
						Layout.leftMargin: Kirigami.Units.largeSpacing
						Layout.rightMargin: Kirigami.Units.largeSpacing + 4
						spacing: 0

						RowLayout {
							Layout.fillWidth: true
							Layout.preferredHeight: Kirigami.Units.gridUnit * 3
							spacing: Kirigami.Units.largeSpacing

							Item {
								implicitWidth: Kirigami.Units.iconSizes.medium
								implicitHeight: Kirigami.Units.iconSizes.medium
								Layout.alignment: Qt.AlignVCenter
								Kirigami.Icon {
									source: modelData.icon || "battery-none"
									anchors.fill: parent
								}
							}

							ColumnLayout {
								Layout.fillWidth: true
								spacing: 0
								PlasmaComponents.Label {
									text: modelData.name || i18n("Unknown Device")
									font.bold: true
									elide: Text.ElideRight
									Layout.fillWidth: true
								}
								PlasmaComponents.Label {
									text: modelData.serial || ""
									visible: Plasmoid.configuration.showDeviceSerials && text !== ""
									font.pixelSize: Kirigami.Theme.smallFont.pixelSize
									opacity: 0.6
									elide: Text.ElideRight
									Layout.fillWidth: true
								}
							}

							RowLayout {
								spacing: Kirigami.Units.smallSpacing
								Layout.alignment: Qt.AlignRight

								property bool isChargingState: {
									if (modelData.key === "MainComputer") return root.mainIsCharging;
									if (modelData.isCharging !== undefined && modelData.isCharging) return true;
									if (modelData.charging !== undefined && modelData.charging) return true;
									if (modelData.state !== undefined && modelData.state === 1) return true;
									if (modelData.status !== undefined && (modelData.status === 1 || String(modelData.status).toLowerCase() === "charging")) return true;
									if (modelData.icon && String(modelData.icon).toLowerCase().indexOf("charging") !== -1) return true;
									return false;
								}

								property bool isPluggedState: {
									if (modelData.key === "MainComputer") return root.mainIsPlugged;
									if (modelData.percentage === 100 && !isChargingState) return true;
									if (modelData.state !== undefined && (modelData.state === 4 || modelData.state === 5)) return true;
									if (modelData.status !== undefined && (String(modelData.status).toLowerCase() === "full" || String(modelData.status).toLowerCase() === "not-charging")) return true;
									if (modelData.icon && String(modelData.icon).toLowerCase().indexOf("full") !== -1 && !isChargingState) return true;
									return false;
								}

								Item {
									visible: parent.isChargingState
									implicitWidth: 10
									implicitHeight: 14
									Layout.alignment: Qt.AlignVCenter
									Canvas {
										anchors.fill: parent
										onPaint: {
											var ctx = getContext("2d");
											ctx.reset();
											ctx.fillStyle = "#2ecc71";
											ctx.beginPath(); 
											ctx.moveTo(width*0.6, 0); 
											ctx.lineTo(0, height*0.55);
											ctx.lineTo(width*0.45, height*0.55); 
											ctx.lineTo(width*0.3, height);
											ctx.lineTo(width, height*0.4); 
											ctx.lineTo(width*0.55, height*0.4);
											ctx.closePath(); 
											ctx.fill();
										}
									}
								}

								Item {
									visible: parent.isPluggedState
									implicitWidth: 12
									implicitHeight: 14
									Layout.alignment: Qt.AlignVCenter
									Canvas {
										anchors.fill: parent
										onPaint: {
											var ctx = getContext("2d");
											ctx.reset();
											ctx.strokeStyle = "#3498db";
											ctx.fillStyle = "#3498db";
											ctx.lineWidth = 1.5;
											ctx.fillRect(2, 5, 8, 5);
											ctx.beginPath();
											ctx.moveTo(4, 5); ctx.lineTo(4, 1);
											ctx.moveTo(8, 5); ctx.lineTo(8, 1);
											ctx.stroke();
											ctx.beginPath();
											ctx.moveTo(6, 10); ctx.lineTo(6, 14);
											ctx.stroke();
										}
									}
								}

								PlasmaComponents.Label {
									text: "%" + modelData.percentage
									font.bold: true
									font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
									color: modelData.percentage <= 20 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
								}
							}
						}
					}
				}

				Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }

				Kirigami.Separator {
					visible: Plasmoid.configuration.showPowerProfile
					Layout.fillWidth: true
					Layout.leftMargin: Kirigami.Units.largeSpacing
					Layout.rightMargin: Kirigami.Units.largeSpacing + 4
					Layout.topMargin: Kirigami.Units.smallSpacing
					Layout.bottomMargin: Kirigami.Units.largeSpacing
				}

				RowLayout {
					visible: Plasmoid.configuration.showPowerProfile
					Layout.fillWidth: true
					Layout.leftMargin: Kirigami.Units.largeSpacing
					Layout.rightMargin: Kirigami.Units.largeSpacing + 4
					spacing: Kirigami.Units.largeSpacing

					Kirigami.Icon {
						source: "speedometer"
						implicitWidth: Kirigami.Units.iconSizes.medium
						implicitHeight: Kirigami.Units.iconSizes.medium
						Layout.alignment: Qt.AlignTop
					}

					ColumnLayout {
						Layout.fillWidth: true
						spacing: Kirigami.Units.smallSpacing

						RowLayout {
							Layout.fillWidth: true
							PlasmaComponents.Label {
								text: root.sysHasPPD ? i18n("Power Profile") : (root.sysHasTLP ? i18n("Power Profile") + " (TLP)" : i18n("Power Profile") + " ⚠️")
								font.bold: true
								color: root.sysHasPPD ? Kirigami.Theme.textColor : Kirigami.Theme.neutralTextColor
							}
							Item { Layout.fillWidth: true }
							PlasmaComponents.Label {
								visible: root.sysHasPPD
								text: root.powerProfileVal === 0 ? i18n("Power Save") : (root.powerProfileVal === 2 ? i18n("Performance") : i18n("Balanced"))
								opacity: 0.8
							}
						}

						PlasmaComponents.Slider {
							id: profileSlider
							Layout.fillWidth: true
							enabled: root.sysHasPPD
							opacity: root.sysHasPPD ? 1.0 : 0.5
							from: 0; to: 2; stepSize: 1
							value: root.powerProfileVal
							onMoved: {
								if (!root.sysHasPPD) return;
								var cmd = "";
								if (value === 0) cmd = "powerprofilesctl set power-saver";
								else if (value === 1) cmd = "powerprofilesctl set balanced";
								else cmd = "powerprofilesctl set performance";
								runCmd(cmd);
								root.powerProfileVal = value;
							}
							Connections {
								target: root
								function onPowerProfileValChanged() {
									if (!profileSlider.pressed) profileSlider.value = root.powerProfileVal;
								}
							}
						}

						RowLayout {
							Layout.fillWidth: true
							opacity: root.sysHasPPD ? 1.0 : 0.5
							Kirigami.Icon { source: "battery-profile-powersave"; implicitWidth: 16; implicitHeight: 16; opacity: root.powerProfileVal === 0 ? 1.0 : 0.5 }
							Item { Layout.fillWidth: true }
							Kirigami.Icon { source: "battery-profile-performance"; implicitWidth: 16; implicitHeight: 16; opacity: root.powerProfileVal === 2 ? 1.0 : 0.5 }
						}
					}
				}

				Kirigami.Separator {
					visible: Plasmoid.configuration.showSleepInhibitor
					Layout.fillWidth: true
					Layout.leftMargin: Kirigami.Units.largeSpacing
					Layout.rightMargin: Kirigami.Units.largeSpacing + 4
					Layout.topMargin: Kirigami.Units.largeSpacing
					Layout.bottomMargin: Kirigami.Units.largeSpacing
				}

				ColumnLayout {
					visible: Plasmoid.configuration.showSleepInhibitor
					Layout.fillWidth: true
					Layout.leftMargin: Kirigami.Units.largeSpacing
					Layout.rightMargin: Kirigami.Units.largeSpacing + 4
					Layout.bottomMargin: Kirigami.Units.largeSpacing
					spacing: Kirigami.Units.smallSpacing

					RowLayout {
						Layout.fillWidth: true
						spacing: Kirigami.Units.largeSpacing
						Kirigami.Icon { source: "system-suspend-inhibit"; implicitWidth: Kirigami.Units.iconSizes.medium; implicitHeight: Kirigami.Units.iconSizes.medium }
						PlasmaComponents.Switch {
							id: preventSleepSwitch
							text: root.sysInhibitType > 0 ? i18n("Manually Block Sleep and Screen Lock") : i18n("Manually Block Sleep and Screen Lock") + " ⚠️"
							enabled: root.sysInhibitType > 0
							Layout.fillWidth: true
							onCheckedChanged: {
								if (root.sysInhibitType === 0) return;
								if (checked) inhibitSource.connectSource(root.inhibitCmd);
								else {
									inhibitSource.disconnectSource(root.inhibitCmd);
									runCmd("pkill -f 'sleep 999999999'");
								}
							}
						}
					}

					PlasmaComponents.Label {
						text: i18n("No active apps blocking sleep")
						font.pixelSize: Kirigami.Theme.smallFont.pixelSize
						opacity: 0.45
						visible: root.inhibitorsList.length === 0 && root.sysInhibitType > 0
						Layout.fillWidth: true
						Layout.leftMargin: Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing
					}

					Repeater {
						model: root.inhibitorsList
						delegate: RowLayout {
							Layout.fillWidth: true
							Layout.leftMargin: Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing
							spacing: Kirigami.Units.smallSpacing

							Kirigami.Icon {
								source: modelData.iconName
								implicitWidth: 16; implicitHeight: 16
								Layout.alignment: Qt.AlignTop | Qt.AlignLeft
								Layout.topMargin: 2
							}

							ColumnLayout {
								Layout.fillWidth: true
								spacing: 0
								PlasmaComponents.Label {
									text: modelData.appName
									font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
									font.bold: true
									Layout.fillWidth: true
									elide: Text.ElideRight
								}
								PlasmaComponents.Label {
									text: i18n("Blocking screen lock (%1)", modelData.reason)
									font.pixelSize: Kirigami.Theme.smallFont.pixelSize
									opacity: 0.7
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}
					}
				}
			}
		}
	}
}
