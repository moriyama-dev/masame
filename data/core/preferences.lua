-- Choices made from the menus (word wrap, zoom, auto save, which bars are
-- shown, ...) are remembered across restarts in USERDIR/preferences.lua.
local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"

local preferences = {}

local values

local function filename()
  return USERDIR .. PATHSEP .. "preferences.lua"
end

local function load()
  if values then return end
  local ok, t = pcall(dofile, filename())
  values = ok and type(t) == "table" and t or {}
end

local function save()
  local path = filename()
  local fp = io.open(path .. ".tmp", "w")
  if not fp then return end
  fp:write("return ", common.serialize(values, { pretty = true, sort = true }), "\n")
  fp:close()
  os.remove(path)
  os.rename(path .. ".tmp", path)
end

---@param key string
---@return any
function preferences.get(key)
  load()
  return values[key]
end

---@param key string
---@param value any
function preferences.set(key, value)
  load()
  if values[key] == value then return end
  values[key] = value
  save()
end

-- On/off choices that are changed with a toggle command. After the command
-- runs, `get` tells the new state, which is stored under `key`.
preferences.toggles = {
  { key = "word_wrap", command = "line-wrapping:toggle",
    get = function() return config.plugins.linewrapping.enable_by_default end },
  { key = "show_whitespace", command = "draw-whitespace:toggle",
    get = function() return config.plugins.drawwhitespace.enabled end },
  { key = "line_guide", command = "lineguide:toggle",
    get = function() return config.plugins.lineguide.enabled end },
  { key = "minimap", command = "minimap:toggle-visibility",
    get = function() return config.plugins.minimap.enabled end },
  { key = "toolbar", command = "toolbar:toggle",
    get = function()
      local treeview = package.loaded["plugins.treeview"]
      return treeview and treeview.toolbar and treeview.toolbar.visible
    end },
  { key = "status_bar", command = "status-bar:toggle",
    get = function() return core.status_view.visible end },
  { key = "menu_bar", command = "menubar:toggle",
    get = function() return core.menu_bar.visible end },
  { key = "fullscreen", command = "core:toggle-fullscreen",
    get = function() return core.fullscreen end },
  { key = "auto_save", command = "auto-save:toggle",
    get = function() return config.plugins.autosave.enabled end },
}

---Returns the current state of a toggle, or nil when its plugin is missing.
function preferences.state(key)
  for _, t in ipairs(preferences.toggles) do
    if t.key == key then
      local ok, value = pcall(t.get)
      if ok and value ~= nil then return not not value end
    end
  end
end

---Called once the plugins are loaded: records each toggle when its command
---runs, and brings back the states chosen last time.
function preferences.init()
  load()
  local restore = {}
  for _, t in ipairs(preferences.toggles) do
    local cmd = command.map[t.command]
    if cmd then
      local perform = cmd.perform
      cmd.perform = function(...)
        local res = perform(...)
        local state = preferences.state(t.key)
        if state ~= nil then preferences.set(t.key, state) end
        return res
      end
      local saved = values[t.key]
      if type(saved) == "boolean" and saved ~= preferences.state(t.key) then
        table.insert(restore, t.command)
      end
    end
  end
  -- run in a thread so that the window and the views are fully set up
  core.add_thread(function()
    for _, name in ipairs(restore) do
      command.perform(name)
    end
  end)
end

return preferences
