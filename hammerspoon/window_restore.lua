-- =============================================================
-- Window Layout — 宣言的レイアウト適用
-- =============================================================
-- systemDidWake       → 段階的リトライでレイアウト適用
-- screenWatcher       → ディスプレイ接続/切断時に自動適用
-- super(⌘⌥⌃⇧) + 1   → 手動適用

-- -----------------------------------------------
-- レイアウト定義
-- -----------------------------------------------
-- { アプリ名, スクリーン名（部分一致）, 配置 }
-- 配置: hs.layout.maximized = 最大化
local appLayout = {
    { "Google Chrome",       "GY-16Q"        },
    { "EdrawMind",           "Display"       },
    { "cmux",                "Built-in"      },
    { "Obsidian",            "LG"            },
    { "Code",                "LG"            },
    { "WebStorm",            "LG"            },
}

-- -----------------------------------------------
-- スクリーン名でスクリーンを探す（部分一致）
-- -----------------------------------------------
local function findScreen(partialName)
    -- 完全一致を優先
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == partialName then
            return screen
        end
    end
    -- 部分一致にフォールバック
    for _, screen in ipairs(hs.screen.allScreens()) do
        if string.find(screen:name(), partialName, 1, true) then
            return screen
        end
    end
    return nil
end

-- -----------------------------------------------
-- レイアウト適用
-- -----------------------------------------------
function applyLayout()
    local applied = 0
    local total = #appLayout

    for _, entry in ipairs(appLayout) do
        local appName = entry[1]
        local screenHint = entry[2]

        local app = hs.application.get(appName)
        if app then
            local targetScreen = findScreen(screenHint)
            if targetScreen then
                for _, win in ipairs(app:allWindows()) do
                    if win:isStandard() then
                        win:moveToScreen(targetScreen, false, false, 0)
                        win:maximize(0)
                        applied = applied + 1
                    end
                end
            else
                print(">>> layout: screen not found for hint '" .. screenHint .. "'")
            end
        end
    end

    print(">>> layout: applied " .. applied .. " windows (from " .. total .. " rules)")
    hs.alert.show("Layout applied: " .. applied .. " windows")
end

-- -----------------------------------------------
-- Sleep/Wake watcher — 段階的リトライ
-- -----------------------------------------------
local RETRY_DELAYS = { 3, 6, 10 }  -- 秒

local sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        print(">>> layout: systemDidWake — applying layout with retries")
        for _, delay in ipairs(RETRY_DELAYS) do
            hs.timer.doAfter(delay, function()
                print(">>> layout: retry at " .. delay .. "s")
                applyLayout()
            end)
        end
    end
end)
sleepWatcher:start()
print(">>> layout: sleep/wake watcher started")

-- -----------------------------------------------
-- スクリーン接続/切断の監視
-- -----------------------------------------------
local screenWatcher = hs.screen.watcher.new(function()
    print(">>> layout: screen configuration changed — applying layout in 2s")
    hs.timer.doAfter(2, applyLayout)
end)
screenWatcher:start()
print(">>> layout: screen watcher started")

-- -----------------------------------------------
-- スナップショット保存・復元
-- -----------------------------------------------
local SNAPSHOT_PATH = os.getenv("HOME") .. "/.hammerspoon/window_snapshot.json"

-- 全ウィンドウの位置を保存（タイトルで個別ウィンドウを区別）
local function saveSnapshot()
    local snapshot = {}
    for _, win in ipairs(hs.window.allWindows()) do
        if win:isStandard() then
            local app = win:application()
            local screen = win:screen()
            local frame = win:frame()
            if app and screen then
                table.insert(snapshot, {
                    appName = app:name(),
                    windowTitle = win:title(),
                    screenName = screen:name(),
                    x = frame.x,
                    y = frame.y,
                    w = frame.w,
                    h = frame.h,
                })
            end
        end
    end
    local json = hs.json.encode(snapshot, true)
    local f = io.open(SNAPSHOT_PATH, "w")
    if f then
        f:write(json)
        f:close()
        print(">>> snapshot: saved " .. #snapshot .. " windows")
        hs.alert.show("Snapshot saved: " .. #snapshot .. " windows")
    else
        print(">>> snapshot: failed to write file")
        hs.alert.show("Snapshot save failed!")
    end
end

-- 保存したスナップショットを復元（タイトルで個別ウィンドウをマッチ）
local function restoreSnapshot()
    local f = io.open(SNAPSHOT_PATH, "r")
    if not f then
        print(">>> snapshot: no snapshot file found")
        hs.alert.show("No snapshot found")
        return
    end
    local content = f:read("*a")
    f:close()

    local snapshot = hs.json.decode(content)
    if not snapshot then
        print(">>> snapshot: failed to parse snapshot")
        hs.alert.show("Snapshot parse error!")
        return
    end

    -- ウィンドウタイトルでマッチング（タイトルが変わっていても部分一致で対応）
    local restored = 0
    local usedWindows = {}  -- 同じウィンドウを二重に復元しないためのトラッカー

    for _, entry in ipairs(snapshot) do
        local app = hs.application.get(entry.appName)
        if app then
            local targetScreen = findScreen(entry.screenName)
            if targetScreen then
                local matched = false
                -- まずタイトル完全一致で探す
                for _, win in ipairs(app:allWindows()) do
                    local winId = win:id()
                    if win:isStandard() and not usedWindows[winId] and win:title() == entry.windowTitle then
                        win:moveToScreen(targetScreen, false, false, 0)
                        win:setFrame(hs.geometry.rect(entry.x, entry.y, entry.w, entry.h), 0)
                        usedWindows[winId] = true
                        restored = restored + 1
                        matched = true
                        break
                    end
                end
                -- 完全一致がなければタイトル部分一致で探す
                if not matched and entry.windowTitle and entry.windowTitle ~= "" then
                    for _, win in ipairs(app:allWindows()) do
                        local winId = win:id()
                        if win:isStandard() and not usedWindows[winId]
                           and string.find(win:title(), entry.windowTitle, 1, true) then
                            win:moveToScreen(targetScreen, false, false, 0)
                            win:setFrame(hs.geometry.rect(entry.x, entry.y, entry.w, entry.h), 0)
                            usedWindows[winId] = true
                            restored = restored + 1
                            matched = true
                            break
                        end
                    end
                end
            end
        end
    end

    print(">>> snapshot: restored " .. restored .. " windows")
    hs.alert.show("Snapshot restored: " .. restored .. " windows")
end

-- -----------------------------------------------
-- Manual hotkeys
-- -----------------------------------------------
local superKey = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(superKey, "1", function()
    applyLayout()
end)

hs.hotkey.bind(superKey, "2", function()
    saveSnapshot()
end)

hs.hotkey.bind(superKey, "3", function()
    restoreSnapshot()
end)

print(">>> layout: loaded (super+1 apply, super+2 save, super+3 restore)")
