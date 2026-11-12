# basic-hypr

A Basic hyprland setup: Lua based config, rofi launcher,
kitty terminal, a simple screenshot tool and the Robot cursor theme which is based on Breeze Light.

## Install

```bash
git clone <this repo> anywhere/you/like
cd anywhere/you/like
./install.sh --dry-run   # see what will happen
./install.sh             # do it
./install.sh --kwallet   # optional: KDE Wallet as the password store
```

`install.sh` works out where the repo is, so you can keep it anywhere. It
**symlinks** everything into place, so edits in the repo are live immediately.
Anything already in the way is moved to `<name>.bak.<timestamp>`, never deleted.
Running it again is safe.

| Repo | Linked to |
|---|---|
| `hypr/` | `~/.config/hypr` |
| `rofi/` | `~/.config/rofi` |
| `kitty/` | `~/.config/kitty` |
| `quickshell/` | `~/.config/quickshell` |
| `scripts/screenshot.sh` | `~/.local/scripts/screenshot.sh` |
| `scripts/theme.sh` | `~/.local/scripts/theme.sh` |
| `scripts/logout.sh` | `~/.local/scripts/logout.sh` |
| `cursors/Robot/` | `~/.local/share/icons/Robot` and `~/.icons/Robot` (Plasma looks there) |

## Change these first

1. **Wallpaper** — `hypr/hyprpaper.conf`. Defaults to Hyprland's own
   `/usr/share/hypr/wall0.png`. Use an absolute path or `~/...`
   (relative paths don't work in hyprpaper).
2. **Monitor** — `hypr/dots/monitors.lua`. `scale = 1.2` suits a 1080p laptop;
   use `1` (or what fits) for your screen.
3. **Apps** — `hypr/dots/programs.lua` (terminal, file manager, launcher).

## Packages

Fedora names; `install.sh` warns about anything missing but installs nothing.

| Needed for | Packages |
|---|---|
| Desktop | `hyprland` `hyprpaper` `hyprpolkitagent` `kitty` `rofi` |
| Bar | `quickshell` `brightnessctl` `lm_sensors` |
| Clean logout | `hyprshutdown` (optional — without it apps aren't asked to close first) |
| Media keys | `wireplumber` `brightnessctl` `playerctl` |
| Screenshots | `grim` `slurp` `hyprpicker` `wl-clipboard` `jq` `xdg-user-dirs` |
| Qt/KDE apps looking right | `plasma-integration` `plasma-breeze` (used via `QT_QPA_PLATFORMTHEME=kde`) |
| File manager | `dolphin` |
| Cursor (only to rebuild) | `breeze-cursor-theme` `python3-gobject` `python3-cairo` |

**Optional:** fonts and icons. Without them everything still works — the
system's default sans / monospace font and icon theme are used instead.

- [Hack Nerd Font](https://www.nerdfonts.com/font-downloads) — rofi
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) — kitty
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) (`Papirus-Dark`) — rofi icons

## Themes

Two colour themes for the bar and rofi: **Vague** (default — matches the kitty
Vague colours, very muted) and **Basic** (Hyprland's blues, the bar looks like
an unfocused window).

```bash
~/.local/scripts/theme.sh          # pick from a rofi menu
~/.local/scripts/theme.sh basic    # or switch directly
~/.local/scripts/theme.sh list
```

The bar recolours straight away; rofi uses it from its next launch. The choice
is kept in `~/.local/state/basic-hypr/`, outside the repo. A theme is a file in
`rofi/dots/themes/` plus a palette with the same name in `quickshell/Theme.qml`.

## Passwords, Wi-Fi and the keyring

**Wi-Fi / wired passwords:** let NetworkManager keep them itself (`psk-flags=0`,
`802-1x.password-flags=0`). They live in root-only files under
`/etc/NetworkManager/system-connections/`, connect in any session (even before
login) and need no keyring or tray applet. Networks saved under Plasma often
keep the password in KDE Wallet instead (`flags=1`) — those never autoconnect
here, because nothing in a Hyprland session hands the password to
NetworkManager. To move them out of the wallet (no typing, passwords never
shown): `scripts/wallet-to-nm.py --dry-run`, then without `--dry-run`.
Check with:

```bash
nmcli -f 802-11-wireless-security.psk-flags,802-1x.password-flags connection show "<name>"
```

**Enterprise / university Wi-Fi (802.1x):** also set the server check
(`802-1x.domain-suffix-match` and a CA certificate from your IT department),
otherwise your login is sent to any access point using that network name.

**Other apps' passwords (browsers etc.):** whichever keyring answers first on
D-Bus gets them. `./install.sh --kwallet` (opt-in) makes that KDE Wallet
instead of gnome-keyring; without the flag nothing changes.

## Keys (SUPER = Windows key)

| Key | Does |
|---|---|
| `SUPER + Q` / `E` / `R` | terminal / file manager / launcher |
| `SUPER + C` | close window |
| `SUPER + M` | log out cleanly (closes apps first) |
| `SUPER + V` | float / tile window |
| `SUPER + SHIFT + F` | fullscreen window (covers bar and gaps) |
| `SUPER + F` | hide / show the bar (notifications and the OSD still pop in) |
| `SUPER + 1…0`, `+ SHIFT` | go to / move window to workspace |
| `SUPER + S` | scratchpad workspace |
| `Print` | screenshot: select a region (screen freezes while selecting) |
| `SHIFT + Print` | screenshot: whole monitor |
| `SUPER + Print` | screenshot: focused window |

Screenshots go to `~/Pictures/Screenshots` and the clipboard.

## The bar

Separate pills along the top of each monitor:

```
[1 2 3][cpu mem temp]        [time] [media]        [quick widgets — coming]
```

| Pill | Shows | Mouse |
|---|---|---|
| workspaces | workspaces on this monitor, active highlighted | click: go there · scroll: next / previous |
| stats | CPU %, used RAM, CPU temperature (`sensors`) every 2 s; amber when high (70% / 70°), bold at 90% / 85° | |
| clock | date + time (+ running timer / stopwatch) | click time: timer / stopwatch · click date: calendar |
| media | cover + title, only while something plays | hover: artist, progress, prev/play/next |

The clock pill also shows the volume / brightness OSD (plain 5% steps) and,
for now, notification popups (left click: open · right click: dismiss).
Panels close when you click anywhere outside the bar.

Quickshell is also the notification daemon, so don't run mako/dunst next to it.
Live reload on save doesn't always pick up changes (files in `bar/`, new files),
so after editing restart it: `pkill -x qs; hyprctl dispatch 'hl.dsp.exec_cmd("qs")'`.
Errors: `qs log`.

From a shell or a keybind:

```
qs ipc call bar toggle            hide / show the bar · show · hide
qs ipc call panel toggle          open/close the timer / stopwatch panel
qs ipc call timer start 25        timer: start 25 min · toggle · reset
qs ipc call stopwatch toggle      stopwatch: toggle · lap · reset
```

## Layout

```
hypr/
  hyprland.lua        entry point, just require()s the files in dots/
  hyprpaper.conf      wallpaper
  dots/               one file per topic: monitors, input, keybindings, look…
rofi/
  config.rasi         behaviour + @imports
  dots/               colors, window, inputbar, listview
  dots/themes/        colour themes: vague (default), basic
kitty/kitty.conf
quickshell/
  shell.qml           entry point, one bar per monitor
  Theme.qml           colours/sizes (same palette as rofi)
  services/           audio, brightness, media, notifications, osd, stats, timer, stopwatch
  bar/                the bar, one file per pill, and the views inside them
scripts/screenshot.sh grim + slurp + hyprpicker + wl-copy
scripts/theme.sh      switch the colour theme (bar + rofi)
scripts/logout.sh     clean logout: close apps, stop background clients, exit
scripts/wallet-to-nm.py  one-off: move Wi-Fi passwords from KDE Wallet into NetworkManager
cursors/
  Robot/              Breeze Light + steel-blue ring spinner (hyprcursor + XCursor)
  build_xcursor.py    rebuilds the XCursor part if you edit the spinner
```

## Credits

Cursor theme based on KDE's Breeze Light cursors (GPL).
Wallpaper default from Hyprland.
