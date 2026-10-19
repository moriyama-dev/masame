local core = require "core"
local common = require "core.common"
local style = require "core.style"
local View = require "core.view"

-- The title bar drawn when the window has no system decorations
-- (config.borderless). It follows the look of the desktop's own title bars:
-- a centered title and round, quiet buttons that only act on release.

local restore_command = {
  symbol = "restore", action = function() system.set_window_mode("normal") end
}

local maximize_command = {
  symbol = "maximize", action = function() system.set_window_mode("maximized") end
}

local title_commands = {
  {symbol = "minimize", action = function() system.set_window_mode("minimized") end},
  maximize_command,
  {symbol = "close", action = function() core.quit() end},
}

local function with_alpha(color, alpha)
  return { color[1], color[2], color[3], alpha }
end

local function colors()
  local text = style.titlebar_text or style.accent
  return {
    background = style.titlebar or style.background2,
    text = text,
    text_inactive = style.titlebar_text_inactive or style.dim,
    button = style.titlebar_button or with_alpha(text, 18),
    button_hover = style.titlebar_button_hover or with_alpha(text, 32),
    button_active = style.titlebar_button_active or with_alpha(text, 52),
  }
end

local function button_size()
  return common.round(24 * SCALE)
end

local function button_spacing()
  return common.round(10 * SCALE)
end

local function controls_width()
  return (button_size() + button_spacing()) * #title_commands + button_spacing()
end

-- Filled circle made of one rect per row, with soft edges.
local function draw_circle(cx, cy, r, color)
  local alpha = color[4] or 255
  for row = math.floor(cy - r), math.ceil(cy + r) - 1 do
    local dy = row + 0.5 - cy
    local half = r * r - dy * dy
    if half > 0 then
      half = math.sqrt(half)
      local x1, x2 = cx - half, cx + half
      local ix1, ix2 = math.ceil(x1), math.floor(x2)
      if ix2 > ix1 then
        renderer.draw_rect(ix1, row, ix2 - ix1, 1, color)
      end
      local edge = { color[1], color[2], color[3], alpha * (ix1 - x1) }
      renderer.draw_rect(ix1 - 1, row, 1, 1, edge)
      edge = { color[1], color[2], color[3], alpha * (x2 - ix2) }
      renderer.draw_rect(ix2, row, 1, 1, edge)
    end
  end
end

local function outline(x, y, w, h, lw, color)
  renderer.draw_rect(x, y, w, lw, color)
  renderer.draw_rect(x, y + h - lw, w, lw, color)
  renderer.draw_rect(x, y, lw, h, color)
  renderer.draw_rect(x + w - lw, y, lw, h, color)
end

-- Thin line icons, centered on (cx, cy).
local function draw_icon(symbol, cx, cy, color)
  local lw = math.max(1, common.round(SCALE))
  local size = common.round(10 * SCALE)
  local x, y = math.floor(cx - size / 2), math.floor(cy - size / 2)
  if symbol == "minimize" then
    renderer.draw_rect(x, math.floor(cy + size / 2 - lw), size, lw, color)
  elseif symbol == "maximize" then
    outline(x, y, size, size, lw, color)
  elseif symbol == "restore" then
    local d = common.round(2 * SCALE)
    renderer.draw_rect(x + d, y, size - d, lw, color)
    renderer.draw_rect(x + size - lw, y, lw, size - d, color)
    outline(x, y + d, size - d, size - d, lw, color)
  elseif symbol == "close" then
    for i = 0, size - lw do
      renderer.draw_rect(x + i, y + i, lw, lw, color)
      renderer.draw_rect(x + size - lw - i, y + i, lw, lw, color)
    end
  end
end

---@class core.titleview : core.view
---@field super core.view
local TitleView = View:extend()

function TitleView:__tostring() return "TitleView" end

local function title_view_height()
  return math.max(style.font:get_height(), button_size()) + style.padding.y * 2
end

function TitleView:new()
  TitleView.super.new(self)
  self.visible = true
end

function TitleView:configure_hit_test(borderless)
  if borderless then
    system.set_window_hit_test(title_view_height(), controls_width(), common.round(6 * SCALE))
  else
    system.set_window_hit_test()
  end
end

function TitleView:on_scale_change()
  self:configure_hit_test(self.visible)
end

function TitleView:update()
  self.size.y = self.visible and title_view_height() or 0
  title_commands[2] = core.window_mode == "maximized" and restore_command or maximize_command
  TitleView.super.update(self)
end


function TitleView:draw_window_title(c)
  local ox, oy = self:get_content_offset()
  local color = system.window_has_focus() and c.text or c.text_inactive
  local title = core.compose_window_title(core.window_title)
  -- Centered in the window, but never under the buttons.
  local room = self.size.x - 2 * controls_width()
  local w = style.font:get_width(title)
  local x = ox + (self.size.x - math.min(w, room)) / 2
  core.push_clip_rect(ox + controls_width(), oy, math.max(room, 0), self.size.y)
  common.draw_text(style.font, color, title, nil, x, oy, 0, self.size.y)
  core.pop_clip_rect()
end

function TitleView:each_control_item()
  local size, spacing = button_size(), button_spacing()
  local ox, oy = self:get_content_offset()
  ox = ox + self.size.x
  local i, n = 0, #title_commands
  local iter = function()
    i = i + 1
    if i <= n then
      local dx = - (size + spacing) * (n - i + 1)
      local dy = (self.size.y - size) / 2
      return title_commands[i], ox + dx, oy + dy, size, size
    end
  end
  return iter
end


function TitleView:draw_window_controls(c)
  local focused = system.window_has_focus()
  for item, x, y, w, h in self:each_control_item() do
    local bg = c.button
    if item == self.hovered_item then
      bg = item == self.pressed_item and c.button_active or c.button_hover
    end
    draw_circle(x + w / 2, y + h / 2, w / 2, bg)
    local color = (focused or item == self.hovered_item) and c.text or c.text_inactive
    draw_icon(item.symbol, x + w / 2, y + h / 2, color)
  end
end


function TitleView:on_mouse_pressed(button, x, y, clicks)
  local caught = TitleView.super.on_mouse_pressed(self, button, x, y, clicks)
  if caught then return end
  core.set_active_view(core.last_active_view)
  if button == "left" then
    self.pressed_item = self.hovered_item
  elseif button == "right" and not self.hovered_item then
    system.show_window_menu(x, y)
  end
  return true
end


function TitleView:on_mouse_released(button, x, y)
  TitleView.super.on_mouse_released(self, button, x, y)
  local item = self.pressed_item
  self.pressed_item = nil
  if button == "left" and item and item == self.hovered_item then
    item.action()
  end
end


function TitleView:on_mouse_moved(px, py, ...)
  if self.size.y == 0 then return end
  TitleView.super.on_mouse_moved(self, px, py, ...)
  self.hovered_item = nil
  for item, x, y, w, h in self:each_control_item() do
    if px > x and py > y and px <= x + w and py <= y + h then
      self.hovered_item = item
      return
    end
  end
end


function TitleView:on_mouse_left()
  TitleView.super.on_mouse_left(self)
  self.hovered_item = nil
  self.pressed_item = nil
end


function TitleView:draw()
  local c = colors()
  self:draw_background(c.background)
  self:draw_window_title(c)
  self:draw_window_controls(c)
end

return TitleView
