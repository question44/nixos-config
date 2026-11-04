--!nonstrict
-- Bar widget that opens the Wallpaper Engine picker.

local glyph = noctalia.getConfig("glyph")

local function render()
  barWidget.setGlyph(glyph)
  barWidget.setTooltip(noctalia.tr("title"))
end

function update()
  render()
end

function onClick()
  noctalia.togglePanel("janzon/wallpaper-engine:picker")
end

render()
