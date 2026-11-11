--!nonstrict
-- EQ panel: on/off and the preset picker. "Off" plays straight into the DAC.
local eq = require("./headphone_eq_lib.luau")

local function options()
  local list = { "Off" }
  for _, name in ipairs(noctalia.state.get("headphoneEqPresets") or {}) do
    table.insert(list, name)
  end
  return list
end

local function render()
  local state = noctalia.state.get("headphoneEq")
  local on = eq.isOn(state)
  local opts = options()
  local selected = 0
  for i, name in ipairs(opts) do
    if i > 1 and name == state then
      selected = i - 1
    end
  end
  panel.render(ui.column({ gap = 12, padding = 16 }, {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({ name = on and "headphones" or "headphones-off", size = 20,
        color = on and "primary" or "on_surface_variant" }),
      ui.label({ text = "Equalizer", fontSize = 15, fontWeight = "bold", flexGrow = 1 }),
      ui.toggle({ checked = on, enabled = state ~= nil, onChange = function(value)
        eq.run(value == "true" and "on" or "off")
      end }),
    }),
    ui.select({ options = opts, selectedIndex = selected, enabled = state ~= nil,
      onChange = function(index)
        local name = opts[(tonumber(index) or 0) + 1]
        eq.run("set", (name == nil or name == "Off") and "off" or name)
      end }),
    ui.label({
      text = state == nil and "headphone-eq is not available on this host"
        or (on and ("Playing through the " .. state .. " EQ") or "Flat: straight to the DAC"),
      fontSize = 12, color = "on_surface_variant",
    }),
  }))
end

noctalia.state.watch("headphoneEq", render)
noctalia.state.watch("headphoneEqPresets", render)

function onOpen()
  eq.run("status")
  render()
end
