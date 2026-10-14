-- Native file dialogs (through SDL: the desktop portal, or zenity).
-- Each function calls on_done(paths) with the chosen paths, or
-- on_done(nil, err) when no dialog could be shown. A cancelled dialog gives
-- an empty list.
local filedialog = {}

local pending = {}

local function show(kind, location, allow_many, on_done)
  local ok, id = pcall(system.show_file_dialog, kind, location, allow_many)
  if not ok then
    on_done(nil, id)
    return
  end
  pending[id] = on_done
end

function filedialog.open_files(location, on_done)
  show("openfile", location, true, on_done)
end

function filedialog.open_folder(location, on_done)
  show("openfolder", location, false, on_done)
end

function filedialog.save_file(location, on_done)
  show("savefile", location, false, on_done)
end

---Called from core.on_event for "dialogfinished" events.
function filedialog.on_finished(id, paths, err)
  local on_done = pending[id]
  pending[id] = nil
  if on_done then on_done(paths, err) end
end

return filedialog
