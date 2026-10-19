local core = require "core"
local command = require "core.command"
local common = require "core.common"
local config = require "core.config"
local View = require "core.view"
local style = require "core.style"
local i18n = require "core.i18n"

local BORDER_WIDTH = common.round(1 * SCALE)

-- Dialogs are drawn as a small centered window over a lightly dimmed editor:
-- an icon and the message on top, and a row of equal buttons at the bottom.
-- The focused button (Enter) has a light outline; the hovered one is lighter.

local noop = function() end

---@class core.nagview : core.view
---@field super core.view
local NagView = View:extend()

function NagView:__tostring() return "NagView" end

function NagView:new()
  NagView.super.new(self)
  self.size.y = 0
  self.show_progress = 0
  self.force_focus = false
  self.queue = {}
  self.scrollable = false
  self.on_mouse_pressed_root = nil
end

function NagView:get_title()
  return self.title
end

local function colors()
  return {
    background = style.dialog or style.background3,
    border = style.dialog_border or style.divider,
    text = style.dialog_text or style.accent,
    hover = style.dialog_button_hover or style.line_highlight,
    focus = style.dialog_button_focus or style.dim,
    dim = style.dialog_dim or style.nagbar_dim,
  }
end

local function fade(color, progress)
  return { color[1], color[2], color[3], (color[4] or 255) * progress }
end

local function line_height()
  return math.floor(style.font:get_height() * 1.4)
end

-- Splits the message into lines that fit in `width`. Breaks at spaces when
-- possible, and anywhere for text without spaces (e.g. Japanese).
local function wrap_message(message, width)
  local lines = {}
  for paragraph in message:gmatch("([^\n]*)\n?") do
    local line, last_space = "", nil
    for char in common.utf8_chars(paragraph) do
      if style.font:get_width(line .. char) > width and line ~= "" then
        if last_space and char ~= " " then
          table.insert(lines, line:sub(1, last_space - 1))
          line = line:sub(last_space + 1) .. char
        else
          table.insert(lines, line)
          line = char == " " and "" or char
        end
        last_space = nil
      else
        line = line .. char
        if char == " " then last_space = #line end
      end
    end
    table.insert(lines, line)
  end
  -- gmatch yields one empty match at the end
  if #lines > 1 and lines[#lines] == "" then table.remove(lines) end
  return lines
end

function NagView:get_layout()
  local pad = common.round(26 * SCALE)
  local icon_w = style.icon_big_font:get_width("!")
  local bh = style.font:get_height() + common.round(22 * SCALE)
  local rw, rh = core.root_view.size.x, core.root_view.size.y

  -- buttons decide the minimum width, the message may widen the dialog
  local bw = common.round(110 * SCALE)
  for _, opt in ipairs(self.options) do
    bw = math.max(bw, style.font:get_width(i18n.t(opt.text)) + 2 * pad)
  end
  local max_w = math.max(rw - 4 * style.padding.x, bw)
  local text_w = 0
  for line in self.message:gmatch("([^\n]*)") do
    text_w = math.max(text_w, style.font:get_width(line))
  end
  local w = math.max(bw * #self.options, common.round(480 * SCALE), icon_w + text_w + 3 * pad)
  w = math.min(w, max_w)

  local lines = wrap_message(self.message, w - icon_w - 3 * pad)
  local text_h = #lines * line_height()
  local body_h = math.max(text_h, style.icon_big_font:get_height()) + 2 * pad
  local h = math.min(body_h + bh, rh)
  local x = core.root_view.position.x + math.floor((rw - w) / 2)
  local y = core.root_view.position.y + math.floor((rh - h) / 2)
  return {
    x = x, y = y, w = w, h = h, pad = pad, icon_w = icon_w, lines = lines,
    text_h = text_h, body_h = h - bh, bh = bh,
  }
end

function NagView:get_scrollable_size()
  return 0
end

function NagView:dim_window_content(progress)
  local rv = core.root_view
  renderer.draw_rect(rv.position.x, rv.position.y, rv.size.x, rv.size.y, fade(colors().dim, progress))
end

function NagView:change_hovered(i)
  if i ~= self.hovered_item then
    self.hovered_item = i
    core.redraw = true
  end
end

function NagView:each_option()
  return coroutine.wrap(function()
    if not self.options then return end
    local l = self:get_layout()
    local n = #self.options
    local by = l.y + l.body_h
    for i, opt in ipairs(self.options) do
      local bx = l.x + math.floor(l.w * (i - 1) / n)
      local bx2 = l.x + math.floor(l.w * i / n)
      coroutine.yield(i, opt, bx, by, bx2 - bx, l.bh)
    end
  end)
end

function NagView:on_mouse_moved(mx, my, ...)
  if not self.visible then return end
  core.set_active_view(self)
  NagView.super.on_mouse_moved(self, mx, my, ...)
  local hovered
  for i, _, x,y,w,h in self:each_option() do
    if mx >= x and my >= y and mx < x + w and my < y + h then
      hovered = i
      break
    end
  end
  if hovered ~= self.mouse_item then
    self.mouse_item = hovered
    core.redraw = true
  end
end

local function register_mouse_pressed(self)
  if self.on_mouse_pressed_root then return end
  -- RootView is loaded locally to avoid NagView and RootView being
  -- mutually recursive
  local RootView = require "core.rootview"
  self.on_mouse_pressed_root = RootView.on_mouse_pressed
  local this = self
  function RootView:on_mouse_pressed(button, x, y, clicks)
    if
      not this:on_mouse_pressed(button, x, y, clicks)
    then
      return this.on_mouse_pressed_root(self, button, x, y, clicks)
    else
      return true
    end
  end
  self.new_on_mouse_pressed_root = RootView.on_mouse_pressed
end

local function unregister_mouse_pressed(self)
  local RootView = require "core.rootview"
  if
    self.on_mouse_pressed_root
    and
    -- just in case prevent overwriting what something else may
    -- have overwrote after us, but after testing with various
    -- plugins this doesn't seems to happen, but just in case
    self.new_on_mouse_pressed_root == RootView.on_mouse_pressed
  then
    RootView.on_mouse_pressed = self.on_mouse_pressed_root
    self.on_mouse_pressed_root = nil
    self.new_on_mouse_pressed_root = nil
  end
end

function NagView:on_mouse_pressed(button, mx, my, clicks)
  if not self.visible then return false end
  if NagView.super.on_mouse_pressed(self, button, mx, my, clicks) then return true end
  for i, _, x,y,w,h in self:each_option() do
    if mx >= x and my >= y and mx < x + w and my < y + h then
      self:change_hovered(i)
      command.perform "dialog:select"
    end
  end
  return true
end

function NagView:on_text_input(text)
  if not self.visible then return end
  if text:lower() == "y" then
    command.perform "dialog:select-yes"
  elseif text:lower() == "n" then
    command.perform "dialog:select-no"
  end
end

function NagView:update()
  if not self.visible and self.show_progress <= 0 then return end
  NagView.super.update(self)
  self.size.y = 0

  if self.visible and core.active_view == self and self.title then
    self:move_towards(self, "show_progress", 1, nil, "nagbar")
  else
    self:move_towards(self, "show_progress", 0, nil, "nagbar")
    if self.show_progress <= 0 then
      self.title = nil
      self.message = nil
      self.options = nil
      self.on_selected = nil
      self.mouse_item = nil
    end
  end
end

local function draw_nagview_message(self)
  local p = self.show_progress
  local c = colors()
  self:dim_window_content(p)

  local l = self:get_layout()
  -- border, then the dialog's background
  renderer.draw_rect(l.x - BORDER_WIDTH, l.y - BORDER_WIDTH, l.w + 2 * BORDER_WIDTH, l.h + 2 * BORDER_WIDTH, fade(c.border, p))
  renderer.draw_rect(l.x, l.y, l.w, l.h, fade(c.background, p))

  core.push_clip_rect(l.x, l.y, l.w, l.h)

  -- icon and message
  local icon_h = style.icon_big_font:get_height()
  local content_h = math.max(l.text_h, icon_h)
  local top = l.y + math.floor((l.body_h - content_h) / 2)
  local ix = l.x + l.pad
  common.draw_text(style.icon_big_font, fade(c.text, p), "!", nil, ix, top, l.icon_w, icon_h)
  local tx = ix + l.icon_w + l.pad
  local ty = top + math.floor((content_h - l.text_h) / 2)
  local lh = line_height()
  for i, line in ipairs(l.lines) do
    common.draw_text(style.font, fade(c.text, p), line, nil, tx, ty + (i - 1) * lh, 0, lh)
  end
  if #self.queue > 0 then
    local str = string.format("[%d]", #self.queue + 1)
    common.draw_text(style.font, fade(c.focus, p), str, "right", l.x, l.y + style.padding.y, l.w - style.padding.x, style.font:get_height())
  end

  -- buttons: a separator line above them and between them
  renderer.draw_rect(l.x, l.y + l.body_h, l.w, BORDER_WIDTH, fade(c.border, p))
  for i, opt, bx,by,bw,bh in self:each_option() do
    local fx, fy, fw, fh = bx, by + BORDER_WIDTH, bw, bh - BORDER_WIDTH
    if i > 1 then
      renderer.draw_rect(bx, by, BORDER_WIDTH, bh, fade(c.border, p))
      fx, fw = fx + BORDER_WIDTH, fw - BORDER_WIDTH
    end
    if i == self.mouse_item then
      renderer.draw_rect(fx, fy, fw, fh, fade(c.hover, p))
    end
    if i == self.hovered_item then
      local fc = fade(c.focus, p)
      renderer.draw_rect(fx, fy, fw, BORDER_WIDTH, fc)
      renderer.draw_rect(fx, fy + fh - BORDER_WIDTH, fw, BORDER_WIDTH, fc)
      renderer.draw_rect(fx, fy, BORDER_WIDTH, fh, fc)
      renderer.draw_rect(fx + fw - BORDER_WIDTH, fy, BORDER_WIDTH, fh, fc)
    end
    common.draw_text(style.font, fade(c.text, p), i18n.t(opt.text), "center", fx, fy, fw, fh)
  end

  core.pop_clip_rect()
end

function NagView:draw()
  if (not self.visible and self.show_progress <= 0) or not self.title then
    return
  end
  core.root_view:defer_draw(draw_nagview_message, self)
end

function NagView:on_scale_change(new_scale, old_scale)
  BORDER_WIDTH = common.round(1 * new_scale)
end

function NagView:next()
  local opts = table.remove(self.queue, 1) or {}
  if opts.title and opts.message and opts.options then
    self.visible = true
    self.title = i18n.t(opts.title)
    self.message = i18n.t(opts.message)
    self.options = opts.options
    self.on_selected = opts.on_selected
    self.mouse_item = nil
    self:change_hovered(common.find_index(self.options, "default_yes"))

    self.force_focus = true
    core.set_active_view(self)
    -- We add a hook to manage all the mouse_pressed events.
    register_mouse_pressed(self)
  else
    self.force_focus = false
    core.set_active_view(core.next_active_view or core.last_active_view)
    self.visible = false
    unregister_mouse_pressed(self)
  end
end

function NagView:show(title, message, options, on_select)
  local opts = {}
  opts.title = assert(title, "No title")
  opts.message = assert(message, "No message")
  opts.options = assert(options, "No options")
  opts.on_selected = on_select or noop
  table.insert(self.queue, opts)
  self:next()
end

return NagView
