-- The menu bar at the top of the window, with drop-down menus.
local core = require "core"
local common = require "core.common"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "core.style"
local i18n = require "core.i18n"
local View = require "core.view"

local T = i18n.t

local DIVIDER = {}

---@class core.menubar : core.view
local MenuBar = View:extend()

MenuBar.DIVIDER = DIVIDER

function MenuBar:__tostring() return "MenuBar" end

function MenuBar:new()
  MenuBar.super.new(self)
  self.visible = true
  self.menus = {}
  self.open_index = nil
  self.hovered_title = nil
  self.hovered_item = nil
end

---Adds a menu. Items are { text = string, command = string|function,
---checked = function?, enabled = function? } or MenuBar.DIVIDER.
---@param title string
---@param items table[]
function MenuBar:add_menu(title, items)
  table.insert(self.menus, { title = title, items = items })
end

---Returns a menu by its (English) title.
function MenuBar:get_menu(title)
  for _, menu in ipairs(self.menus) do
    if menu.title == title then return menu end
  end
end

function MenuBar:get_name() return nil end

function MenuBar:bar_height()
  return self.visible and (style.font:get_height() + style.padding.y * 2) or 0
end

function MenuBar:update()
  self.size.y = self:bar_height()
  MenuBar.super.update(self)
end

local function title_padding() return style.padding.x end

---Iterates over the menu titles: index, menu, x, y, w, h.
function MenuBar:each_title()
  local x, y, h = self.position.x + style.padding.x / 2, self.position.y, self.size.y
  return coroutine.wrap(function()
    for i, menu in ipairs(self.menus) do
      local w = style.font:get_width(T(menu.title)) + title_padding() * 2
      coroutine.yield(i, menu, x, y, w, h)
      x = x + w
    end
  end)
end

local function item_enabled(item)
  if item.enabled then return item.enabled() end
  if type(item.command) == "string" then return command.is_valid(item.command) end
  return true
end

-- Shortcuts shown in menus: prefer the usual keys over legacy ones such as
-- ctrl+insert, and write them like "Ctrl+Shift+D".
local function format_binding(stroke)
  return (stroke:gsub("[^+]+", function(part)
    if #part == 1 then return part:upper() end
    return part:sub(1, 1):upper() .. part:sub(2)
  end))
end

local function item_binding(item)
  if type(item.command) ~= "string" then return end
  local best
  for _, stroke in ipairs(keymap.get_bindings(item.command) or {}) do
    if not stroke:find("insert") and not stroke:find("click") and not stroke:find("wheel") then
      if not best or #stroke < #best then best = stroke end
    end
  end
  return best and format_binding(best)
end

local function check_width() return style.font:get_width("✓") + style.padding.x end

---Returns the drop-down rectangle for the open menu.
function MenuBar:dropdown_rect()
  local menu = self.menus[self.open_index]
  if not menu then return end
  local tx
  for i, _, x in self:each_title() do
    if i == self.open_index then tx = x end
  end
  local item_h = style.font:get_height() + style.padding.y
  local w, h = 0, style.padding.y
  for _, item in ipairs(menu.items) do
    if item == DIVIDER then
      h = h + style.padding.y
    else
      local lw = style.font:get_width(T(item.text))
      local binding = item_binding(item)
      if binding then lw = lw + style.padding.x * 3 + style.font:get_width(binding) end
      w = math.max(w, lw)
      h = h + item_h
    end
  end
  w = w + check_width() + style.padding.x * 2
  h = h + style.padding.y
  local x = common.clamp(tx, 0, math.max(0, core.root_view.size.x - w))
  return x, self.position.y + self.size.y, w, h
end

---Iterates over the open menu's items: index, item, x, y, w, h.
function MenuBar:each_item()
  local menu = self.menus[self.open_index]
  local x, y, w = self:dropdown_rect()
  local item_h = style.font:get_height() + style.padding.y
  y = y + style.padding.y
  return coroutine.wrap(function()
    for i, item in ipairs(menu.items) do
      local h = item == DIVIDER and style.padding.y or item_h
      coroutine.yield(i, item, x, y, w, h)
      y = y + h
    end
  end)
end

function MenuBar:is_open()
  return self.open_index ~= nil
end

function MenuBar:open(index)
  self.open_index = index
  self.hovered_item = nil
  core.request_cursor("arrow")
end

function MenuBar:close()
  self.open_index = nil
  self.hovered_item = nil
end

function MenuBar:title_at(px, py)
  if not self.visible then return end
  for i, _, x, y, w, h in self:each_title() do
    if px >= x and px < x + w and py >= y and py < y + h then return i end
  end
end

function MenuBar:item_at(px, py)
  if not self:is_open() then return end
  for i, item, x, y, w, h in self:each_item() do
    if item ~= DIVIDER and px >= x and px < x + w and py >= y and py < y + h then
      return i
    end
  end
end

function MenuBar:dropdown_contains(px, py)
  if not self:is_open() then return false end
  local x, y, w, h = self:dropdown_rect()
  return px >= x and px < x + w and py >= y and py < y + h
end

function MenuBar:bar_contains(px, py)
  return self.visible and py >= self.position.y and py < self.position.y + self.size.y
end

function MenuBar:activate(index)
  local item = self.menus[self.open_index].items[index]
  if not item or item == DIVIDER or not item_enabled(item) then return end
  self:close()
  if type(item.command) == "string" then
    command.perform(item.command)
  else
    item.command()
  end
end

---Handles a mouse press anywhere in the window. Returns true if consumed.
function MenuBar:handle_mouse_pressed(button, px, py)
  local title = self:title_at(px, py)
  if title then
    if self.open_index == title then self:close() else self:open(title) end
    return true
  end
  if self:is_open() then
    local index = self:item_at(px, py)
    if index and button == "left" then
      self:activate(index)
    elseif not self:dropdown_contains(px, py) then
      self:close()
    end
    return true
  end
  return self:bar_contains(px, py)
end

---Handles mouse movement anywhere in the window. Returns true if consumed.
function MenuBar:handle_mouse_moved(px, py)
  self.hovered_title = self:title_at(px, py)
  if self:is_open() then
    if self.hovered_title and self.hovered_title ~= self.open_index then
      self:open(self.hovered_title)
    end
    self.hovered_item = self:item_at(px, py)
    core.request_cursor("arrow")
    return true
  end
  if self:bar_contains(px, py) then
    core.request_cursor("arrow")
    return true
  end
  return false
end

function MenuBar:move_selection(dir)
  local items = self.menus[self.open_index].items
  local n = #items
  local i = self.hovered_item or (dir > 0 and 0 or n + 1)
  for _ = 1, n do
    i = (i + dir - 1) % n + 1
    if items[i] ~= DIVIDER and item_enabled(items[i]) then
      self.hovered_item = i
      return
    end
  end
end

function MenuBar:move_menu(dir)
  local n = #self.menus
  self:open((self.open_index + dir - 1) % n + 1)
end

function MenuBar:draw()
  if not self.visible then return end
  self:draw_background(style.background2)
  for i, menu, x, y, w, h in self:each_title() do
    if i == self.open_index or (i == self.hovered_title and not self:is_open()) then
      renderer.draw_rect(x, y, w, h, i == self.open_index and style.selection or style.line_highlight)
    end
    common.draw_text(style.font, style.text, T(menu.title), "center", x, y, w, h)
  end
  renderer.draw_rect(self.position.x, self.position.y + self.size.y - 1, self.size.x, 1, style.divider)
  if self:is_open() then
    core.root_view:defer_draw(self.draw_dropdown, self)
  end
end

function MenuBar:draw_dropdown()
  if not self:is_open() then return end
  local bx, by, bw, bh = self:dropdown_rect()
  local border = math.max(1, SCALE)
  renderer.draw_rect(bx - border, by - border, bw + border * 2, bh + border * 2, style.divider)
  renderer.draw_rect(bx, by, bw, bh, style.background3)
  local cw = check_width()
  for i, item, x, y, w, h in self:each_item() do
    if item == DIVIDER then
      renderer.draw_rect(x + style.padding.x / 2, y + h / 2, w - style.padding.x, border, style.divider)
    else
      local enabled = item_enabled(item)
      if i == self.hovered_item and enabled then
        renderer.draw_rect(x, y, w, h, style.selection)
      end
      local color = enabled and style.text or style.dim
      if item.checked and item.checked() then
        common.draw_text(style.font, style.accent, "✓", "left", x + style.padding.x, y, cw, h)
      end
      common.draw_text(style.font, color, T(item.text), "left", x + style.padding.x + cw, y, w, h)
      local binding = item_binding(item)
      if binding then
        common.draw_text(style.font, style.dim, binding, "right", x, y, w - style.padding.x, h)
      end
    end
  end
end

return MenuBar
