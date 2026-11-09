--!nonstrict
-- Toggles [wallpaper.sequoia] desktop_motion between "still" and "animated".
-- Hidden when Noctalia lacks the Sequoia patch (no such setting).

local KEY = "wallpaper.sequoia.desktop_motion"

local function render()
  local motion = noctalia.getSetting(KEY)
  barWidget.setVisible(motion ~= nil)
  local animated = motion == "animated"
  barWidget.setGlyph(animated and "wave-sine" or "photo")
  barWidget.setTooltip(animated and "Wallpaper animated — click to keep it still"
    or "Wallpaper still — click to animate")
end

function update()
  render()
end

function onConfigChanged()
  render()
end

function onClick()
  local nextValue = noctalia.getSetting(KEY) == "animated" and "still" or "animated"
  noctalia.runAsync({ "noctalia", "msg", "config-set", KEY, '"' .. nextValue .. '"' }, function(result)
    if type(result) == "table" and result.exitCode ~= 0 then
      noctalia.notifyError("Sequoia wallpaper", "config-set failed: " .. tostring(result.stderr))
    end
  end)
end

render()
