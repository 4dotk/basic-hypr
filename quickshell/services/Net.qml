// ---------------------------------------------------------
// NET  — NetworkManager state for the quick pill.
//   wired / wifi       the first ethernet and wifi device (null if none),
//                      from Quickshell.Networking
//   wifiOn             the Wi-Fi radio (writable through setWifi)
//   networks           wifi networks from nmcli, one per SSID (strongest),
//                      connected first, then signal level, then name. Plain
//                      objects: ssid, level (icon name), security, active,
//                      known, uuid. Kept for the whole session like Caelestia /
//                      end-4 do: NetworkManager's cached scan list (`nmcli d w`)
//                      is read at start and on every `nmcli monitor` event, so
//                      the dropdown never opens empty. (Quickshell.Networking
//                      only lists networks while its scanner runs and drops them
//                      when it stops.) Raw signal isn't stored, so small changes
//                      don't rebuild rows or reorder the list.
//   scanning           true while the network dropdown is open: a fresh scan
//                      on open, then the cached list every 5 s
//   connect(n, psk) / disconnect() / connecting / connectError
//   hotspot*           a Wi-Fi hotspot through NetworkManager's profile named
//                      "Hotspot" (setHotspot). First use creates it with
//                      `nmcli device wifi hotspot` (SSID `hotspotSsid`, the
//                      password typed in the dropdown, autoconnect off). It runs on the
//                      same card as Wi-Fi, so it disconnects Wi-Fi while on;
//                      other devices get internet only over the wired link.
// (Named Net, not Network, so it doesn't hide the Quickshell.Networking type.)
// Enterprise (802.1x) networks can't be set up here; saved ones still connect.
// SSIDs and passwords go to nmcli as separate arguments, never into a shell
// string (a password is visible in the process list while nmcli runs).
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs

Singleton {
    id: root

    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifi:  Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool wiredUp: wired?.connected ?? false
    readonly property string ifname: wifi?.name ?? ""

    property var networks: []
    readonly property var active: networks.find(n => n.active) ?? null
    property bool scanning: false
    // opening the dropdown: a fresh scan and a hotspot check (after that,
    // `nmcli monitor` events keep both current)
    onScanningChanged: if (scanning) { rescan(); refreshHotspot(); }

    // the pill's icon: plug when wired, wifi strength when on wifi, else empty fan / off
    readonly property string icon: wiredUp ? "wired"
        : active ? active.level
        : wifiOn ? "wifi-none"
        : "wifi-off"
    readonly property bool online: wiredUp || active !== null

    function setWifi(on) { Networking.wifiEnabled = on; }

    // ---- the list ----
    // nmcli -g escapes ':' and '\' in values: split on unescaped colons
    function fields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue; }
            if (c === ":") { out.push(cur); cur = ""; continue; }
            cur += c;
        }
        out.push(cur);
        return out;
    }
    function refresh() { if (!listProc.running) listProc.running = true; }
    function rescan() { if (wifiOn && !rescanProc.running) rescanProc.running = true; }

    property var known: ({})               // ssid -> uuid of its saved profile

    function rebuild(text) {
        const best = {};
        for (const line of text.split("\n")) {
            if (line === "") continue;
            const f = fields(line);
            if (f.length < 4 || f[3] === "") continue;           // hidden networks have no SSID
            const n = { active: f[0] === "yes", signal: parseInt(f[1]) || 0, security: f[2], ssid: f[3] };
            const b = best[n.ssid];
            if (!b || (n.active && !b.active) || (n.active === b.active && n.signal > b.signal)) best[n.ssid] = n;
        }
        const list = Object.values(best).map(n => ({
            ssid: n.ssid,
            level: Theme.wifiIcon(n.signal / 100),
            rank: Math.min(3, Math.floor(n.signal / 25)),
            security: n.security,
            active: n.active,
            known: root.known[n.ssid] !== undefined,
            uuid: root.known[n.ssid] ?? ""
        }));
        list.sort((a, b) => (b.active - a.active) || (b.rank - a.rank) || a.ssid.localeCompare(b.ssid));
        networks = list;
    }

    Process {
        id: listProc
        // saved profiles first (uuid, then its SSID), a separator, then the scan list
        command: ["sh", "-c",
            "nmcli -g UUID,TYPE connection show | while IFS=: read -r u t; do "
          + "[ \"$t\" = 802-11-wireless ] && printf '%s\\t' \"$u\" && nmcli -g 802-11-wireless.ssid connection show \"$u\"; done; "
          + "echo '--'; nmcli -g ACTIVE,SIGNAL,SECURITY,SSID device wifi list --rescan no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("\n--\n");
                const k = {};
                for (const line of (parts[0] ?? "").split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab > 0) k[root.fields(line.slice(tab + 1))[0]] = line.slice(0, tab);
                }
                root.known = k;
                root.rebuild(parts.length > 1 ? parts[1] : "");
            }
        }
    }
    // a real scan (takes a few seconds), then re-read the list
    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: rescanDone.restart()
    }
    Timer { id: rescanDone; interval: 2500; onTriggered: root.refresh() }
    // while the dropdown is open, follow NetworkManager's own background scans
    Timer { interval: 5000; repeat: true; running: root.scanning && root.wifiOn; onTriggered: root.refresh() }
    // connection changes (connected, disconnected, radio on/off, profiles) -> re-read
    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: settle.restart() }
        onExited: restartMonitor.start()
    }
    Timer { id: restartMonitor; interval: 2000; onTriggered: monitor.running = true }
    Timer { id: settle; interval: 300; onTriggered: { root.refresh(); root.refreshHotspot(); } }
    onWifiOnChanged: refresh()

    // ---- connect / disconnect ----
    property string connecting: ""             // SSID being connected
    property string connectError: ""           // for the SSID in `errorFor`
    property string errorFor: ""
    signal needPassword(string ssid)           // a secured network said no: ask (again)

    function needsPassword(n) { return /WPA|SAE/.test(n.security) && !/802\.1X/.test(n.security); }
    function isOpen(n)        { return n.security === "" || /OWE/.test(n.security); }
    function unsupported(n)   { return !n.known && !isOpen(n) && !needsPassword(n); }

    function connect(n, psk) {
        if (connectProc.running) return;
        connecting = n.ssid;
        errorFor = "";
        connectError = "";
        connectProc.target = n.ssid;
        connectProc.command = n.known && !psk ? ["nmcli", "connection", "up", "uuid", n.uuid]
            : psk ? ["nmcli", "device", "wifi", "connect", n.ssid, "password", psk].concat(ifname ? ["ifname", ifname] : [])
            : ["nmcli", "device", "wifi", "connect", n.ssid].concat(ifname ? ["ifname", ifname] : []);
        connectProc.running = true;
    }
    function disconnect() {
        if (!ifname) return;
        discProc.command = ["sh", "-c",
            "c=$(nmcli -g GENERAL.CONNECTION device show \"$1\") && [ -n \"$c\" ] && nmcli connection down id \"$c\"",
            "sh", ifname];
        discProc.running = true;
    }
    Process {
        id: connectProc
        property string target: ""
        stderr: StdioCollector { id: connectErr }
        onExited: code => {
            root.connecting = "";
            if (code !== 0) {
                const e = connectErr.text;
                const secrets = /[Ss]ecrets were required|psk|password/.test(e);
                root.errorFor = target;
                root.connectError = secrets ? "Wrong password" : "Couldn't connect";
                if (secrets) root.needPassword(target);
            }
            root.refresh();
        }
    }
    Process { id: discProc; onExited: root.refresh() }

    Component.onCompleted: { refresh(); refreshHotspot(); }

    // ---- hotspot ----
    readonly property string hotspotSsid: "Y5"
    property bool hotspotOn: false
    property bool hotspotSaved: false       // the "Hotspot" profile exists (no password needed)
    property bool hotspotBusy: false
    property string hotspotName: ""
    property string hotspotError: ""

    function refreshHotspot() { if (!hsState.running) hsState.running = true; }
    // password: only for the first start (creates the profile); 8–63 characters
    function setHotspot(on, password) {
        if (hsToggle.running) return;
        hotspotError = "";
        hotspotBusy = true;
        hsToggle.command = !on ? ["nmcli", "connection", "down", "Hotspot"]
            : hotspotSaved ? ["nmcli", "connection", "up", "Hotspot"]
            : ["sh", "-c",
               "nmcli device wifi hotspot con-name Hotspot ssid \"$1\" password \"$2\" "
             + "&& nmcli connection modify Hotspot connection.autoconnect no",
               "sh", hotspotSsid, password ?? ""];
        hsToggle.running = true;
    }

    // exit 2: no profile · 1: saved, off · 0: on, then its name (the password is never read)
    Process {
        id: hsState
        command: ["sh", "-c",
            "nmcli -t -f NAME connection show | grep -qx Hotspot || exit 2; "
          + "nmcli -t -f NAME connection show --active | grep -qx Hotspot || exit 1; "
          + "nmcli -g 802-11-wireless.ssid connection show Hotspot"]
        stdout: StdioCollector {
            onStreamFinished: root.hotspotName = this.text.trim()
        }
        onExited: code => { root.hotspotOn = code === 0; root.hotspotSaved = code !== 2; }
    }
    Process {
        id: hsToggle
        stderr: StdioCollector { id: hsErr }
        onExited: code => {
            root.hotspotBusy = false;
            if (code !== 0) root.hotspotError = hsErr.text.trim().split("\n").pop() || "Couldn't start the hotspot";
            root.refreshHotspot();
        }
    }
}
