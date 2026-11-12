// ---------------------------------------------------------
// MEDIA  — picks one MPRIS player to show (the playing one, else the first).
// shown stays true for a few seconds after pausing, so pausing from the
// pill doesn't make it collapse under your cursor.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer player: {
        const ps = Mpris.players.values;
        for (let i = 0; i < ps.length; i++)
            if (ps[i].isPlaying) return ps[i];
        return ps.length > 0 ? ps[0] : null;
    }

    readonly property bool playing: player?.isPlaying ?? false
    property bool shown: false

    onPlayingChanged: {
        if (playing) { linger.stop(); shown = true; }
        else linger.restart();
    }
    Timer { id: linger; interval: 6000; onTriggered: root.shown = false }
}
