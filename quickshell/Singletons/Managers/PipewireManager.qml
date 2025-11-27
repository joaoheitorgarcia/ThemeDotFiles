pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell
import "../../Singletons" as Singletons


//TODO Sinks not refreshing on change ( see jbl go 2 in bluetooth)
QtObject {
    id: pipewire

    property real volume: 0.5
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

    function setVolume(v) {
        const pct = Math.round(Math.max(0, Math.min(100, v * 100)));
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", pct + "%"]);
        pipewire.volume = v;
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
        });
    }

    function setInput(nameOrId) {
        Quickshell.execDetached(["pactl", "set-default-source", String(nameOrId)]);
        Qt.callLater(refreshInputs);
    }

    function refresh() {
        refreshVolume();
        refreshOutputs();
        refreshInputs();
    }

    Component.onCompleted: refresh()
}
