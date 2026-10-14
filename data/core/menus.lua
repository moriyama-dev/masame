-- Menu bar contents, the commands only reachable from menus, and the
-- default key bindings that differ from the inherited ones.
local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local i18n = require "core.i18n"
local MenuBar = require "core.menubar"
local RootView = require "core.rootview"
local DocView = require "core.docview"

local T = i18n.t
local D = MenuBar.DIVIDER
local menubar = core.menu_bar

local function lang_item(lang)
  return {
    text = lang.name,
    command = "core:set-language-" .. lang.id,
    checked = function() return i18n.lang == lang.id end,
  }
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------
local language_commands = {}
for _, lang in ipairs(i18n.languages) do
  language_commands["core:set-language-" .. lang.id] = function()
    i18n.set(lang.id)
    core.redraw = true
  end
end
command.add(nil, language_commands)

command.add(nil, {
  ["core:new-window"] = function()
    system.exec(string.format("%q", EXEFILE))
  end,

  ["core:save-all"] = function()
    for _, doc in ipairs(core.docs) do
      if doc:is_dirty() and doc.filename then
        core.try(doc.save, doc)
      end
    end
  end,

  ["core:about"] = function()
    core.nag_view:show(
      T("About Masame"),
      i18n.f("Masame %s\nA lightweight text editor. MIT License. Based on Lite XL.", VERSION),
      { { text = "OK", default_yes = true, default_no = true } },
      function() end
    )
  end,

  ["core:open-website"] = function()
    system.exec("xdg-open https://github.com/moriyama-dev/masame")
  end,
})

-- Open/save use the system file dialogs; when none can be shown (no portal
-- and no zenity), the original path prompt is used instead.
local filedialog = require "core.filedialog"
local common = require "core.common"

local function use_dialog(name, run)
  local original = command.map[name].perform
  command.map[name].perform = function(...)
    local args = table.pack(...)
    local function fallback(err)
      core.log_quiet("File dialog unavailable: %s", tostring(err))
      original(table.unpack(args, 1, args.n))
    end
    run(fallback, ...)
  end
end

local function active_dir()
  local view = core.active_view
  if view and view.doc and view.doc.abs_filename then
    return common.dirname(view.doc.abs_filename)
  end
  return core.project_dir
end

use_dialog("core:open-file", function(fallback)
  filedialog.open_files(active_dir(), function(paths, err)
    if not paths then return fallback(err) end
    for _, path in ipairs(paths) do
      core.try(function() core.root_view:open_doc(core.open_doc(path)) end)
    end
  end)
end)

use_dialog("core:open-folder", function(fallback)
  filedialog.open_folder(core.project_dir, function(paths, err)
    if not paths then return fallback(err) end
    local path = paths[1]
    if not path or path == core.project_dir then return end
    core.confirm_close_docs(core.docs, function(dirpath)
      core.open_folder_project(dirpath)
    end, path)
  end)
end)

use_dialog("doc:save-as", function(fallback, dv)
  local doc = dv.doc
  local location = doc.abs_filename or (active_dir() .. PATHSEP)
  filedialog.save_file(location, function(paths, err)
    if not paths then return fallback(err) end
    local path = paths[1]
    if not path then return end
    local filename = core.normalize_to_project_dir(path)
    local ok, save_err = pcall(doc.save, doc, filename, core.project_absolute_path(filename))
    if ok then
      core.log("Saved \"%s\"", doc.filename)
    else
      core.error("%s", tostring(save_err))
    end
  end)
end)

command.add("core.docview!", {
  ["doc:sort-lines"] = function(dv)
    local doc = dv.doc
    local line1, _, line2 = doc:get_selection(true)
    if line1 == line2 then line1, line2 = 1, #doc.lines end
    local lines = {}
    for i = line1, line2 do
      lines[#lines + 1] = doc.lines[i]:gsub("\n$", "")
    end
    table.sort(lines)
    doc:remove(line1, 1, line2, math.huge)
    doc:insert(line1, 1, table.concat(lines, "\n"))
    doc:set_selection(line1, 1, line2, math.huge)
  end,
})

command.add(function() return menubar:is_open() end, {
  ["menubar:close"] = function() menubar:close() end,
  ["menubar:next-item"] = function() menubar:move_selection(1) end,
  ["menubar:previous-item"] = function() menubar:move_selection(-1) end,
  ["menubar:next-menu"] = function() menubar:move_menu(1) end,
  ["menubar:previous-menu"] = function() menubar:move_menu(-1) end,
  ["menubar:activate"] = function()
    if menubar.hovered_item then menubar:activate(menubar.hovered_item) end
  end,
})

command.add(function() return menubar.visible and not menubar:is_open() end, {
  ["menubar:open"] = function() menubar:open(1); menubar:move_selection(1) end,
})

command.add(nil, {
  ["menubar:toggle"] = function()
    menubar.visible = not menubar.visible
    menubar:close()
  end,
})

--------------------------------------------------------------------------------
-- Menus
--------------------------------------------------------------------------------
menubar:add_menu("File", {
  { text = "New File", command = "core:new-doc" },
  { text = "New Window", command = "core:new-window" },
  D,
  { text = "Open File...", command = "core:open-file" },
  { text = "Open Folder...", command = "core:open-folder" },
  D,
  { text = "Save", command = "doc:save" },
  { text = "Save As...", command = "doc:save-as" },
  { text = "Save All", command = "core:save-all" },
  D,
  { text = "Reload from Disk", command = "doc:reload" },
  D,
  { text = "Close File", command = "root:close" },
  { text = "Close Other Files", command = "root:close-all-others" },
  { text = "Close All Files", command = "root:close-all" },
  D,
  { text = "Quit", command = "core:quit" },
})

menubar:add_menu("Edit", {
  { text = "Undo", command = "doc:undo" },
  { text = "Redo", command = "doc:redo" },
  D,
  { text = "Cut", command = "doc:cut" },
  { text = "Copy", command = "doc:copy" },
  { text = "Paste", command = "doc:paste" },
  D,
  { text = "Indent", command = "doc:indent" },
  { text = "Unindent", command = "doc:unindent" },
  { text = "Toggle Comment", command = "doc:toggle-line-comments" },
  { text = "Toggle Block Comment", command = "doc:toggle-block-comments" },
  D,
  { text = "Duplicate Line", command = "doc:duplicate-lines" },
  { text = "Delete Line", command = "doc:delete-lines" },
  { text = "Move Line Up", command = "doc:move-lines-up" },
  { text = "Move Line Down", command = "doc:move-lines-down" },
  { text = "Join Lines", command = "doc:join-lines" },
  D,
  { text = "Upper Case", command = "doc:upper-case" },
  { text = "Lower Case", command = "doc:lower-case" },
  { text = "Sort Lines", command = "doc:sort-lines" },
  { text = "Wrap Paragraph", command = "reflow:reflow" },
  { text = "Trim Trailing Whitespace", command = "trim-whitespace:trim-trailing-whitespace" },
})

menubar:add_menu("Selection", {
  { text = "Select All", command = "doc:select-all" },
  { text = "Expand Selection to Line", command = "doc:select-lines" },
  { text = "Expand Selection to Word", command = "doc:select-word" },
  D,
  { text = "Add Next Occurrence", command = "find-replace:select-add-next" },
  { text = "Select All Occurrences", command = "find-replace:select-add-all" },
  D,
  { text = "Add Cursor Above", command = "doc:create-cursor-previous-line" },
  { text = "Add Cursor Below", command = "doc:create-cursor-next-line" },
})

menubar:add_menu("Find", {
  { text = "Find...", command = "find-replace:find" },
  { text = "Find Next", command = "find-replace:repeat-find" },
  { text = "Find Previous", command = "find-replace:previous-find" },
  { text = "Replace...", command = "find-replace:replace" },
  D,
  { text = "Find in Files...", command = "project-search:find" },
})

menubar:add_menu("View", {
  { text = "Side Bar", command = "treeview:toggle" },
  { text = "Toolbar", command = "toolbar:toggle" },
  { text = "Status Bar", command = "status-bar:toggle" },
  { text = "Minimap", command = "minimap:toggle-visibility" },
  { text = "Menu Bar", command = "menubar:toggle" },
  D,
  { text = "Word Wrap", command = "line-wrapping:toggle" },
  { text = "Show Whitespace", command = "draw-whitespace:toggle" },
  { text = "Line Guide", command = "lineguide:toggle" },
  D,
  { text = "Split Right", command = "root:split-right" },
  { text = "Split Down", command = "root:split-down" },
  D,
  { text = "Zoom In", command = "scale:increase" },
  { text = "Zoom Out", command = "scale:decrease" },
  { text = "Reset Zoom", command = "scale:reset" },
  D,
  { text = "Full Screen", command = "core:toggle-fullscreen" },
})

menubar:add_menu("Goto", {
  { text = "Go to File...", command = "core:find-file" },
  { text = "Go to Line...", command = "doc:go-to-line" },
  D,
  { text = "Next File", command = "root:switch-to-next-tab" },
  { text = "Previous File", command = "root:switch-to-previous-tab" },
})

local preferences = {
  { text = "Settings", command = "core:open-user-module" },
  D,
}
for _, lang in ipairs(i18n.languages) do
  table.insert(preferences, lang_item(lang))
end
menubar:add_menu("Preferences", preferences)

menubar:add_menu("Help", {
  { text = "Website", command = "core:open-website" },
  { text = "About Masame", command = "core:about" },
})

--------------------------------------------------------------------------------
-- Event routing: the menu bar sees mouse events before any other view, so
-- clicking it does not take focus away from the document.
--------------------------------------------------------------------------------
local root_on_mouse_pressed = RootView.on_mouse_pressed
function RootView:on_mouse_pressed(button, x, y, clicks)
  if menubar:handle_mouse_pressed(button, x, y) then return true end
  return root_on_mouse_pressed(self, button, x, y, clicks)
end

local root_on_mouse_moved = RootView.on_mouse_moved
function RootView:on_mouse_moved(x, y, dx, dy)
  if menubar:handle_mouse_moved(x, y) then
    self.mouse.x, self.mouse.y = x, y
    return
  end
  return root_on_mouse_moved(self, x, y, dx, dy)
end

--------------------------------------------------------------------------------
-- Key bindings
--------------------------------------------------------------------------------
keymap.add {
  ["escape"] = "menubar:close",
  ["down"] = "menubar:next-item",
  ["up"] = "menubar:previous-item",
  ["right"] = "menubar:next-menu",
  ["left"] = "menubar:previous-menu",
  ["return"] = "menubar:activate",
}

keymap.add({
  ["ctrl+shift+n"] = "core:new-window",
  ["ctrl+q"] = "core:quit",
  ["ctrl+h"] = "find-replace:replace",
  ["ctrl+shift+z"] = "doc:redo",
  ["ctrl+]"] = "doc:indent",
  ["ctrl+["] = "doc:unindent",
  ["ctrl+shift+up"] = "doc:move-lines-up",
  ["ctrl+shift+down"] = "doc:move-lines-down",
  ["alt+shift+up"] = "doc:create-cursor-previous-line",
  ["alt+shift+down"] = "doc:create-cursor-next-line",
  ["alt+f3"] = "find-replace:select-add-all",
  ["ctrl+pageup"] = "root:switch-to-previous-tab",
  ["ctrl+pagedown"] = "root:switch-to-next-tab",
  ["ctrl+shift+pageup"] = "root:move-tab-left",
  ["ctrl+shift+pagedown"] = "root:move-tab-right",
  ["f9"] = "doc:sort-lines",
  ["alt+q"] = "reflow:reflow",
}, true)

keymap.unbind("ctrl+r", "find-replace:replace")

return menubar
