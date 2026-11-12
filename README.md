# basic-hypr

A Basic hyprland setup: Lua based config, rofi launcher,
kitty terminal, a simple screenshot tool and the Robot cursor theme which is based on Breeze Light.

## Install

```bash
git clone <this repo> anywhere/you/like
cd anywhere/you/like
./install.sh --dry-run   # see what will happen
./install.sh             # do it
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
| `scripts/screenshot.sh` | `~/.local/scripts/screenshot.sh` |
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
| Screenshots | `grim` `slurp` `hyprpicker` `wl-clipboard` `jq` `xdg-user-dirs` |
| Qt/KDE apps looking right | `plasma-integration` `plasma-breeze` (used via `QT_QPA_PLATFORMTHEME=kde`) |
| File manager | `dolphin` |
| Cursor (only to rebuild) | `breeze-cursor-theme` `python3-gobject` `python3-cairo` |

**Optional:** fonts and icons. Without them everything still works — the
system's default sans / monospace font and icon theme are used instead.

- [Hack Nerd Font](https://www.nerdfonts.com/font-downloads) — rofi
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) — kitty
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) (`Papirus-Dark`) — rofi icons

## Keys (SUPER = Windows key)

| Key | Does |
|---|---|
| `SUPER + Q` / `E` / `R` | terminal / file manager / launcher |
| `SUPER + C` | close window |
| `SUPER + V` | float / tile window |
| `SUPER + 1…0`, `+ SHIFT` | go to / move window to workspace |
| `SUPER + S` | scratchpad workspace |
| `Print` | screenshot: select a region (screen freezes while selecting) |
| `SHIFT + Print` | screenshot: whole monitor |
| `SUPER + Print` | screenshot: focused window |

Screenshots go to `~/Pictures/Screenshots` and the clipboard.

## Layout

```
hypr/
  hyprland.lua        entry point, just require()s the files in dots/
  hyprpaper.conf      wallpaper
  dots/               one file per topic: monitors, input, keybindings, look…
rofi/
  config.rasi         behaviour + @imports
  dots/               colors, window, inputbar, listview
kitty/kitty.conf
scripts/screenshot.sh grim + slurp + hyprpicker + wl-copy
cursors/
  Robot/              Breeze Light + steel-blue ring spinner (hyprcursor + XCursor)
  build_xcursor.py    rebuilds the XCursor part if you edit the spinner
```

## Credits

Cursor theme based on KDE's Breeze Light cursors (GPL).
Wallpaper default from Hyprland.
