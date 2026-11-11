--!nonstrict
-- Control-center tile: click opens the EQ panel, right-click turns the EQ on
-- or off.
local eq = require("./headphone_eq_lib.luau")

local function render(state)
  shortcut.setEnabled(state ~= nil)
  shortcut.setLabel("EQ")
  shortcut.setIcon("headphones", "headphones-off")
  shortcut.setActive(eq.isOn(state))
end

noctalia.state.watch("headphoneEq", render)
render(noctalia.state.get("headphoneEq"))

function onClick()
  noctalia.togglePanel(eq.PANEL)
end

function onRightClick()
  eq.run("toggle")
end
