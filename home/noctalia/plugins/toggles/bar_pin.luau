--!nonstrict
-- Toggles the default bar between pinned and smart auto-hide through
-- noctalia-bar-autohide, which writes the settings override.

local function pinned()
  return noctalia.getSetting("bar.default.auto_hide") ~= true
    and noctalia.getSetting("bar.default.smart_auto_hide") ~= true
end

local function render()
  local isPinned = pinned()
  barWidget.setGlyph(isPinned and "pinned" or "pinned-off")
  barWidget.setTooltip(isPinned and "Bar pinned — click to auto-hide" or "Bar auto-hides — click to pin")
end

function update()
  render()
end

function onConfigChanged()
  render()
end

function onClick()
  noctalia.runAsync({ "noctalia-bar-autohide", "toggle" }, function(result)
    if type(result) == "table" and result.exitCode ~= 0 then
      noctalia.notifyError("Bar", "noctalia-bar-autohide failed: " .. tostring(result.stderr))
    end
  end)
end

render()
