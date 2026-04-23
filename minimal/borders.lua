-- Faint rounded stroke frames around CPU / GPU / Memory / Disk / Network (containers have no outer box).
-- Container row: lua_draw_hook_pre draws inner cell borders; use ${lua_parse media_container_icons} (not $lua) so the returned Conky markup is parsed.

require('cairo')
pcall(require, 'cairo_xlib')

local CORNER_R = 10
local PAD_X = 0
local LINE_A = 0.2
local LINE_W = 1

local GAP = 14

local HEADER_SKIP = 515

local CPU_H = 204
local GPU_H = 192
local MEM_H = 125
local DISK_H = 280
local NET_H = 152

local y1 = HEADER_SKIP
local y2 = y1 + CPU_H + GAP
local y3 = y2 + GPU_H + GAP
local y4 = y3 + MEM_H + GAP
local y5 = y4 + DISK_H + GAP

local SECTIONS = {
  { y = y1, h = CPU_H },
  { y = y2, h = GPU_H },
  { y = y3, h = MEM_H },
  { y = y4, h = DISK_H },
  { y = y5, h = NET_H },
}

-- Vertical layout inside the containers block (must match conky.conf # containers).
local CONT_VO_TOP = 12
local CONT_HDR_LINE = 24
local CONT_VO_GAP = 4
local CONT_ICON_ROW_TOP = CONT_VO_TOP + CONT_HDR_LINE + CONT_VO_GAP
local CONT_CELL_H = 42
local CONT_CELL_PAD = 4
local CONT_CELL_R = 8

-- Nerd icons: md-jellyfish (Jellyfin stand-in), md-emby (UTF-8 literals for all Lua versions).
local ICON_JF = '\243\176\188\129'
local ICON_EM = '\243\176\154\180'

local dock_cache = { t = 0, jf = false, em = false }

local function docker_up(filter)
  local h = io.popen('docker ps -q --filter name=' .. filter .. ' 2>/dev/null | head -1', 'r')
  if not h then
    return false
  end
  local s = h:read('*a') or ''
  h:close()
  return s:match('%S') ~= nil
end

local function dock_refresh()
  local now = os.time()
  if now - dock_cache.t < 8 then
    return
  end
  dock_cache.t = now
  dock_cache.jf = docker_up('jellyfin')
  dock_cache.em = docker_up('emby')
end

local function rounded_rectangle(cr, x, y, w, h, radius)
  local deg = math.pi / 180.0
  radius = math.min(radius, w / 2, h / 2)
  if radius < 1 then
    radius = 1
  end
  cairo_new_sub_path(cr)
  cairo_arc(cr, x + w - radius, y + radius, radius, -90 * deg, 0 * deg)
  cairo_arc(cr, x + w - radius, y + h - radius, radius, 0 * deg, 90 * deg)
  cairo_arc(cr, x + radius, y + h - radius, radius, 90 * deg, 180 * deg)
  cairo_arc(cr, x + radius, y + radius, radius, 180 * deg, 270 * deg)
  cairo_close_path(cr)
end

-- Under the text layer: two rounded cells (left two quarters of the row).
function conky_container_cells()
  if conky_window == nil then
    return
  end
  dock_refresh()

  local win_w = conky_window.width
  local base_y = conky_window.text_start_y or 0
  -- Containers block is below the Network box (no outer frame for that block).
  local y0 = base_y + y5 + NET_H + CONT_ICON_ROW_TOP
  local cell = win_w / 4
  local h = CONT_CELL_H

  local cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    win_w,
    conky_window.height
  )
  local cr = cairo_create(cs)
  if cr == nil then
    cairo_surface_destroy(cs)
    return
  end

  cairo_save(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
  cairo_set_antialias(cr, CAIRO_ANTIALIAS_DEFAULT)
  cairo_set_line_width(cr, 1.25)
  cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
  cairo_set_source_rgba(cr, 1, 1, 1, 0.38)

  for col = 0, 1 do
    local x = PAD_X + col * cell + CONT_CELL_PAD
    local w = cell - 2 * CONT_CELL_PAD
    rounded_rectangle(cr, x, y0, w, h, CONT_CELL_R)
    cairo_stroke(cr)
  end

  cairo_restore(cr)
  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end

function conky_section_borders()
  if conky_window == nil then
    return
  end

  local win_w = conky_window.width
  local win_h = conky_window.height
  local cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    win_w,
    win_h
  )
  local cr = cairo_create(cs)
  if cr == nil then
    cairo_surface_destroy(cs)
    return
  end

  local x = PAD_X
  local w = win_w - 2 * PAD_X
  local base_y = conky_window.text_start_y or 0

  cairo_save(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
  cairo_set_antialias(cr, CAIRO_ANTIALIAS_DEFAULT)
  cairo_set_line_width(cr, LINE_W)
  cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
  cairo_set_source_rgba(cr, 1, 1, 1, LINE_A)

  for _, s in ipairs(SECTIONS) do
    rounded_rectangle(cr, x, base_y + s.y, w, s.h, CORNER_R)
    cairo_stroke(cr)
  end

  cairo_restore(cr)
  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end

-- Text layer: two Nerd icons (md-jellyfish / md-emby), dim when container down.
function conky_media_container_icons()
  dock_refresh()
  local cjf = dock_cache.jf and 'ffffff' or '7f7f7f'
  local cem = dock_cache.em and 'ffffff' or '7f7f7f'
  return string.format(
    '${font Symbols Nerd Font Mono:size=34}${offset 26}${color %s}%s${offset 90}${color %s}%s${font Ubuntu:size=12}${color ffffff}',
    cjf,
    ICON_JF,
    cem,
    ICON_EM
  )
end
