-- y   k   u
-- h       l
-- b   j   n
-- ウィンドウを指定した量だけ移動する関数
local function moveWindow(dx, dy)
  local win = hs.window.focusedWindow()
  if not win then return end
  
  local f = win:frame()
  f.x = f.x + dx
  f.y = f.y + dy
  win:setFrame(f)
end

-- ホットキーのマッピング
local keyMappings = {
  -- Y = {-10, -10}, -- 左上
  -- K = {  0, -10}, -- 上
  -- U = { 10, -10}, -- 右上
  -- H = {-10,   0}, -- 左
  -- L = { 10,   0}, -- 右
  -- B = {-10,  10}, -- 左下
  -- J = {  0,  10}, -- 下
  -- N = { 10,  10}  -- 右下
}

-- ホットキーを登録
for key, delta in pairs(keyMappings) do
  hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, key, function()
    moveWindow(delta[1], delta[2])
  end)
end

local function moveWindow(x, y, w, h)
  local win = hs.window.focusedWindow()
  if win then
      local f = win:frame()
      local screen = win:screen()
      local max = screen:frame()

      f.x = max.x + max.w * x
      f.y = max.y + max.h * y
      f.w = max.w * w
      f.h = max.h * h

      win:setFrame(f)
  end
end

local hyper = {"cmd", "alt", "ctrl"}

-- 1/2
-- J   K
-- H   L

-- 1/3
-- Y I P

-- 1/4
-- U   O
-- M   .

hs.hotkey.bind(hyper, "H", function() moveWindow(0, 0, 0.5, 1) end) -- 左半分
hs.hotkey.bind(hyper, "L", function() moveWindow(0.5, 0, 0.5, 1) end) -- 右半分
hs.hotkey.bind(hyper, "J", function() moveWindow(0, 0.5, 1, 0.5) end) -- 下半分
hs.hotkey.bind(hyper, "K", function() moveWindow(0, 0, 1, 0.5) end) -- 上半分

hs.hotkey.bind(hyper, "U", function() moveWindow(0, 0, 0.5, 0.5) end) -- 左上 1/4
hs.hotkey.bind(hyper, "O", function() moveWindow(0.5, 0, 0.5, 0.5) end) -- 右上 1/4
hs.hotkey.bind(hyper, "M", function() moveWindow(0, 0.5, 0.5, 0.5) end) -- 左下 1/4
hs.hotkey.bind(hyper, ".", function() moveWindow(0.5, 0.5, 0.5, 0.5) end) -- 右下 1/4

hs.hotkey.bind(hyper, "Y", function() moveWindow(0, 0, 1/3, 1) end) -- 左1/3
hs.hotkey.bind(hyper, "I", function() moveWindow(1/3, 0, 1/3, 1) end) -- 中央1/3
hs.hotkey.bind(hyper, "P", function() moveWindow(2/3, 0, 1/3, 1) end) -- 右1/3


local function maximizeWindow()
    local win = hs.window.focusedWindow()
    if win then
        win:maximize()
    end
end

local function centerWindow()
    local win = hs.window.focusedWindow()
    if win then
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()
        
        f.x = max.x + (max.w - f.w) / 2
        f.y = max.y + (max.h - f.h) / 2
        
        win:setFrame(f)
    end
end

hs.hotkey.bind(hyper, "0", maximizeWindow) -- `⌘⌥⌃ + 0` でウィンドウ最大化
hs.hotkey.bind(hyper, "C", centerWindow) -- 中央に配置（サイズ保持）

-- =============================================================
-- Activity Monitor - HTTP API + Dashboard
-- =============================================================
print(">>> Activity Monitor loading...")

local monitorState = {
    activeApp = "",
    activeAppBundle = "",
    activeWindowTitle = "",
    idleTime = 0,
    windows = {},
    browserUrl = "",
    lastUpdate = "",
}

local function getMonitorBrowserUrl(appName)
    local scripts = {
        ["Google Chrome"] = 'tell application "Google Chrome" to return URL of active tab of front window',
        ["Brave Browser"] = 'tell application "Brave Browser" to return URL of active tab of front window',
        ["Safari"] = 'tell application "Safari" to return URL of current tab of front window',
        ["Arc"] = 'tell application "Arc" to return URL of active tab of front window',
    }
    local script = scripts[appName]
    if not script then return "" end
    local ok, result = hs.osascript.applescript(script)
    if ok then return result else return "" end
end

local monitorAppWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if eventType == hs.application.watcher.activated then
        monitorState.activeApp = appName or ""
        monitorState.activeAppBundle = app and app:bundleID() or ""
        local win = app and app:focusedWindow()
        monitorState.activeWindowTitle = win and win:title() or ""
        monitorState.browserUrl = getMonitorBrowserUrl(appName or "")
    end
end)
monitorAppWatcher:start()
print(">>> appWatcher started")

local monitorTimer = hs.timer.doEvery(2, function()
    monitorState.idleTime = math.floor(hs.host.idleTime())
    monitorState.lastUpdate = os.date("!%Y-%m-%dT%H:%M:%SZ")

    pcall(function()
        local wins = hs.window.visibleWindows()
        local windowList = {}
        for _, w in ipairs(wins) do
            local app = w:application()
            table.insert(windowList, {
                title = w:title() or "",
                app = app and app:name() or "",
                bundle = app and app:bundleID() or "",
                id = w:id(),
            })
        end
        monitorState.windows = windowList
    end)

    local focused = hs.window.focusedWindow()
    if focused then
        monitorState.activeWindowTitle = focused:title() or ""
        local app = focused:application()
        if app then
            monitorState.activeApp = app:name() or ""
            monitorState.activeAppBundle = app:bundleID() or ""
        end
    end

    -- Write monitor.json for the Python HTTP server
    pcall(function()
        local monitorPath = os.getenv("HOME") .. "/.config/hammerspoon/monitor.json"
        local ok, json = pcall(hs.json.encode, monitorState)
        if ok then
            local f = io.open(monitorPath, "w")
            if f then
                f:write(json)
                f:close()
            end
        end
    end)
end)
print(">>> updateTimer started — writing monitor.json")

-- -----------------------------------------------
-- Window Restore (sleep/wake)
-- -----------------------------------------------
require("window_restore")
