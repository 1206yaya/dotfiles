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
    { "Google Chrome",       "Display"       },
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
-- Manual hotkeys
-- -----------------------------------------------
local superKey = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(superKey, "1", function()
    applyLayout()
end)

print(">>> layout: loaded (super+1 apply)")
