-- Start-up check run by .github/workflows/macos-test.yml: proves the app starts and that the
-- Help menu commands build the right URLs, then quits. Loaded as the user module (LITE_USERDIR).
local core = require "core"
local command = require "core.command"

local report_path = os.getenv("MASAME_TEST_REPORT")
local opened = {}
-- Record the URLs instead of opening a browser on the runner
system.exec = function(cmd) table.insert(opened, cmd) end

core.add_thread(function()
  coroutine.yield(2)
  command.perform("core:report-problem")
  command.perform("core:open-website")
  local file = assert(io.open(report_path, "w"))
  file:write("started ", VERSION, " ", PLATFORM, " ", ARCH, "\n")
  for _, cmd in ipairs(opened) do file:write(cmd, "\n") end
  file:close()
  core.quit(true)
end)
