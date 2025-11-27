import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../../Singletons" as Singletons
import "../../Singletons/Managers" as Managers

Item {
    id: wifiMenuContent
    implicitWidth: 320
    implicitHeight: 300

    property string selectedSsid: ""
    property string selectedSecurity: ""
    property var sortedNetworks: []
    property bool connecting: Managers.NetworkManager.connecting

    function selectCurrentNetwork() {
        var rawList = Managers.NetworkManager.networks || []
        var visibleList = []

        for (var i = 0; i < rawList.length; ++i) {
            var entry = rawList[i]

            if (entry.ssid && entry.ssid.trim() !== "") {
                visibleList.push(entry)
            }
        }

        var sorted = visibleList.slice(0)
        sorted.sort(function(a, b) {
            if (a.inUse && !b.inUse) return -1
            if (!a.inUse && b.inUse) return 1
            return (b.signal || 0) - (a.signal || 0)
        })
        sortedNetworks = sorted
    }

    Component.onCompleted: selectCurrentNetwork()

    Connections {
        target: Managers.NetworkManager
        function onNetworksChanged() {
            wifiMenuContent.selectCurrentNetwork()
        }
        function onWifiConnectedChanged() {
            wifiMenuContent.selectCurrentNetwork()
        }
        function onPasswordNeeded(ssid) {
            wifiMenuContent.selectedSsid = ssid
            wifiMenuContent.selectedSecurity = ""
            passwordWindow.show()
            passwordWindow.requestActivate()
        }
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 10
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 18
            anchors.bottomMargin: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    id: networkTitle
                    text: "Network"
                    font.bold: true
                    font.pixelSize: 16
                    color: Singletons.Theme.darkBase
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: wifiSwitch.implicitWidth
                    Layout.preferredHeight: wifiSwitch.implicitHeight

                    Switch {
                        id: wifiSwitch
                        anchors.centerIn: parent
                        implicitWidth: indicator.implicitWidth
                        implicitHeight: indicator.implicitHeight
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0

                        checked: Managers.NetworkManager.enabled
                        enabled: Managers.NetworkManager.hardwareEnabled && !wifiMenuContent.connecting

                        onToggled: {
                            Managers.NetworkManager.setWifiEnabled(checked)
                        }

                        Connections {
                            target: Managers.NetworkManager
                            function onEnabledChanged() {
                                wifiSwitch.checked = Managers.NetworkManager.enabled
                            }
                        }

                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 20
                            radius: height / 2
                            color: wifiSwitch.checked
                                   ? Singletons.Theme.accentSoftYellow
                                   : Singletons.Theme.accentSoft
                            border.color: Singletons.Theme.darkBase
                            border.width: 1.5

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                y: (parent.height - height) / 2
                                x: wifiSwitch.checked
                                   ? parent.width - width - 3
                                   : 3
                                color: Singletons.Theme.darkBase
                                border.color: Singletons.Theme.lightBackground
                                border.width: 2

                                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (wifiSwitch.enabled) {
                                Managers.NetworkManager.setWifiEnabled(!wifiSwitch.checked)
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Singletons.Icon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    size: 18
                    color: Singletons.Theme.darkBase
                    source: Managers.NetworkManager.wiredConnected
                            ? Singletons.Theme.iconWired
                            : Managers.NetworkManager.wifiConnected
                              ? (Managers.NetworkManager.strength >= 60
                                 ? Singletons.Theme.iconWifiStrength3
                                 : Managers.NetworkManager.strength >= 40
                                   ? Singletons.Theme.iconWifiStrength2
                                   : Managers.NetworkManager.strength >= 20
                                     ? Singletons.Theme.iconWifiStrength1
                                     : Singletons.Theme.iconWifiStrength0)
                              : Singletons.Theme.iconWifiStrengthSlash
                }

                Text {
                    Layout.fillWidth: true
                    text: wifiMenuContent.connecting
                          ? (wifiMenuContent.selectedSsid !== ""
                             ? "Connecting to " + wifiMenuContent.selectedSsid + "..."
                             : "Talking to NetworkManager...")
                          : Managers.NetworkManager.wiredConnected
                            ? "Connected: " + (Managers.NetworkManager.wiredConnectionName || "Ethernet")
                            : Managers.NetworkManager.wifiConnected && Managers.NetworkManager.ssid !== ""
                              ? "Connected: " + Managers.NetworkManager.ssid
                              : "Not connected"
                    color: Singletons.Theme.darkBase
                    font.pixelSize: 13
                    opacity: 0.8
                    elide: Text.ElideRight
                }
            }

            ListView {
                id: networkList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                enabled: Managers.NetworkManager.enabled
                         && Managers.NetworkManager.hardwareEnabled
                         && !wifiMenuContent.connecting
                opacity: enabled ? 1 : 0.5
                spacing: 4

                model: wifiMenuContent.sortedNetworks

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool selected: wifiMenuContent.selectedSsid === modelData.ssid
                    readonly property string securityLabel: (!modelData.security || modelData.security === "--") ? "Open" : modelData.security
                    readonly property bool isSaved: Managers.NetworkManager.hasSavedConnection(modelData.ssid)

                    width: ListView.view.width
                    height: 40
                    radius: 6
                    color: hovered || selected || modelData.inUse
                           ? Singletons.Theme.accentSoftYellow
                           : "transparent"
                    border.color: selected ? Singletons.Theme.darkBase : modelData.inUse ? Singletons.Theme.darkBase : Singletons.Theme.accentSoft
                    border.width: selected || modelData.inUse ? 2 : 1

                    property bool hovered: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Singletons.Icon {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            size: 18
                            color: Singletons.Theme.darkBase
                            source: {
                                const sig = modelData.signal || 0
                                if (sig >= 75) return Singletons.Theme.iconWifiStrength3
                                if (sig >= 50) return Singletons.Theme.iconWifiStrength2
                                if (sig >= 25) return Singletons.Theme.iconWifiStrength1
                                return Singletons.Theme.iconWifiStrength0
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: modelData.ssid
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                color: Singletons.Theme.darkBase
                                font.pixelSize: 13
                                font.bold: modelData.inUse
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: securityLabel
                                    color: Singletons.Theme.darkBase
                                    font.pixelSize: 11
                                    opacity: 0.7
                                    horizontalAlignment: Text.AlignLeft
                                }

                            }
                        }

                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: modelData.signal + "%"
                                color: Singletons.Theme.darkBase
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false

                        onClicked: {
                            if (!networkList.enabled)
                                return

                            wifiMenuContent.selectedSsid = modelData.ssid
                            wifiMenuContent.selectedSecurity = modelData.security

                            if (modelData.inUse) {
                                return
                            }

                            var needsPassword = Managers.NetworkManager.requiresPasswordFor(
                                modelData.ssid,
                                modelData.security
                            )

                            if (needsPassword) {
                                passwordWindow.show()
                                passwordWindow.requestActivate()
                            } else {
                                Managers.NetworkManager.connectTo(modelData.ssid, "")
                            }
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: networkList.count === 0
                    text: Managers.NetworkManager.enabled
                          ? "No networks found"
                          : "WiFi is disabled"
                    opacity: 0.6
                    color: Singletons.Theme.darkBase
                    font.pixelSize: 12
                }
            }
        }
    }

    Window {
        id: passwordWindow
        width: 320
        height: 200
        color: "transparent"
        title: "Network Password"
        flags: Qt.Tool | Qt.Dialog | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        modality: Qt.ApplicationModal
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Singletons.Theme.lightBackground
            border.color: Singletons.Theme.darkBase
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "Enter password for " + wifiMenuContent.selectedSsid
                    color: Singletons.Theme.darkBase
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: passwordInput
                        Layout.fillWidth: true
                        echoMode: showPasswordCheckbox.checked ? TextInput.Normal : TextInput.Password
                        placeholderText: "Password"
                        color: Singletons.Theme.darkBase
                        placeholderTextColor: Singletons.Theme.mediumGray
                        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                        selectByMouse: true
                        onAccepted: wifiMenuContent.connectWithPassword()

                        background: Rectangle {
                            radius: 6
                            color: Singletons.Theme.accentSoft
                            border.color: Singletons.Theme.darkBase
                            border.width: 1
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    CheckBox {
                        id: showPasswordCheckbox
                        checked: false

                        indicator: Rectangle {
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 3
                            border.color: Singletons.Theme.darkBase
                            border.width: 1.5
                            color: showPasswordCheckbox.checked
                                   ? Singletons.Theme.accentSoftYellow
                                   : Singletons.Theme.accentSoft

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: Singletons.Theme.darkBase
                                font.pixelSize: 12
                                font.bold: true
                                visible: showPasswordCheckbox.checked
                            }
                        }

                        contentItem: Text {
                            text: "Show password"
                            color: Singletons.Theme.darkBase
                            font.pixelSize: 11
                            leftPadding: showPasswordCheckbox.indicator.width + 6
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "Cancel"
                        Layout.fillWidth: true
                        onClicked: wifiMenuContent.closePasswordWindow()

                        background: Rectangle {
                            radius: 6
                            color: Singletons.Theme.accentSoft
                            border.color: Singletons.Theme.darkBase
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Singletons.Theme.darkBase
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Connect"
                        Layout.fillWidth: true
                        enabled: passwordInput.text.length > 0
                        onClicked: wifiMenuContent.connectWithPassword()

                        background: Rectangle {
                            radius: 6
                            color: parent.enabled
                                   ? Singletons.Theme.accentSoftYellow
                                   : Singletons.Theme.accentSoft
                            border.color: Singletons.Theme.darkBase
                            border.width: 1
                            opacity: parent.enabled ? 1 : 0.5
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Singletons.Theme.darkBase
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                x = (Screen.width - width) / 2
                y = (Screen.height - height) / 2
                passwordInput.text = ""
                showPasswordCheckbox.checked = false
                Qt.callLater(function() {
                    passwordInput.forceActiveFocus()
                })
            }
        }
    }

    function closePasswordWindow() {
        passwordWindow.visible = false
    }

    function connectWithPassword() {
        if (!wifiMenuContent.selectedSsid || wifiMenuContent.selectedSsid === "")
            return

        var pwd = passwordInput.text.trim()
        if (pwd.length === 0)
            return

        closePasswordWindow()
        Managers.NetworkManager.connectTo(
            wifiMenuContent.selectedSsid,
            pwd
        )
    }
}
