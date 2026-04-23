# Minimal Conky

This is a **personal Conky HUD** for X11: a tall strip of system info (CPU, GPU via `nvidia-smi`, RAM, disks, network, optional MangoHud FPS, Jellyfin/Emby/ComfyUI Docker status) with **Lua-drawn** section borders and helper shell scripts. Config is plain `**conky.conf`** (Lua table + `conky.text`); `**borders.lua**` is loaded for Cairo hooks.

**Typical use:** edit `**conky.conf`** (and `**borders.lua**` if you change layout heights), then reload Conky. With **systemd user** units enabled, run `**systemctl --user restart conky-minimal.service`**. Without systemd, run `**./start.sh**` from this directory (it restarts the user service when available, otherwise starts `conky` in the background). First-time setup: enable the units in the next section so Conky starts with your graphical session.

## systemd (recommended)

User units live in `~/.config/systemd/user/`:


| Unit                          | Purpose                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| `conky-minimal.service`       | Runs Conky with this `conky.conf`, restarts on exit                                         |
| `conky-minimal-restart.timer` | Every 4h, `try-restart` the service if it is running (first fire 4h after the timer starts) |


Enable once:

```bash
systemctl --user daemon-reload
systemctl --user enable --now conky-minimal.service
systemctl --user enable --now conky-minimal-restart.timer
```

The service is tied to `graphical-session.target` (starts with your graphical session, stops when you log out).

To run the user session at boot without logging in at the console (optional):

```bash
sudo loginctl enable-linger "$USER"
```

## Monitor

- `**xinerama_head**` — Chooses which monitor `**alignment**` / `**gap_***` use. If Conky is on the wrong display, try `**0**` or `**1**`, or run `**xrandr --listmonitors**` and match the index you want.

## If it stops auto-starting after crashes

Conky was hitting **start-rate limits** (default: 5 failures in 10s → unit goes **failed** and systemd stops restarting until you reset). The unit sets `**StartLimitIntervalSec=0`** in `**[Unit]**` so a bad session does not strand the service.

If it is already failed:

```bash
systemctl --user reset-failed conky-minimal.service
systemctl --user start conky-minimal.service
```

Repeated `**code=dumped, status=6/ABRT**` in `journalctl --user -u conky-minimal.service` is a separate bug (config, Lua, or X not ready); check logs after fixing limits.

## Manual reload

```bash
systemctl --user restart conky-minimal.service
```

Or run `./start.sh`, which prefers systemd when the user bus is available.

## Cron (optional)

If you prefer cron over the timer, disable the timer and add (example every 6 hours):

```cron
0 */6 * * * XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user try-restart conky-minimal.service
```

The timer avoids setting `XDG_RUNTIME_DIR` and keeps restarts in systemd.

## Scripts

- `**human-gb.sh**` — RAM, swap, and filesystem lines as decimal gigabytes (SI, powers of 1000), format `**used/totalGb**` (e.g. `934/1824Gb`). Uses `/proc/meminfo` and `**df --si -BG**`.
- `**nvidia-conky.sh**` — GPU stats via `**nvidia-smi**`; `**vram**` uses the same `**used/totalGb**` style for VRAM.
- `**mangohud-fps.sh**` — Reads the **latest MangoHud `*.csv`** (not `*_summary.csv`) from `**~/.config/MangoHud/mangologs**` or `**~/.local/share/MangoHud**`, preferring filenames that look like **Ark / Ascended / ShooterGame**. Parses the column header row starting with `**fps`**, then the **last numeric data row** (first field = FPS). Shows `**—`** if no log exists. Requires MangoHud logging: set `**output_folder**` in MangoHud config, then in-game **Shift+F2** (default) to capture, or enable `**autostart_log`**. Steam launch example: `**mangohud %command%**`. Override search path with `**CONKY_MANGOHUD_LOGDIR**`.
- **Containers row** (below network, no outer rounded frame) — **`lua_draw_hook_pre`** draws **three inner rounded cells**; use **`${lua_parse media_container_icons}`** so Conky parses the returned markup. Icons: **md-jellyfish**, **md-emby**, **md-sitemap** (ComfyUI stand-in). **up** = **`ffffff`**, **down** = **`5f5f5f`**. Docker **`name=`** checks are cached ~8s in **`borders.lua`**. Optional: **`media-containers.sh jellyfin|emby|comfyui`**.

