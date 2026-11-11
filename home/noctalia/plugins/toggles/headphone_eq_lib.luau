--!nonstrict
-- Shared by the headphone EQ service, bar widget and control-center tile.
-- State "headphoneEq" is "on", "off" or nil (no headphone-eq command, i.e.
-- my.headphoneEq is off on this host).

local M = {}

M.CMD = "/run/current-system/sw/bin/headphone-eq"

-- Runs `headphone-eq <arg>` and publishes the state it prints.
function M.run(arg)
  noctalia.runAsync({ M.CMD, arg }, function(result)
    if type(result) ~= "table" or result.exitCode ~= 0 then
      if arg ~= "status" then
        noctalia.notifyError("Headphone EQ", "headphone-eq " .. arg .. " failed: "
          .. tostring(type(result) == "table" and result.stderr or result))
      end
      noctalia.state.set("headphoneEq", nil)
      return
    end
    local out = noctalia.string.trim(tostring(result.stdout))
    noctalia.state.set("headphoneEq", (out == "on" or out == "off") and out or nil)
  end)
end

return M
