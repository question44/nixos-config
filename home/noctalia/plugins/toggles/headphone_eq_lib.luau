--!nonstrict
-- Shared by the headphone EQ service, panel, bar widget and control-center
-- tile. State "headphoneEq" is the active preset's name, "off", or nil (no
-- headphone-eq command: my.headphoneEq is off on this host). State
-- "headphoneEqPresets" lists the preset names.

local M = {}

M.CMD = "/run/current-system/sw/bin/headphone-eq"
M.PANEL = "janzon/toggles:eq"

local function failed(result)
  return type(result) ~= "table" or result.exitCode ~= 0
end

local function report(what, result)
  noctalia.notifyError("Headphone EQ", "headphone-eq " .. what .. " failed: "
    .. tostring(type(result) == "table" and result.stderr or result))
end

-- Runs `headphone-eq <args...>` and publishes the state it prints.
function M.run(...)
  local args = { M.CMD, ... }
  local what = table.concat({ ... }, " ")
  noctalia.runAsync(args, function(result)
    if failed(result) then
      if what ~= "status" then
        report(what, result)
      end
      noctalia.state.set("headphoneEq", nil)
      return
    end
    local out = noctalia.string.trim(tostring(result.stdout))
    noctalia.state.set("headphoneEq", out ~= "" and out or nil)
  end)
end

function M.loadPresets()
  noctalia.runAsync({ M.CMD, "list" }, function(result)
    if failed(result) then
      return
    end
    local presets = {}
    for line in string.gmatch(tostring(result.stdout), "[^\n]+") do
      local name = noctalia.string.trim(line)
      if name ~= "" then
        table.insert(presets, name)
      end
    end
    noctalia.state.set("headphoneEqPresets", presets)
  end)
end

function M.isOn(state)
  return state ~= nil and state ~= "off"
end

return M
