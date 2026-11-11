--!nonstrict
-- Bar button: headphone EQ on (FiiO FT1 EQ sink is default) or off (DAC).
local eq = require("./headphone_eq_lib.luau")

local function render(state)
  barWidget.setVisible(state ~= nil)
  local on = state == "on"
  barWidget.setGlyph(on and "headphones" or "headphones-off")
  barWidget.setTooltip(on and "Headphone EQ on — click for speakers (flat)"
    or "Headphone EQ off — click to equalise for headphones")
end

noctalia.state.watch("headphoneEq", render)
render(noctalia.state.get("headphoneEq"))

function onClick()
  eq.run("toggle")
end
