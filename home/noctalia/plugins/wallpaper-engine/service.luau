--!nonstrict
-- Wallpaper Engine - headless service.
-- Keeps the per-output assignments (connector -> Workshop item id, "*" for every
-- output) and runs a single linux-wallpaperengine process that renders all of
-- them. The process lives in a transient systemd user unit so it can be stopped,
-- frozen and inspected (journalctl --user -u noctalia-wallpaper-engine) without
-- matching command lines. Plugin scripts have no `require`, so helpers shared
-- with the panel are duplicated there.

noctalia.setUpdateInterval(5000)

local UNIT = "noctalia-wallpaper-engine"
local STATE_DIR = (noctalia.getenv("XDG_STATE_HOME") or ((noctalia.getenv("HOME") or "") .. "/.local/state")) .. "/noctalia/wallpaper-engine"
local STATE_FILE = STATE_DIR .. "/assignments.json"
local DEFAULT_WORKSHOP_DIR = "~/.local/share/Steam/steamapps/workshop/content/431960"

local assignments = {}  -- connector -> Workshop item id ("*" = every output)
local paused = false
local running = false   -- whether we expect the unit to be active
local binary = nil      -- absolute path of linux-wallpaperengine, nil if missing
local launchGeneration = 0

local function cfg(key)
  return noctalia.getConfig(key)
end

local function workshopDirectory()
  local dir = cfg("workshop_directory")
  if type(dir) ~= "string" or dir == "" then dir = DEFAULT_WORKSHOP_DIR end
  return noctalia.expandPath(dir)
end

-- ── State ──────────────────────────────────────────────────────────────────

local function persist()
  noctalia.writeFile(STATE_FILE, noctalia.json.encode({ assignments = assignments }) or "")
end

local function loadAssignments()
  local content = noctalia.readFile(STATE_FILE)
  if type(content) ~= "string" or content == "" then return end
  local decoded = noctalia.json.decode(content)
  if type(decoded) == "table" and type(decoded.assignments) == "table" then
    assignments = decoded.assignments
  end
end

local function publish()
  noctalia.state.set("assignments", assignments)
  noctalia.state.set("available", binary ~= nil)
  noctalia.state.set("paused", paused)
end

-- ── Outputs ────────────────────────────────────────────────────────────────

local function presentOutputs()
  local names = {}
  for _, output in ipairs(noctalia.outputs()) do
    table.insert(names, output.name)
  end
  return names
end

-- Resolves assignments to the outputs that exist right now: a specific
-- assignment wins over the "*" one.
local function effectiveAssignments()
  local result = {}
  for _, name in ipairs(presentOutputs()) do
    local id = assignments[name] or assignments["*"]
    if id ~= nil then result[name] = id end
  end
  return result
end

local function setHostWallpapers(effective)
  for _, name in ipairs(presentOutputs()) do
    noctalia.setWallpaperEnabled(name, effective[name] == nil)
  end
end

local function restoreHostWallpapers()
  for _, name in ipairs(presentOutputs()) do
    noctalia.setWallpaperEnabled(name, true)
  end
end

-- Points Noctalia's own wallpaper (and so the generated palette) at the item's
-- preview image. GIF previews are skipped; the host shows only their first frame.
local function matchTheme(effective)
  if not cfg("match_theme") then return end
  local dir = workshopDirectory()
  for name, id in pairs(effective) do
    for _, file in ipairs({ "preview.jpg", "preview.png", "preview.jpeg" }) do
      local path = dir .. "/" .. id .. "/" .. file
      if noctalia.fileExists(path) then
        noctalia.setWallpaper(name, path)
        break
      end
    end
  end
end

-- ── Process ────────────────────────────────────────────────────────────────

local function stopUnit(callback)
  -- A frozen unit ignores SIGTERM, so thaw it first; both are no-ops otherwise.
  noctalia.runAsync({ "sh", "-c", "systemctl --user thaw " .. UNIT .. " 2>/dev/null; systemctl --user stop " .. UNIT .. " 2>/dev/null; systemctl --user reset-failed " .. UNIT .. " 2>/dev/null; true" }, function()
    if callback then callback() end
  end)
end

local function buildArgv(effective)
  local argv = {
    "systemd-run", "--user", "--unit=" .. UNIT, "--collect", "--quiet",
    "--setenv=WAYLAND_DISPLAY=" .. (noctalia.getenv("WAYLAND_DISPLAY") or "wayland-0"),
    "--", binary,
  }
  local fps = cfg("fps")
  if type(fps) == "number" and fps > 0 then
    table.insert(argv, "--fps")
    table.insert(argv, tostring(math.floor(fps)))
  end
  if cfg("mute") then table.insert(argv, "--silent") end
  if not cfg("fullscreen_pause") then table.insert(argv, "--no-fullscreen-pause") end
  if not cfg("mouse") then table.insert(argv, "--disable-mouse") end

  local extra = cfg("extra_args")
  if type(extra) == "string" then
    for word in extra:gmatch("%S+") do table.insert(argv, word) end
  end

  local scaling = cfg("scaling")
  local names = {}
  for name in pairs(effective) do table.insert(names, name) end
  table.sort(names)
  for _, name in ipairs(names) do
    table.insert(argv, "--screen-root")
    table.insert(argv, name)
    table.insert(argv, "--bg")
    table.insert(argv, workshopDirectory() .. "/" .. effective[name])
    if type(scaling) == "string" and scaling ~= "" then
      table.insert(argv, "--scaling")
      table.insert(argv, scaling)
    end
  end
  return argv
end

-- Restarts the process for the current assignments. Rapid consecutive calls
-- (clicking several tiles) collapse into the last one via the generation counter.
local function apply()
  launchGeneration += 1
  local generation = launchGeneration
  local effective = effectiveAssignments()
  paused = false

  stopUnit(function()
    if generation ~= launchGeneration then return end
    if binary == nil or next(effective) == nil then
      running = false
      restoreHostWallpapers()
      publish()
      return
    end

    matchTheme(effective)
    running = true
    noctalia.runAsync(buildArgv(effective), function(result)
      if generation ~= launchGeneration then return end
      if type(result) == "table" and result.exitCode ~= 0 then
        running = false
        restoreHostWallpapers()
        noctalia.notifyError("Wallpaper Engine", "Failed to start linux-wallpaperengine: " .. tostring(result.stderr))
        publish()
        return
      end
      -- Give the first frame a moment before revealing it.
      noctalia.runAsync({ "sleep", "1.5" }, function()
        if generation ~= launchGeneration then return end
        setHostWallpapers(effective)
      end)
    end)
    publish()
  end)
end

-- If the renderer dies (bad scene, GPU reset), bring Noctalia's wallpaper back
-- instead of leaving the output black.
function update()
  if not running then return end
  local generation = launchGeneration
  noctalia.runAsync({ "systemctl", "--user", "is-active", UNIT }, function(result)
    if generation ~= launchGeneration or not running then return end
    local state = type(result) == "table" and type(result.stdout) == "string" and result.stdout:match("%S+") or ""
    if state ~= "active" and state ~= "activating" and state ~= "reloading" then
      running = false
      restoreHostWallpapers()
      noctalia.notifyError("Wallpaper Engine", "linux-wallpaperengine stopped (" .. state .. "); see journalctl --user -u " .. UNIT)
      publish()
    end
  end)
end

-- ── Commands ───────────────────────────────────────────────────────────────

local function setItem(connector, id)
  if type(connector) ~= "string" or connector == "" then return end
  if type(id) ~= "string" or not id:match("^%d+$") then return end
  if connector == "*" then
    assignments = { ["*"] = id }
  else
    assignments[connector] = id
  end
  persist()
  apply()
end

local function clear(connector)
  if connector == nil or connector == "" or connector == "*" then
    assignments = {}
  else
    -- Stopping one output that inherits "*" turns "*" into explicit
    -- assignments for the remaining outputs.
    local wildcard = assignments["*"]
    if wildcard ~= nil then
      assignments["*"] = nil
      for _, name in ipairs(presentOutputs()) do
        if name ~= connector and assignments[name] == nil then assignments[name] = wildcard end
      end
    end
    assignments[connector] = nil
  end
  persist()
  apply()
end

local function setPaused(value)
  if not running then return end
  paused = value
  noctalia.runAsync({ "systemctl", "--user", value and "freeze" or "thaw", UNIT })
  publish()
end

function onIpc(event, payload)
  if event == "set" then
    -- payload: "<id>" for every output, or "<connector> <id>"
    local connector, id = tostring(payload or ""):match("^(%S+)%s+(%d+)$")
    if connector == nil then connector, id = "*", tostring(payload or "") end
    setItem(connector, id)
  elseif event == "clear" then
    clear(payload)
  elseif event == "reapply" then
    apply()
  elseif event == "pause" then
    setPaused(true)
  elseif event == "resume" then
    setPaused(false)
  elseif event == "toggle" then
    setPaused(not paused)
  end
end

noctalia.state.watch("command", function(cmd)
  if type(cmd) ~= "table" then return end
  if cmd.action == "set" then setItem(cmd.connector, cmd.id)
  elseif cmd.action == "clear" then clear(cmd.connector)
  elseif cmd.action == "toggle" then setPaused(not paused) end
end)

-- ── Lifecycle ──────────────────────────────────────────────────────────────

local lastOutputs = ""

function onOutputsChanged()
  local names = presentOutputs()
  table.sort(names)
  local key = table.concat(names, ",")
  if key == lastOutputs then return end
  lastOutputs = key
  apply()
end

function onConfigChanged(_key, _value)
  apply()
end

function onExit(_signal)
  launchGeneration += 1
  running = false
  noctalia.runAsync({ "sh", "-c", "systemctl --user thaw " .. UNIT .. " 2>/dev/null; systemctl --user stop " .. UNIT .. " 2>/dev/null; true" })
end

noctalia.runAsync({ "mkdir", "-p", STATE_DIR })
loadAssignments()
do
  local names = presentOutputs()
  table.sort(names)
  lastOutputs = table.concat(names, ",")
end
publish()

noctalia.runAsync({ "sh", "-c", "command -v linux-wallpaperengine" }, function(result)
  local path = type(result) == "table" and type(result.stdout) == "string" and result.stdout:match("^%s*(%S+)") or nil
  if path == nil or path == "" then
    noctalia.notifyError("Wallpaper Engine", "linux-wallpaperengine is not installed")
    publish()
    return
  end
  binary = path
  apply()
end)
