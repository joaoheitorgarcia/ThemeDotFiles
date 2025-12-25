pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell
import "../../Singletons" as Singletons

QtObject {
    id: pipewire

    property real volume: 0.5
    property real inputVolume: 0.5
    property var sinkInputs: []
    property var outputs: []
    property var inputs: []
    property string defaultOutput: ""
    property string defaultInput: ""

    function refreshVolume() {
        Singletons.CommandRunner.run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"], function(text) {
            const m = text.match(/(\d+)%/);
            if (m) {
                pipewire.volume = parseInt(m[1]) / 100;
            }
        });
    }

    function refreshInputVolume() {
        Singletons.CommandRunner.run(["pactl", "get-source-volume", "@DEFAULT_SOURCE@"], function(text) {
            const m = text.match(/(\d+)%/);
            if (m) {
                pipewire.inputVolume = parseInt(m[1]) / 100;
            }
        });
    }

    function setVolume(v) {
        const pct = Math.round(Math.max(0, Math.min(100, v * 100)));
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", pct + "%"]);
        pipewire.volume = v;
    }

    function setInputVolume(v) {
        const pct = Math.round(Math.max(0, Math.min(100, v * 100)));
        Quickshell.execDetached(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", pct + "%"]);
        pipewire.inputVolume = v;
    }

    function setAppVolume(id, v, updateModel) {
        const pct = Math.round(Math.max(0, Math.min(100, v * 100)));
        Quickshell.execDetached(["pactl", "set-sink-input-volume", String(id), pct + "%"]);
        Quickshell.execDetached(["pactl", "set-sink-input-mute", String(id), "0"]);

        if (updateModel === false) {
            return;
        }

        pipewire.sinkInputs = pipewire.sinkInputs.map(function(app) {
            if (String(app.id) === String(id)) {
                return {
                    id: app.id ?? id,
                    name: app.name || "Unknown",
                    volume: pct / 100,
                    muted: false
                };
            }

            return app;
        });
    }

    function setAppMute(id, muted) {
        Quickshell.execDetached(["pactl", "set-sink-input-mute", String(id), muted ? "1" : "0"]);

        pipewire.sinkInputs = pipewire.sinkInputs.map(function(app) {
            if (String(app.id) === String(id)) {
                return {
                    id: app.id ?? id,
                    name: app.name || "Unknown",
                    volume: app.volume ?? 0,
                    muted: !!muted
                };
            }
            return app;
        });
    }

    function refreshOutputs() {
        Singletons.CommandRunner.run(["pactl", "-f", "json", "list", "sinks"], function(text) {
            if (!text || !text.trim()) {
                console.warn("PipewireManager: empty response from pactl list sinks");
                return;
            }

            let arr;
            try {
                arr = JSON.parse(text);
            } catch(e) {
                console.error("PipewireManager: error parsing sinks JSON:", e);
                return;
            }

            if (!Array.isArray(arr)) {
                console.error("PipewireManager: sinks response is not an array");
                return;
            }

            pipewire.outputs = arr.map(function(s) {
                return {
                    id: s.index ?? "",
                    name: s.description || s.name || "Unknown",
                    sinkName: s.name || "",
                    default: false
                };
            });

            pipewire.refreshDefaultOutput();
        });
    }

    function refreshDefaultOutput() {
        Singletons.CommandRunner.run(["pactl", "get-default-sink"], function(text) {
            const name = text.trim();
            pipewire.defaultOutput = name;

            pipewire.outputs = pipewire.outputs.map(function(o) {
                return {
                    id: o.id || "",
                    name: o.name || "Unknown",
                    sinkName: o.sinkName || "",
                    default: o.sinkName === name
                };
            });
        });
    }

    function setOutput(nameOrId) {
        Quickshell.execDetached(["pactl", "set-default-sink", String(nameOrId)]);
        Qt.callLater(refreshOutputs);
    }

    function refreshInputs() {
        Singletons.CommandRunner.run(["pactl", "-f", "json", "list", "sources"], function(text) {
            if (!text || !text.trim()) {
                console.warn("PipewireManager: empty response from pactl list sources");
                return;
            }

            let arr;
            try {
                arr = JSON.parse(text);
            } catch(e) {
                console.error("PipewireManager: error parsing sources JSON:", e);
                return;
            }

            if (!Array.isArray(arr)) {
                console.error("PipewireManager: sources response is not an array");
                return;
            }

            pipewire.inputs = arr.map(function(s) {
                return {
                    id: s.index ?? "",
                    name: s.description || s.name || "Unknown",
                    sourceName: s.name || "",
                    default: false
                };
            });

            pipewire.refreshDefaultInput();
        });
    }

    function refreshDefaultInput() {
        Singletons.CommandRunner.run(["pactl", "get-default-source"], function(text) {
            const name = text.trim();
            pipewire.defaultInput = name;

            pipewire.inputs = pipewire.inputs.map(function(o) {
                return {
                    id: o.id || "",
                    name: o.name || "Unknown",
                    sourceName: o.sourceName || "",
                    default: o.sourceName === name
                };
            });

            pipewire.refreshInputVolume();
        });
    }

    function refreshSinkInputs() {
        Singletons.CommandRunner.run(["pactl", "-f", "json", "list", "sink-inputs"], function(text) {
            if (!text || !text.trim()) {
                console.warn("PipewireManager: empty response from pactl list sink-inputs");
                pipewire.sinkInputs = [];
                return;
            }

            let arr;
            try {
                arr = JSON.parse(text);
            } catch(e) {
                console.error("PipewireManager: error parsing sink inputs JSON:", e);
                return;
            }

            if (!Array.isArray(arr)) {
                console.error("PipewireManager: sink inputs response is not an array");
                return;
            }

            pipewire.sinkInputs = arr.map(function(input) {
                const vol = parseVolumePercent(input.volume);
                const props = input.properties || {};
                const name = props["application.name"]
                    || props["media.name"]
                    || input.name
                    || "Unknown";

                return {
                    id: input.index ?? "",
                    name: name,
                    volume: vol,
                    muted: !!input.mute
                };
            });
        });
    }

    function parseVolumePercent(volumeObj) {
        if (!volumeObj || typeof volumeObj !== "object") {
            return 0;
        }

        const values = Object.values(volumeObj)
            .map(function(entry) {
                if (!entry || typeof entry !== "object" || entry.value_percent === undefined) {
                    return null;
                }

                const pct = parseInt(String(entry.value_percent).replace("%", ""));
                return isNaN(pct) ? null : pct;
            })
            .filter(function(v) { return v !== null; });

        if (!values.length) {
            return 0;
        }

        const avg = values.reduce(function(sum, v) { return sum + v; }, 0) / values.length;
        return Math.max(0, Math.min(1, avg / 100));
    }

    function setInput(nameOrId) {
        Quickshell.execDetached(["pactl", "set-default-source", String(nameOrId)]);
        Qt.callLater(refreshInputs);
        Qt.callLater(refreshInputVolume);
    }

    function refresh() {
        refreshVolume();
        refreshInputVolume();
        refreshOutputs();
        refreshInputs();
        refreshSinkInputs();
    }

    Component.onCompleted: refresh()
}
