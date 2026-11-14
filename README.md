# basic-hypr

A Basic hyprland setup: Lua based config, rofi launcher,
kitty terminal, a simple screenshot tool and the Robot cursor theme which is based on Breeze Light.

## Install

```bash
git clone https://github.com/4dotk/basic-hypr.git
cd basic-hypr
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
| Lock screen + idle | `hyprlock` `hypridle` `brightnessctl` |
| Bar | `quickshell` `brightnessctl` |
| Quick pill (network, Bluetooth, battery) | `NetworkManager` `bluez` `upower` `tuned-ppd` (or `power-profiles-daemon`) |
| Clipboard history | `cliphist` `wl-clipboard` |
| Notification sounds | `pipewire-utils` (`pw-play`) `ocean-sound-theme` `sound-theme-freedesktop` |
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
- [Red Hat Display](https://github.com/RedHatOfficial/RedHatFont) (`redhat-display-fonts`) — lock screen
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
| `SUPER + L` | lock (also after 5 min idle: dim at 2, lock at 5, screen off at 5.5, sleep at 15) |
| `SUPER + M` | log out cleanly (closes apps first) |
| `CTRL + ALT + Delete` | power screen: lock, log out, suspend, reboot, shut down (←/→ Enter, Esc) |
| `SUPER + V` | clipboard history |
| `SUPER + SHIFT + V` | float / tile window |
| `SUPER + P` | pseudo-tile window |
| `SUPER + J` | toggle split direction |
| `SUPER + SHIFT + F` | fullscreen window (covers bar and gaps) |
| `SUPER + F` | hide / show the bar (notifications and the OSD still pop in) |
| `SUPER + 1…0`, `+ SHIFT` | go to / move window to workspace |
| `SUPER + S` / `+ SHIFT` | show the scratchpad / send window there |
| `SUPER + scroll` | next / previous workspace |
| `SUPER + drag` (left / right button) | move / resize window |
| `Print` | screenshot: select a region (screen freezes while selecting) |
| `SHIFT + Print` | screenshot: whole monitor |
| `SUPER + Print` | screenshot: focused window |
| media keys | volume, mute, mic mute, brightness, play / pause / next / previous (also on the lock screen) |

Screenshots go to `~/Pictures/Screenshots` and the clipboard.

## The bar

Separate pills along the top of each monitor:

```
[1 2 3 4][cpu mem temp]      [Fri 13 Nov  19:36]      [media][net bt vol bat][bell]
```

| Pill | Shows | Mouse |
|---|---|---|
| workspaces | workspaces on this monitor, active highlighted | click: go there · scroll: next / previous |
| stats | CPU %, used RAM, CPU temperature (read straight from `/proc` and the kernel's hwmon sensor, AMD `k10temp` or Intel `coretemp`) every 2 s; amber when high (70% / 70°), bold at 90% / 85° | |
| clock | date + time (+ running timer / stopwatch) | click date: calendar · click time: timer / stopwatch |
| media | cover + title, only while something plays (and a few seconds after pausing) | hover: artist, progress, prev / play / next |
| quick | clipboard, network, Bluetooth, volume, battery % (Bluetooth / battery only when the machine has them) | click an icon: its own dropdown · scroll: volume ±5% |
| bell | dot = unread, bell-off = do not disturb | click: notification center |

**Dropdowns** slide out under their pill as one shape with it (drawers); only
one is open at a time and a click anywhere outside closes it.

| Icon | Dropdown |
|---|---|
| clipboard | recent copies (cliphist), newest first. Click: copy it again · − or right click: delete · **Clear**: forget all. Images show as a line of text. |
| network | wired status; Wi-Fi switch; networks by signal, connected first (scrolls). Click: connect (password field for WPA / WPA3 personal) or disconnect. Enterprise (802.1x) networks are set up in `nm-connection-editor`. Scans only while open. **Hotspot** switch: the first time it asks for a password; while on it shows its name (the password is never shown; sharing it by QR code is planned). It uses the Wi-Fi card, so Wi-Fi disconnects while it runs, and other devices only get internet when you're on a cable. |
| Bluetooth | power switch; paired devices (connected first, battery %); scan button for nearby devices, click to pair + connect. No PIN pairing. |
| volume | mixer: **Output** and **Mic** devices (click a name to make it the default, slider, mute) and **Apps** playing sound (per-app slider + mute) |
| battery | level, time left / to full, health; power mode: Saver / Balanced / Performance (a small badge on the icon shows Saver / Performance) |

**Clock cards:** the calendar (arrows or scroll change month, click the month
to jump back to today) and Timer | Stopwatch (type or scroll the hh : mm : ss
fields, Enter to start; stopwatch keeps the last 3 laps). Both keep running
with the card closed. They hang a small gap below the clock.

**OSD:** volume and brightness changes (keys, or any app via PipeWire) show a
level bar in the clock pill for a moment, on the focused monitor.

**Notifications:** Quickshell is the notification daemon, so don't run
mako / dunst / swaync next to it. Popups come out of the bell one at a time
(amber border = critical; critical ones stay until clicked). The center lists
everything, newest first: click to open, right click to remove, **Clear** for
all. New ones play a sound (the app's own, else KDE Ocean's "message-attention";
"dialog-warning" for critical ones). **Do not disturb** stops popups, except critical ones, and all sounds. History is kept
in memory, so a quickshell restart clears it.

**Empty workspace:** with no windows on the workspace, the pills join into
one full-width bar. Opening a window tears it back into pills (the long gaps
next to the clock pull apart like goo, the short ones just open); closing the
last window joins it again.

**SUPER + F** hides the bar: the pills slide up and windows take the space;
the OSD and notification popups still pop in.

**Power screen** (`CTRL + ALT + Delete`): Lock, Log out, Suspend, Reboot,
Shut down over the dimmed, blurred desktop. ←/→ or Tab to move, Enter to
choose, Esc or a click outside to close. Log out / reboot / shut down first
grow their tile to fill the screen; Esc while it grows cancels.

Live reload on save doesn't always pick up changes (files in `bar/`, new files),
so after editing restart it: `pkill -x qs; hyprctl dispatch 'hl.dsp.exec_cmd("qs")'`.
Errors: `qs log`.

From a shell or a keybind:

```
qs ipc call bar toggle            hide / show the bar · show · hide
qs ipc call panel open network    open a dropdown: clipboard · network · bluetooth · sound · battery · calendar · clocks
qs ipc call panel toggle          open/close the timer / stopwatch card
qs ipc call power toggle          the power screen
qs ipc call timer start 25        timer: start 25 min · toggle · reset
qs ipc call stopwatch toggle      stopwatch: toggle · lap · reset
qs ipc call theme set basic       colour theme (theme.sh does this for you)
```

## Layout

```
hypr/
  hyprland.lua        entry point, just require()s the files in dots/
  hyprpaper.conf      wallpaper
  hyprlock.conf       lock screen (wallpaper: ~/Pictures/Saved/ecorp.jpg)
  hypridle.conf       idle: dim, lock, screen off, sleep
  dots/               one file per topic: monitors, input, keybindings, look…
rofi/
  config.rasi         behaviour + @imports
  dots/               colors, window, inputbar, listview
  dots/themes/        colour themes: vague (default), basic
kitty/kitty.conf
quickshell/
  shell.qml           entry point, one bar per monitor
  Theme.qml           colours/sizes (same palette as rofi)
  services/           audio, network + hotspot (Net), bluetooth (Bt), battery, brightness, clipboard (ClipHist), media,
                      notifications, osd, stats, timer, stopwatch
  bar/                the bar, one file per pill, and the views inside them
  icons/              the quick pill's icons (own SVGs, tinted to the theme)
scripts/screenshot.sh grim + slurp + hyprpicker + wl-copy
scripts/theme.sh      switch the colour theme (bar + rofi)
scripts/wallet-to-nm.py  one-off: move Wi-Fi passwords from KDE Wallet into NetworkManager
cursors/
  Robot/              Breeze Light + steel-blue ring spinner (hyprcursor + XCursor)
  build_xcursor.py    rebuilds the XCursor part if you edit the spinner
```

## Credits

Cursor theme based on KDE's Breeze Light cursors (GPL).
Wallpaper default from Hyprland.
