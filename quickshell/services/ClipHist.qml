// ---------------------------------------------------------
// CLIPHIST  — clipboard history through cliphist (the quick pill's clipboard).
// Recording is done by hypr/dots/autostart.lua:
//   wl-paste --type text  --watch cliphist store
//   wl-paste --type image --watch cliphist store
//   entries      recent history, newest first (at most `limit`)
//   starred      starred entries, newest star first
//   present      cliphist is installed
//   refresh()    re-read both (the dropdown calls it when it opens)
//   copy(e)      put an entry back on the clipboard (it moves to the top)
//   remove(e)    delete one (not if it is starred; the dropdown's − button)
//   wipe()       delete every history entry that is not starred
//   star(e) · unstar(e)   (e from either list; the dropdown's right click)
//
// An entry: { kind: "txt"|"img", hash, text, name, path, w, h, line }  (isStarred(e) for its star)
//   hash   sha1 of the content: what ties a history entry to its star
//          (cliphist gives a re-copied entry a new id, so ids can't be used)
//   text   one-line preview · name: image caption · path: image file
//   line   the cliphist line ("id<TAB>preview"; empty for starred entries)
//
// Stars are copies of the content in ~/.local/share/basic-hypr/clip-stars/
//   <hash>.txt  ·  <hash>_<w>x<h>_<name>   (images)
// so they outlive Clear, cliphist's own pruning and reboots.
// Image thumbnails are decoded to $XDG_RUNTIME_DIR/basic-hypr-clip/<hash>.<ext>.
// Image captions: the screenshot's file name when the image is a shot from
// scripts/screenshot.sh (matched by hash; shots.idx there indexes the
// Screenshots folder, only new files get hashed), else Image_<first seen>.<ext>.
// Values go to the scripts as arguments / stdin, never into a shell string.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property var starred: []
    property bool present: true
    readonly property int limit: 50

    readonly property string cacheDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/basic-hypr-clip"
    readonly property string starDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/basic-hypr/clip-stars"

    // hashes of the starred entries (history rows read their star from this)
    readonly property var starHashes: {
        const s = {};
        for (const e of starred) s[e.hash] = true;
        return s;
    }
    function isStarred(e) { return starHashes[e.hash] === true; }

    function refresh() {
        if (!list.running) list.running = true;
        if (!stars.running) stars.running = true;
    }

    function copy(e) {
        if (e.line !== "")
            run(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", e.line]);
        else if (e.kind === "img")
            run(["sh", "-c", "wl-copy --type \"image/${2##*.}\" < \"$1\"", "sh", e.path, e.name]);
        else
            run(["sh", "-c", "wl-copy < \"$1\"", "sh", e.path]);
    }
    function remove(e) {
        if (isStarred(e) || e.line === "") return;
        run(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", e.line]);
    }
    function wipe() {
        // keep the starred ones: decode each entry, delete those whose hash has no star
        run(["bash", "-c", [
            "stars=$(ls \"$1\" 2>/dev/null | cut -c1-40)",
            "[ -n \"$stars\" ] || exec cliphist wipe",
            "all=$(cliphist list)",
            "del=$(while IFS= read -r l; do",
            "  [ -n \"$l\" ] || continue",
            "  h=$(printf '%s' \"$l\" | cliphist decode | sha1sum | cut -c1-40)",
            "  grep -qxF \"$h\" <<<\"$stars\" || printf '%s\\n' \"$l\"",
            "done <<<\"$all\")",
            "[ -z \"$del\" ] || printf '%s\\n' \"$del\" | cliphist delete"
        ].join("\n"), "bash", starDir]);
    }
    function star(e) {
        if (isStarred(e)) return;
        if (e.kind === "img")
            run(["sh", "-c", "mkdir -p \"$1\" && cp \"$2\" \"$1/$3_$4x$5_$6\"",
                 "sh", starDir, e.path, e.hash, String(e.w), String(e.h), e.name]);
        else if (e.line !== "")
            run(["sh", "-c", "mkdir -p \"$1\" && printf '%s' \"$3\" | cliphist decode > \"$1/$2.txt\"",
                 "sh", starDir, e.hash, e.line]);
    }
    function unstar(e) {
        run(["sh", "-c", "rm -f -- \"$1/$2.txt\" \"$1/$2\"_*", "sh", starDir, e.hash]);
    }

    function run(cmd) {
        const p = act.createObject(root, { command: cmd });
        p.running = true;
    }
    Component {
        id: act
        Process {
            onExited: { root.refresh(); destroy(); }
        }
    }

    // both lists print: kind<TAB>hash<TAB>name<TAB>path<TAB>w<TAB>h<TAB>rest
    // (rest = the cliphist line for history, the text preview for stars)
    function parse(out, history) {
        return out.split("\n").filter(l => l !== "").map(l => {
            const f = l.split("\t");
            const rest = f.slice(6).join("\t");
            const kind = f[0];
            const text = kind === "img" ? f[2]
                       : (history ? rest.slice(rest.indexOf("\t") + 1) : rest).replace(/\s+/g, " ").trim();
            return { kind: kind, hash: f[1], name: f[2], path: f[3], w: Number(f[4]) || 0, h: Number(f[5]) || 0,
                     line: history ? rest : "", text: text };
        });
    }

    Process {
        id: list
        command: ["bash", "-c", [
            "command -v cliphist >/dev/null || exit 127",
            "cache=$1 n=$2",
            "shots=${SCREENSHOT_DIR:-$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots}",
            "mkdir -p \"$cache\"; idx=$cache/shots.idx; stamp=$cache/shots.stamp",
            // index screenshots saved since the last run: hash<TAB>file name
            "if [ -d \"$shots\" ]; then",
            "  new=(); [ -f \"$stamp\" ] && new=(-newer \"$stamp\")",
            "  touch \"$stamp.next\"",
            "  find \"$shots\" -maxdepth 1 -type f \"${new[@]}\" -print0 | while IFS= read -r -d '' f; do",
            "    printf '%s\\t%s\\n' \"$(sha1sum < \"$f\" | cut -c1-40)\" \"${f##*/}\"",
            "  done >> \"$idx\"",
            "  mv \"$stamp.next\" \"$stamp\"",
            "fi",
            "all=$(cliphist list | head -n \"$n\")",
            "while IFS= read -r line; do",
            "  [ -n \"$line\" ] || continue",
            "  prev=${line#*$'\\t'}",
            "  if [[ $prev =~ ^\\[\\[\\ binary\\ data\\ .*\\ ([a-z0-9]+)\\ ([0-9]+)x([0-9]+)\\ \\]\\]$ ]]; then",
            "    ext=${BASH_REMATCH[1]} w=${BASH_REMATCH[2]} h=${BASH_REMATCH[3]}",
            "    tmp=$cache/decode.tmp",
            "    printf '%s' \"$line\" | cliphist decode > \"$tmp\"",
            "    hash=$(sha1sum < \"$tmp\" | cut -c1-40)",
            "    thumb=$cache/$hash.$ext",
            "    if [ -f \"$thumb\" ]; then rm -f \"$tmp\"; else mv \"$tmp\" \"$thumb\"; fi",
            "    name=$(awk -F'\\t' -v h=\"$hash\" '$1==h { print $2; exit }' \"$idx\" 2>/dev/null)",
            "    [ -n \"$name\" ] || name=Image_$(date -r \"$thumb\" +%Y%m%d_%H%M%S).$ext",
            "    printf 'img\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$hash\" \"$name\" \"$thumb\" \"$w\" \"$h\" \"$line\"",
            "  else",
            "    hash=$(printf '%s' \"$line\" | cliphist decode | sha1sum | cut -c1-40)",
            "    printf 'txt\\t%s\\t\\t\\t\\t\\t%s\\n' \"$hash\" \"$line\"",
            "  fi",
            "done <<<\"$all\""
        ].join("\n"), "bash", root.cacheDir, String(root.limit)]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(this.text, true)
        }
        onExited: code => { root.present = code !== 127; }
    }

    Process {
        id: stars
        command: ["bash", "-c", [
            "dir=$1; [ -d \"$dir\" ] || exit 0",
            "ls -t \"$dir\" | while IFS= read -r f; do",
            "  hash=${f:0:40}",
            "  case $f in",
            "    *.txt) printf 'txt\\t%s\\t\\t%s\\t\\t\\t%s\\n' \"$hash\" \"$dir/$f\" \"$(head -c 300 \"$dir/$f\" | tr '\\n\\t\\r' '   ')\" ;;",
            "    *) rest=${f:41}; dims=${rest%%_*}",
            "       printf 'img\\t%s\\t%s\\t%s\\t%s\\t%s\\t\\n' \"$hash\" \"${rest#*_}\" \"$dir/$f\" \"${dims%x*}\" \"${dims#*x}\" ;;",
            "  esac",
            "done"
        ].join("\n"), "bash", root.starDir]
        stdout: StdioCollector {
            onStreamFinished: root.starred = root.parse(this.text, false)
        }
    }
}
