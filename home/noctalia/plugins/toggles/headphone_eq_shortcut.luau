--!nonstrict
-- Control-center tile: headphone EQ on (FiiO FT1 EQ sink is default) or off.
local eq = require("./headphone_eq_lib.luau")

local function render(state)
  shortcut.setEnabled(state ~= nil)
  shortcut.setLabel("Headphone EQ")
  shortcut.setIcon("headphones", "headphones-off")
  shortcut.setActive(state == "on")
end

noctalia.state.watch("headphoneEq", render)
render(noctalia.state.get("headphoneEq"))

function onClick()
  eq.run("toggle")
end
