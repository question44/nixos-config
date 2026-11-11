--!nonstrict
-- Polls the default sink so the tile and widget follow output changes made
-- elsewhere (Noctalia's audio panel, wpctl).
local eq = require("./headphone_eq_lib.luau")

noctalia.setUpdateInterval(2000)

function update()
  eq.run("status")
end

eq.run("status")
