local style = require "core.style"
local keymap = require "core.keymap"
local View = require "core.view"

---@class core.emptyview : core.view
---@field super core.view
local EmptyView = View:extend()

function EmptyView:__tostring() return "EmptyView" end

function EmptyView:get_name()
  return "Get Started"
end

function EmptyView:get_filename()
  return ""
end

local function draw_text(x, y, color)
  local lines = {
    { fmt = "%s to create a new file", cmd = "core:new-doc" },
    { fmt = "%s to open a file", cmd = "core:open-file" },
    { fmt = "%s to go to a file in the folder", cmd = "core:find-file" },
  }
  local th = style.big_font:get_height()
  local dh = 2 * th + style.padding.y * 2
  local x1, y1 = x, y + ((dh - th) / #lines)
  local xv = x1
  local title = "Masame"
  local version = "version " .. VERSION
  local title_width = style.big_font:get_width(title)
  local version_width = style.font:get_width(version)
  if version_width > title_width then
    version = VERSION
    version_width = style.font:get_width(version)
    xv = x1 - (version_width - title_width)
  end
  x = renderer.draw_text(style.big_font, title, x1, y1, color)
  renderer.draw_text(style.font, version, xv, y1 + th, color)
  x = x + style.padding.x
  renderer.draw_rect(x, y, math.ceil(1 * SCALE), dh, color)
  th = style.font:get_height()
  y = y + (dh - (th + style.padding.y) * #lines) / 2
  local w = 0
  for _, line in ipairs(lines) do
    local text = string.format(line.fmt, keymap.get_binding(line.cmd))
    w = math.max(w, renderer.draw_text(style.font, text, x + style.padding.x, y, color))
    y = y + th + style.padding.y
  end
  return w, dh
end

function EmptyView:draw()
  self:draw_background(style.background)
  local w, h = draw_text(0, 0, { 0, 0, 0, 0 })
  local x = self.position.x + math.max(style.padding.x, (self.size.x - w) / 2)
  local y = self.position.y + (self.size.y - h) / 2
  draw_text(x, y, style.dim)
end

return EmptyView
