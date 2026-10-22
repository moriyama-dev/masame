-- mod-version:3
-- Auto save: a file is saved a moment after the last change. New files that
-- have never been saved are left alone, as there is nowhere to save them.
local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local Doc = require "core.doc"
local preferences = require "core.preferences"

config.plugins.autosave = common.merge({
  enabled = preferences.get("auto_save") == true,
  -- seconds to wait after the last change
  delay = 1,
}, config.plugins.autosave)

local autosave = {}

-- docs with changes waiting to be saved, and when they last changed
local pending = setmetatable({}, { __mode = "k" })

local on_text_change = Doc.on_text_change
function Doc:on_text_change(type)
  if config.plugins.autosave.enabled and self.filename then
    pending[self] = system.get_time()
  end
  return on_text_change(self, type)
end

---Saves a doc without asking anything. Returns true when it was saved.
---@param doc core.doc
---@return boolean
function autosave.save(doc)
  pending[doc] = nil
  if not doc.filename or not doc:is_dirty() then return false end
  local ok, err = pcall(doc.save, doc)
  if not ok then
    core.error("Couldn't save file \"%s\": %s", doc.filename, tostring(err))
    return false
  end
  core.redraw = true
  return true
end

---Whether a doc is taken care of by auto save (it has a file to go to).
---@param doc core.doc
function autosave.covers(doc)
  return config.plugins.autosave.enabled and doc.filename ~= nil
end

core.add_thread(function()
  while true do
    local now = system.get_time()
    for doc, time in pairs(pending) do
      if now - time >= config.plugins.autosave.delay then
        autosave.save(doc)
      end
    end
    coroutine.yield(0.2)
  end
end)

command.add(nil, {
  ["auto-save:toggle"] = function()
    local enabled = not config.plugins.autosave.enabled
    config.plugins.autosave.enabled = enabled
    if enabled then
      -- files already changed are saved right away
      for _, doc in ipairs(core.docs) do
        if doc.filename and doc:is_dirty() then autosave.save(doc) end
      end
    else
      for doc in pairs(pending) do pending[doc] = nil end
    end
  end,
})

return autosave
