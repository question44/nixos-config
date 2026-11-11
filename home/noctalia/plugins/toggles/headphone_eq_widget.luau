--!nonstrict
-- Bar button beside volume: click opens the EQ panel, right-click turns the
-- EQ on or off.
local eq = require("./headphone_eq_lib.luau")

local function render(state)
  barWidget.setVisible(state ~= nil)
  local on = eq.isOn(state)
  barWidget.setGlyph(on and "headphones" or "headphones-off")
  barWidget.setTooltip(on and ("EQ: " .. state .. " — click for presets, right-click to turn off")
    or "EQ off — click for presets, right-click to turn on")
end

noctalia.state.watch("headphoneEq", render)
render(noctalia.state.get("headphoneEq"))

function onClick()
  noctalia.togglePanel(eq.PANEL)
end

function onRightClick()
  eq.run("toggle")
end
