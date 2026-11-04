--!nonstrict
-- Tile in the control center that opens the Wallpaper Engine picker.

local function render()
  shortcut.setLabel(noctalia.tr("title"))
  shortcut.setIcon("wallpaper")
end

render()

function onClick()
  noctalia.togglePanel("janzon/wallpaper-engine:picker")
end
