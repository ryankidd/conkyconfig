# Minimal Conky

## systemd (recommended)

User units live in `~/.config/systemd/user/`:

| Unit | Purpose |
|------|---------|
| `conky-minimal.service` | Runs Conky with this `conky.conf`, restarts on exit |
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

## Window type and stacking

Current attempt: **`own_window_type = 'normal'`** with **`own_window_transparent = true`** (this was **`false`** before; that often yields an opaque black backing with **`normal`**), **`own_window_argb_visual = true`**, **`own_window_argb_value = 0`**, and **`below`** in hints.

If the background is **solid black** or the whole window looks wrong, try in order:

1. Set **`own_window_argb_value = 255`** (some compositors want “opaque” ARGB with a transparent client background).
2. Toggle **`double_buffer`** to **`false`** (rarely fixes transparency glitches).
3. Revert to **`override`** (known-good here):  
   `own_window_type = 'override'`, **`own_window_transparent = false`**, **`own_window_argb_value = 0`**, and accept that **`below`** is ignored.

**COSMIC / Wayland:** Conky is still largely an **X11** client (often **XWayland**). Real transparency and stacking depend on the compositor’s treatment of XWayland windows; tiling COSMIC so nothing covers the Conky strip is a solid plan if **`normal`** never looks right.

## Monitor

- **`xinerama_head`** — Chooses which monitor **`alignment`** / **`gap_*`** use. If Conky is on the wrong display, try **`0`** or **`1`**, or run **`xrandr --listmonitors`** and match the index you want.

## If it stops auto-starting after crashes

Conky was hitting **start-rate limits** (default: 5 failures in 10s → unit goes **failed** and systemd stops restarting until you reset). The unit sets **`StartLimitIntervalSec=0`** in **`[Unit]`** so a bad session does not strand the service.

If it is already failed:

```bash
systemctl --user reset-failed conky-minimal.service
systemctl --user start conky-minimal.service
```

Repeated **`code=dumped, status=6/ABRT`** in `journalctl --user -u conky-minimal.service` is a separate bug (config, Lua, or X not ready); check logs after fixing limits.

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

- **`human-gb.sh`** — RAM, swap, and filesystem lines as decimal gigabytes (SI, powers of 1000), format **`used/totalGb`** (e.g. `934/1824Gb`). Uses `/proc/meminfo` and **`df --si -BG`**.
- **`nvidia-conky.sh`** — GPU stats via **`nvidia-smi`**; **`vram`** uses the same **`used/totalGb`** style for VRAM.
- **`mangohud-fps.sh`** — Reads the **latest MangoHud `*.csv`** (not `*_summary.csv`) from **`~/.config/MangoHud/mangologs`** or **`~/.local/share/MangoHud`**, preferring filenames that look like **Ark / Ascended / ShooterGame**. Parses the column header row starting with **`fps`**, then the **last numeric data row** (first field = FPS). Shows **`—`** if no log exists. Requires MangoHud logging: set **`output_folder`** in MangoHud config, then in-game **Shift+F2** (default) to capture, or enable **`autostart_log`**. Steam launch example: **`mangohud %command%`**. Override search path with **`CONKY_MANGOHUD_LOGDIR`**.
- **Containers row** (below network, no outer rounded frame) — **`lua_draw_hook_pre`** draws **two inner rounded cells**; use **`${lua_parse media_container_icons}`** so Conky **parses** the returned **`${font}` / `${color}`** markup. Plain **`${lua …}`** only **prints** the string and would show literal **`${…}`** on screen. Icons: **md-jellyfish** (Jellyfin stand-in) + **md-emby**; **up** = **`ffffff`**, **down** = **`7f7f7f`**. Docker is cached ~8s in **`borders.lua`**. Optional: **`media-containers.sh jellyfin|emby`**.
