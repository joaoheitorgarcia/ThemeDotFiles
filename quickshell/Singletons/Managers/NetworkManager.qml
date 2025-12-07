pragma Singleton
import QtQuick
import Quickshell.Io
import ".." as Singletons

/*
    TODO
    Refactor when this is merged
    https://github.com/quickshell-mirror/quickshell/pull/96

    In the meantime just use nmtui

    Error its lockin on wrong password
    also doesnt remeber previously connected passwords
*/

QtObject {
    id: wifi

    readonly property string _nmService: "org.freedesktop.NetworkManager"
    readonly property string _nmPath: "/org/freedesktop/NetworkManager"

    property bool enabled: true
    property bool hardwareEnabled: true
    property bool connected: false
    property bool wifiConnected: false
    property bool wiredConnected: false
    property bool connecting: false
    property bool awaitingAuth: false
    property string wiredConnectionName: ""
    property string activeConnectionName: ""
    property string activeConnectionType: "none"
    property string ssid: ""
    property string pendingSsid: ""
    property int strength: 0
    property var networks: []
    property var knownSsids: ({})
    property var savedConnections: ({})

    property string wifiDevicePath: ""
    property string wifiInterface: ""
    property string activeWifiConnectionPath: ""
    property var deviceCache: ({})

    signal passwordNeeded(string ssid)

    property Process dbusMonitor: Process {
        running: true
        command: [
            "dbus-monitor",
            "--system",
            "type='signal',sender='org.freedesktop.NetworkManager'"
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("org.freedesktop.NetworkManager")) {
                    Qt.callLater(wifi.refresh)
                }
            }
        }
    }

    function refresh() {
        _refreshRadio()
        _refreshDeviceCache(function() {
            _refreshActiveConnections()
            _refreshWifiNetworks()
        })
        _refreshSavedWifiConnections()
    }

    function setWifiEnabled(on) {
        connecting = true
        _runBusctl(
            [
                "set-property",
                _nmService,
                _nmPath,
                _nmService,
                "WirelessEnabled",
                "b",
                on ? "true" : "false"
            ],
            function() {
                connecting = false
                refresh()
            }
        )
    }

    function connectTo(ssidToConnect, password) {
        if (!ssidToConnect || ssidToConnect === "")
            return

        connecting = true
        awaitingAuth = true
        pendingSsid = ssidToConnect
        var targetAp = _findNetworkBySsid(ssidToConnect)
        var saved = savedConnections[ssidToConnect]
        var devicePath = wifiDevicePath || "/"
        var apPath = targetAp && targetAp.path ? targetAp.path : "/"

        if (saved && saved.path) {
            if (!password || password === "") {
                if (saved.hasSecrets === false) {
                    connecting = false
                    awaitingAuth = false
                    return
                }

                _activateConnection(saved.path, devicePath, apPath, function(success) {
                    if (!success) {
                        console.log("Failed to activate saved connection for", ssidToConnect)
                    }
                    refresh()
                })
                return
            }

            _updateSavedConnectionPassword(saved, password, function() {
                _activateConnection(saved.path, devicePath, apPath, function(success) {
                    if (!success) {
                        console.log("Failed to activate saved connection for", ssidToConnect)
                    }
                    if (savedConnections[ssidToConnect])
                        savedConnections[ssidToConnect].hasSecrets = true
                    refresh()
                })
            })
            return
        }

        _addAndActivateConnection(ssidToConnect, password, devicePath, apPath, function(ok) {
            if (!ok) {
                console.log("Failed to add/activate connection for", ssidToConnect)
            }
            refresh()
        })
    }

    function hasSavedConnection(ssidToCheck) {
        if (!ssidToCheck || ssidToCheck === "")
            return false
        return knownSsids[ssidToCheck] === true
    }

    function requiresPasswordFor(ssidToCheck, securityLabel) {
        if (!ssidToCheck || ssidToCheck === "")
            return false
        var openNetwork = (!securityLabel || securityLabel === "--" || securityLabel.toLowerCase() === "open")
        if (openNetwork)
            return false
        var saved = savedConnections[ssidToCheck]
        if (!saved)
            return true
        return saved.hasSecrets !== true
    }

    function _updateActiveConnection() {
        if (wiredConnected) {
            connected = true
            activeConnectionType = "wired"
            activeConnectionName = wiredConnectionName || "Ethernet"
            return
        }

        if (wifiConnected) {
            connected = true
            activeConnectionType = "wifi"
            activeConnectionName = ssid
            return
        }

        connected = false
        activeConnectionType = "none"
        activeConnectionName = ""
    }

    function _refreshRadio() {
        _runBusctl(
            ["get-property", _nmService, _nmPath, _nmService, "WirelessEnabled"],
            function(out) {
                enabled = !!(out && out.data)
            }
        )

        _runBusctl(
            ["get-property", _nmService, _nmPath, _nmService, "WirelessHardwareEnabled"],
            function(out) {
                hardwareEnabled = !!(out && out.data)
            }
        )
    }

    function _refreshDeviceCache(onDone) {
        _runBusctl(
            ["call", _nmService, _nmPath, _nmService, "GetDevices"],
            function(result) {
                var paths = _unwrapList(result ? result.data : [])
                var cache = {}

                if (!paths || paths.length === 0) {
                    deviceCache = cache
                    wifiDevicePath = ""
                    wifiInterface = ""
                    onDone && onDone()
                    return
                }

                var pending = paths.length
                paths.forEach(function(path) {
                    _runBusctl(
                        [
                            "call",
                            _nmService,
                            path,
                            "org.freedesktop.DBus.Properties",
                            "GetAll",
                            "s",
                            "org.freedesktop.NetworkManager.Device"
                        ],
                        function(res) {
                            var values = _extractValues(res)
                            cache[path] = {
                                path: path,
                                interface: values.Interface || "",
                                deviceType: values.DeviceType || 0,
                                state: values.State || 0,
                                stateReason: values.StateReason || [],
                                activeConnection: values.ActiveConnection || ""
                            }

                            if (cache[path].deviceType === 2) {
                                wifiDevicePath = path
                                wifiInterface = cache[path].interface
                            }

                            pending -= 1
                            if (pending === 0) {
                                deviceCache = cache
                                onDone && onDone()
                                _handleAuthFailure()
                            }
                        }
                    )
                })
            }
        )
    }

    function _refreshActiveConnections() {
        _runBusctl(
            ["get-property", _nmService, _nmPath, _nmService, "ActiveConnections"],
            function(res) {
                var paths = _unwrapList(res ? res.data : [])

                if (!paths || paths.length === 0) {
                    wifiConnected = false
                    wiredConnected = false
                    ssid = ""
                    strength = 0
                    activeWifiConnectionPath = ""
                    _updateActiveConnection()
                    return
                }

                var wifiInfo = null
                var wiredInfo = null
                var pending = paths.length

                paths.forEach(function(path) {
                    _runBusctl(
                        [
                            "call",
                            _nmService,
                            path,
                            "org.freedesktop.DBus.Properties",
                            "GetAll",
                            "s",
                            "org.freedesktop.NetworkManager.Connection.Active"
                        ],
                        function(details) {
                            var vals = _extractValues(details)
                            var info = {
                                path: path,
                                id: vals.Id || "",
                                type: vals.Type || "",
                                state: vals.State || 0,
                                devices: _unwrapList(vals.Devices || [])
                            }

                            var hasEthernetDevice = false
                            var hasWifiDevice = false
                            for (var i = 0; i < info.devices.length; ++i) {
                                var dev = deviceCache[info.devices[i]]
                                if (dev && dev.deviceType === 1)
                                    hasEthernetDevice = true
                                if (dev && dev.deviceType === 2)
                                    hasWifiDevice = true
                            }

                            if (info.type.indexOf("802-11") !== -1 || hasWifiDevice) {
                                if (!wifiInfo || info.state > wifiInfo.state) {
                                    wifiInfo = info
                                }
                            } else if (
                                (info.type.indexOf("802-3-ethernet") !== -1 || hasEthernetDevice)
                                && info.type !== "loopback"
                            ) {
                                if (!wiredInfo || info.state > wiredInfo.state) {
                                    wiredInfo = info
                                }
                            }

                            pending -= 1
                            if (pending === 0) {
                                wifiConnected = !!(wifiInfo && _isActiveState(wifiInfo.state))
                                wiredConnected = !!(wiredInfo && _isActiveState(wiredInfo.state))
                                wiredConnectionName = wiredConnected
                                        ? (wiredInfo.id || "Ethernet")
                                        : ""

                                activeWifiConnectionPath = wifiInfo ? wifiInfo.path : ""
                                if (wifiInfo) {
                                    ssid = wifiInfo.id || ""
                                    if (wifiInfo.devices && wifiInfo.devices.length > 0) {
                                        wifiDevicePath = wifiInfo.devices[0]
                                        var cached = deviceCache[wifiDevicePath]
                                        wifiInterface = cached ? cached.interface : wifiInterface
                                    }
                                } else {
                                    ssid = ""
                                }
                                _updateActiveConnection()
                                _handleAuthFailure()
                            }
                        }
                    )
                })
            }
        )
    }

    function _refreshWifiNetworks() {
        if (!wifiDevicePath) {
            _refreshDeviceCache(function() {
                _loadWifiAccessPoints()
                _handleAuthFailure()
            })
            return
        }

        _loadWifiAccessPoints()
        _handleAuthFailure()
    }

    function _loadWifiAccessPoints() {
        if (!wifiDevicePath) {
            networks = []
            strength = 0
            wifiConnected = false
            _updateActiveConnection()
            return
        }

        _runBusctl(
            [
                "call",
                _nmService,
                wifiDevicePath,
                "org.freedesktop.DBus.Properties",
                "GetAll",
                "s",
                "org.freedesktop.NetworkManager.Device.Wireless"
            ],
            function(res) {
                var vals = _extractValues(res)
                var accessPoints = _unwrapList(vals.AccessPoints || [])
                var activeAp = vals.ActiveAccessPoint || ""

                if (!accessPoints || accessPoints.length === 0) {
                    networks = []
                    if (!wifiConnected) {
                        ssid = ""
                        strength = 0
                    }
                    _updateActiveConnection()
                    return
                }

                var list = []
                var pending = accessPoints.length

                accessPoints.forEach(function(apPath) {
                    _runBusctl(
                        [
                            "call",
                            _nmService,
                            apPath,
                            "org.freedesktop.DBus.Properties",
                            "GetAll",
                            "s",
                            "org.freedesktop.NetworkManager.AccessPoint"
                        ],
                        function(apRes) {
                            var apVals = _extractValues(apRes)
                            var ssidStr = _ssidFromBytes(apVals.Ssid)

                            if (ssidStr !== "") {
                                var entry = {
                                    ssid: ssidStr,
                                    signal: apVals.Strength || 0,
                                    security: _describeSecurity(apVals),
                                    inUse: apPath === activeAp,
                                    path: apPath,
                                    lastSeen: apVals.LastSeen || 0
                                }

                                list.push(entry)

                                if (entry.inUse) {
                                    ssid = entry.ssid
                                    strength = entry.signal
                                    wifiConnected = wifiConnected || true
                                }
                            }

                            pending -= 1
                            if (pending === 0) {
                                networks = list
                                if (!wifiConnected) {
                                    strength = 0
                                }
                                _updateActiveConnection()
                            }
                        }
                    )
                })
            }
        )
    }

    function _refreshSavedWifiConnections() {
        _runBusctl(
            [
                "call",
                _nmService,
                _nmPath + "/Settings",
                "org.freedesktop.NetworkManager.Settings",
                "ListConnections"
            ],
            function(res) {
                var paths = _unwrapList(res ? res.data : [])
                var map = {}
                var infoMap = {}

                if (!paths || paths.length === 0) {
                    knownSsids = map
                    savedConnections = infoMap
                    return
                }

                var pending = paths.length

                paths.forEach(function(path) {
                    _getConnectionSettings(path, function(settings) {
                        var connection = settings ? settings["connection"] : null
                        var wifiSection = settings ? settings["802-11-wireless"] : null
                        var type = _typedValue(connection, "type", "")
                        var ssidBytes = _typedValue(wifiSection, "ssid", null)
                        var ssidStr = _ssidFromBytes(ssidBytes)

                        if (ssidStr !== "" && type && type.indexOf("802-11-wireless") === 0) {
                            map[ssidStr] = true
                            var entry = {
                                path: path,
                                id: _typedValue(connection, "id", ssidStr),
                                uuid: _typedValue(connection, "uuid", ""),
                                hasSecrets: false
                            }
                            infoMap[ssidStr] = entry

                            _getConnectionSecrets(path, function(secretMap) {
                                entry.hasSecrets = _connectionHasSecrets(settings, secretMap)
                                pending -= 1
                                if (pending === 0) {
                                    knownSsids = map
                                    savedConnections = infoMap
                                }
                            })
                        } else {
                            pending -= 1
                            if (pending === 0) {
                                knownSsids = map
                                savedConnections = infoMap
                            }
                        }
                    })
                })
            }
        )
    }

    function _handleAuthFailure() {
        if (!awaitingAuth && !connecting)
            return

        if (wifiConnected && pendingSsid !== "" && ssid === pendingSsid) {
            awaitingAuth = false
            pendingSsid = ""
            connecting = false
            return
        }

        var dev = deviceCache[wifiDevicePath]
        if (!dev || !dev.stateReason || dev.stateReason.length < 2)
            return

        var reasonCode = dev.stateReason[1]
        if (!_isAuthFailureReason(reasonCode))
            return

        var targetSsid = pendingSsid
        awaitingAuth = false
        connecting = false
        pendingSsid = ""

        if (targetSsid && savedConnections[targetSsid]) {
            _clearSavedSecret(targetSsid)
        }

        passwordNeeded(targetSsid || "")
    }

    function _activateConnection(connectionPath, devicePath, specificObject, cb) {
        _runBusctl(
            [
                "call",
                _nmService,
                _nmPath,
                _nmService,
                "ActivateConnection",
                "ooo",
                connectionPath || "/",
                devicePath && devicePath !== "" ? devicePath : "/",
                specificObject && specificObject !== "" ? specificObject : "/"
            ],
            function(result) {
                cb && cb(!!result)
            }
        )
    }

    function _addAndActivateConnection(ssidToConnect, password, devicePath, apPath, cb) {
        var settings = []

        var connectionValues = [
            { key: "id", type: "s", value: ssidToConnect },
            { key: "type", type: "s", value: "802-11-wireless" },
            { key: "uuid", type: "s", value: _generateUuid() }
        ]

        if (wifiInterface && wifiInterface !== "") {
            connectionValues.push({ key: "interface-name", type: "s", value: wifiInterface })
        }

        settings.push({ key: "connection", values: connectionValues })

        var wifiValues = [
            { key: "ssid", type: "ay", value: _ssidToBytes(ssidToConnect) },
            { key: "mode", type: "s", value: "infrastructure" }
        ]

        if (password && password !== "") {
            wifiValues.push({ key: "security", type: "s", value: "802-11-wireless-security" })
        }

        settings.push({ key: "802-11-wireless", values: wifiValues })

        if (password && password !== "") {
            settings.push({
                key: "802-11-wireless-security",
                values: [
                    { key: "key-mgmt", type: "s", value: "wpa-psk" },
                    { key: "psk", type: "s", value: password }
                ]
            })
        }

        settings.push({ key: "ipv4", values: [ { key: "method", type: "s", value: "auto" } ] })
        settings.push({ key: "ipv6", values: [ { key: "method", type: "s", value: "auto" } ] })

        var settingsArgs = _encodeSettings(settings)
        var args = [
            "call",
            _nmService,
            _nmPath,
            _nmService,
            "AddAndActivateConnection",
            "a{sa{sv}}oo"
        ].concat(settingsArgs, [
            devicePath && devicePath !== "" ? devicePath : "/",
            apPath && apPath !== "" ? apPath : "/"
        ])

        _runBusctl(args, function(result) {
            cb && cb(!!result)
        })
    }

    function _updateSavedConnectionPassword(saved, password, cb) {
        if (!saved || (!saved.uuid && !saved.id)) {
            cb && cb(false)
            return
        }

        var nameOrUuid = saved.uuid && saved.uuid !== "" ? saved.uuid : saved.id

        Singletons.CommandRunner.run(
            [
                "nmcli",
                "connection",
                "modify",
                nameOrUuid,
                "wifi-sec.key-mgmt",
                "wpa-psk",
                "wifi-sec.psk",
                password
            ],
            function() {
                cb && cb(true)
            }
        )
    }

    function _getConnectionSettings(path, cb) {
        _runBusctl(
            [
                "call",
                _nmService,
                path,
                "org.freedesktop.NetworkManager.Settings.Connection",
                "GetSettings"
            ],
            function(res) {
                var settings = _extractSettings(res)
                cb && cb(settings)
            }
        )
    }

    function _getConnectionSecrets(path, cb) {
        _runBusctl(
            [
                "call",
                _nmService,
                path,
                "org.freedesktop.NetworkManager.Settings.Connection",
                "GetSecrets",
                "a{ss}",
                0
            ],
            function(res) {
                var secrets = _extractSettings(res)
                cb && cb(secrets)
            }
        )
    }

    function _clearSavedSecret(ssidToClear) {
        var saved = savedConnections[ssidToClear]
        if (!saved)
            return

        var nameOrUuid = saved.uuid && saved.uuid !== "" ? saved.uuid : saved.id

        Singletons.CommandRunner.run(
            [
                "nmcli",
                "connection",
                "modify",
                nameOrUuid,
                "wifi-sec.psk",
                ""
            ],
            function() {
                if (savedConnections[ssidToClear])
                    savedConnections[ssidToClear].hasSecrets = false
            }
        )
    }

    function _runBusctl(args, cb) {
        Singletons.CommandRunner.run(
            ["busctl", "--system", "--json=short"].concat(args),
            function(out) {
                var parsed = _parseBusctlJson(out)
                cb && cb(parsed)
            }
        )
    }

    function _parseBusctlJson(out) {
        if (!out || out.trim() === "")
            return null

        var trimmed = out.trim()
        var idx = trimmed.indexOf("{")
        if (idx > 0)
            trimmed = trimmed.slice(idx)

        try {
            return JSON.parse(trimmed)
        } catch (e) {
            console.log("Failed to parse busctl output", out)
            return null
        }
    }

    function _extractValues(container) {
        var result = {}
        if (!container || !container.data || container.data.length === 0)
            return result

        var obj = container.data[0]
        for (var key in obj) {
            result[key] = obj[key].data
        }
        return result
    }

    function _extractSettings(container) {
        if (!container || !container.data || container.data.length === 0)
            return null
        return container.data[0]
    }

    function _unwrapList(data) {
        if (!data)
            return []
        if (Array.isArray(data) && data.length === 1 && Array.isArray(data[0]))
            return data[0]
        if (Array.isArray(data))
            return data
        return []
    }

    function _ssidToBytes(value) {
        var arr = []
        if (!value)
            return arr
        for (var i = 0; i < value.length; ++i) {
            arr.push(value.charCodeAt(i))
        }
        return arr
    }

    function _ssidFromBytes(bytes) {
        if (!bytes || !Array.isArray(bytes) || bytes.length === 0)
            return ""
        var s = ""
        for (var i = 0; i < bytes.length; ++i) {
            s += String.fromCharCode(bytes[i])
        }
        return s
    }

    function _typedValue(section, key, fallback) {
        if (!section || !section[key])
            return fallback
        if (section[key].data === undefined || section[key].data === null)
            return fallback
        return section[key].data
    }

    function _connectionHasSecrets(settings, secrets) {
        var secSettings = settings ? settings["802-11-wireless-security"] : null
        var secSecrets = secrets ? secrets["802-11-wireless-security"] : null

        if (secSecrets && secSecrets.psk && secSecrets.psk.data && secSecrets.psk.data !== "")
            return true

        var flags = secSettings && secSettings["psk-flags"] ? secSettings["psk-flags"].data : null

        // flags 0 → stored; any other/unknown → assume missing/agent-owned
        if (flags === 0)
            return true
        if (flags === null || flags === undefined)
            return !!(secSecrets && secSecrets.psk && secSecrets.psk.data && secSecrets.psk.data !== "")

        return false
    }

    function _describeSecurity(ap) {
        var flags = ap && ap.Flags ? ap.Flags : 0
        var wpa = ap && ap.WpaFlags ? ap.WpaFlags : 0
        var rsn = ap && ap.RsnFlags ? ap.RsnFlags : 0

        if (wpa && rsn)
            return "WPA/WPA2"
        if (rsn)
            return "WPA2"
        if (wpa)
            return "WPA"
        if (flags & 0x1)
            return "WEP"
        return ""
    }

    function _isActiveState(state) {
        return state === 2
    }

    function _isAuthFailureReason(reasonCode) {
        // NM_DEVICE_STATE_REASON_* that imply bad or missing secrets
        var reasons = [6, 7, 8, 9, 23, 24]
        for (var i = 0; i < reasons.length; ++i) {
            if (reasonCode === reasons[i])
                return true
        }
        return false
    }

    function _encodeSettings(settings) {
        var args = []
        args.push(settings.length)

        for (var i = 0; i < settings.length; ++i) {
            var entry = settings[i]
            args.push(entry.key)
            args.push(entry.values.length)

            for (var j = 0; j < entry.values.length; ++j) {
                var item = entry.values[j]
                args.push(item.key)
                args.push(item.type)
                _appendTypedValue(args, item.type, item.value)
            }
        }

        return args
    }

    function _appendTypedValue(args, type, value) {
        if (type === "ay") {
            var arr = value || []
            args.push(arr.length)
            for (var i = 0; i < arr.length; ++i) {
                args.push(arr[i])
            }
            return
        }

        if (type === "b") {
            args.push(value ? 1 : 0)
            return
        }

        args.push(value)
    }

    function _generateUuid() {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
        }
        return (
            s4() + s4() + "-" +
            s4() + "-" +
            s4() + "-" +
            s4() + "-" +
            s4() + s4() + s4()
        )
    }

    function _findNetworkBySsid(targetSsid) {
        for (var i = 0; i < networks.length; ++i) {
            if (networks[i].ssid === targetSsid)
                return networks[i]
        }
        return null
    }

    Component.onCompleted: refresh()
}
