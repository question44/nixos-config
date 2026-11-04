--!nonstrict
-- Wallpaper Engine picker.
-- Lists the Steam Workshop items for Wallpaper Engine that linux-wallpaperengine
-- can render (scenes and videos; web wallpapers and presets are skipped), with
-- a search box, a type filter and an output selector. Choices go to the headless
-- service through the shared "command" state channel.

local PANEL_WIDTH = 920
local PANEL_PADDING = 28
local COLUMNS = 4
local COLUMN_GAP = 12
local PAGE_SIZE = 24
local TILE_RADIUS = 12
local DEFAULT_WORKSHOP_DIR = "~/.local/share/Steam/steamapps/workshop/content/431960"
local SUPPORTED_TYPES = { scene = true, video = true }
local PREVIEW_FILES = { "preview.jpg", "preview.png", "preview.jpeg", "preview.gif" }

local closeButton = true
local items = {}        -- { { id=, title=, kind=, preview= }, ... } sorted by title
local filtered = {}
local page = 1
local query = ""
local kindIndex = 0     -- 0 = all, 1 = scenes, 2 = videos
local outputsList = {}
local selectedConnectorName = "" -- empty = all outputs
local errorMessage = ""
local cmdNonce = 0

local render

local function tr(key)
  return noctalia.tr(key)
end

local function workshopDirectory()
  local dir = noctalia.getConfig("workshop_directory")
  if type(dir) ~= "string" or dir == "" then dir = DEFAULT_WORKSHOP_DIR end
  return noctalia.expandPath(dir)
end

-- ── State ──────────────────────────────────────────────────────────────────

local function assignmentFor(connector)
  local assignments = noctalia.state.get("assignments")
  if type(assignments) == "table" then return assignments[connector] end
  return nil
end

local function hasAnyAssignment()
  local assignments = noctalia.state.get("assignments")
  return type(assignments) == "table" and next(assignments) ~= nil
end

local function sendCommand(action, connector, id)
  cmdNonce += 1
  noctalia.state.set("command", { action = action, connector = connector, id = id, nonce = cmdNonce })
end

local function isAssignedToSelection(id)
  if selectedConnectorName == "" then
    local assignments = noctalia.state.get("assignments")
    if type(assignments) ~= "table" then return false end
    for _, v in pairs(assignments) do
      if v == id then return true end
    end
    return false
  end
  return (assignmentFor(selectedConnectorName) or assignmentFor("*")) == id
end

-- ── Loading ────────────────────────────────────────────────────────────────

local function previewFor(dir)
  for _, file in ipairs(PREVIEW_FILES) do
    local path = dir .. "/" .. file
    if noctalia.fileExists(path) then return path end
  end
  return nil
end

local function applyFilter()
  filtered = {}
  local needle = query:lower()
  for _, item in ipairs(items) do
    local kindOk = kindIndex == 0 or (kindIndex == 1 and item.kind == "scene") or (kindIndex == 2 and item.kind == "video")
    local textOk = needle == "" or item.title:lower():find(needle, 1, true) ~= nil or item.id:find(needle, 1, true) ~= nil
    if kindOk and textOk then table.insert(filtered, item) end
  end
  page = 1
end

local function loadItems()
  items = {}
  errorMessage = ""
  local root = workshopDirectory()
  local entries = noctalia.listDir(root)
  if type(entries) ~= "table" then
    errorMessage = tr("no_workshop")
    applyFilter()
    return
  end
  for _, id in ipairs(entries) do
    if id:match("^%d+$") then
      local dir = root .. "/" .. id
      local content = noctalia.readFile(dir .. "/project.json")
      local project = type(content) == "string" and noctalia.json.decode(content) or nil
      if type(project) == "table" and type(project.type) == "string" then
        local kind = project.type:lower()
        if SUPPORTED_TYPES[kind] then
          table.insert(items, {
            id = id,
            title = type(project.title) == "string" and project.title ~= "" and project.title or id,
            kind = kind,
            preview = previewFor(dir),
          })
        end
      end
    end
  end
  table.sort(items, function(a, b) return a.title:lower() < b.title:lower() end)
  applyFilter()
end

local function refreshOutputs()
  outputsList = noctalia.outputs() or {}
  if selectedConnectorName == "" then return end
  for _, output in ipairs(outputsList) do
    if output.name == selectedConnectorName then return end
  end
  selectedConnectorName = ""
end

-- ── Rendering ──────────────────────────────────────────────────────────────

local function totalPages()
  return math.max(1, math.ceil(#filtered / PAGE_SIZE))
end

local function outputOptions()
  local options = { tr("all_outputs") }
  for _, output in ipairs(outputsList) do table.insert(options, output.name) end
  return options
end

local function selectedOutputIndex()
  for i, output in ipairs(outputsList) do
    if output.name == selectedConnectorName then return i end
  end
  return 0
end

local function tileSize()
  local width = math.floor(((PANEL_WIDTH - PANEL_PADDING) - COLUMN_GAP * (COLUMNS - 1)) / COLUMNS)
  return width, math.floor(width * 9 / 16)
end

local function itemTile(item)
  local frameWidth, frameHeight = tileSize()
  local selected = isAssignedToSelection(item.id)
  local onClick = function()
    sendCommand("set", selectedConnectorName == "" and "*" or selectedConnectorName, item.id)
    render()
  end
  local tooltip = item.title .. " · " .. tr("kind_" .. item.kind)

  local preview
  if item.preview ~= nil then
    preview = ui.image({
      width = frameWidth,
      height = frameHeight,
      path = item.preview,
      fit = "cover",
      radius = TILE_RADIUS,
      border = selected and "primary" or "outline_variant",
      borderWidth = selected and 3 or 1,
      tooltip = tooltip,
      onClick = onClick,
    })
  else
    preview = ui.box({
      width = frameWidth,
      height = frameHeight,
      fill = "surface_container",
      radius = TILE_RADIUS,
      border = selected and "primary" or "outline_variant",
      borderWidth = selected and 3 or 1,
      tooltip = tooltip,
      onClick = onClick,
    })
  end

  return ui.column({ gap = 4, key = item.id, flexGrow = 1, align = "center" }, {
    preview,
    ui.row({ gap = 4, align = "center" }, {
      ui.glyph({ name = item.kind == "video" and "movie" or "sparkles", size = 12, color = selected and "primary" or "on_surface_variant" }),
      ui.label({
        text = item.title,
        fontSize = 11,
        color = selected and "primary" or "on_surface_variant",
        maxLines = 1,
        maxWidth = frameWidth - 18,
      }),
    }),
  })
end

local function itemGrid()
  if #filtered == 0 then
    local text = errorMessage ~= "" and errorMessage or (#items == 0 and tr("empty") or tr("no_match"))
    return ui.label({ text = text, color = "on_surface_variant" })
  end
  local first = (page - 1) * PAGE_SIZE + 1
  local last = math.min(first + PAGE_SIZE - 1, #filtered)
  local rows, row = {}, {}
  for i = first, last do
    table.insert(row, itemTile(filtered[i]))
    if #row == COLUMNS or i == last then
      -- Pad the last row so tiles keep their width.
      while #row < COLUMNS do table.insert(row, ui.spacer({ flexGrow = 1 })) end
      table.insert(rows, ui.row({ gap = COLUMN_GAP, align = "stretch" }, row))
      row = {}
    end
  end
  return ui.column({ gap = 12, align = "stretch" }, rows)
end

render = function()
  refreshOutputs()

  if noctalia.state.get("available") == false then
    panel.render(ui.column({ flexGrow = 1, gap = 12, align = "center", justify = "center" }, {
      ui.glyph({ name = "wallpaper", size = 48, color = "on_surface_variant" }),
      ui.label({ text = tr("not_installed"), color = "error", textAlign = "center" }),
    }))
    return
  end

  local paused = noctalia.state.get("paused") == true
  local active = hasAnyAssignment()

  local header = {
    ui.label({ text = tr("title"), fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
    ui.label({ text = `{#filtered} / {#items}`, fontSize = 12, color = "on_surface_variant" }),
  }
  if closeButton then table.insert(header, ui.button({ glyph = "close", onClick = "onClose" })) end

  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", justify = "space_between", gap = 8 }, header),
    ui.row({ gap = 8, align = "center" }, {
      ui.input({ key = "search", value = query, placeholder = tr("search"), onChange = "onSearch", flexGrow = 1 }),
      ui.select({
        key = "kind",
        options = { tr("kind_all"), tr("kind_scene"), tr("kind_video") },
        selectedIndex = kindIndex,
        onChange = "onKindChange",
        width = 140,
      }),
    }),
    ui.row({ gap = 8, align = "center" }, {
      ui.label({ text = tr("output"), fontSize = 12, color = "on_surface_variant" }),
      ui.select({ key = "output", options = outputOptions(), selectedIndex = selectedOutputIndex(), onChange = "onOutputChange", flexGrow = 1 }),
      ui.button({
        text = paused and tr("resume") or tr("pause"),
        glyph = paused and "player-play" or "player-pause",
        variant = "outline",
        onClick = "onToggle",
        enabled = active,
      }),
      ui.button({ text = tr("stop"), glyph = "player-stop", variant = "outline", onClick = "onStop", enabled = active }),
    }),
    ui.scroll({ flexGrow = 1, gap = 12 }, { itemGrid() }),
    ui.row({ align = "center", justify = "space_between", gap = 8 }, {
      ui.button({ glyph = "chevron-left", variant = "ghost", onClick = "onPrevPage", enabled = page > 1 }),
      ui.label({ text = `{page} / {totalPages()}`, color = "on_surface_variant" }),
      ui.button({ glyph = "chevron-right", variant = "ghost", onClick = "onNextPage", enabled = page < totalPages() }),
    }),
  }))
end

-- ── Callbacks ──────────────────────────────────────────────────────────────

function onOpen(_context)
  closeButton = noctalia.getSetting("shell.show_close_buttons") ~= false
  refreshOutputs()
  loadItems()
  render()
end

function onSearch(text)
  query = tostring(text or "")
  applyFilter()
  render()
end

function onKindChange(index, _label)
  kindIndex = tonumber(index) or 0
  applyFilter()
  render()
end

function onOutputChange(index, label)
  if tonumber(index) == 0 then
    selectedConnectorName = ""
  elseif type(label) == "string" and label ~= "" then
    selectedConnectorName = label
  end
  render()
end

function onStop()
  sendCommand("clear", selectedConnectorName == "" and "*" or selectedConnectorName, nil)
  render()
end

function onToggle()
  sendCommand("toggle", nil, nil)
  render()
end

function onPrevPage()
  if page > 1 then
    page -= 1
    render()
  end
end

function onNextPage()
  if page < totalPages() then
    page += 1
    render()
  end
end

function onClose()
  panel.close()
end

noctalia.state.watch("assignments", function(_) render() end)
noctalia.state.watch("paused", function(_) render() end)
noctalia.state.watch("available", function(_) render() end)
