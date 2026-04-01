-- =============================================================
-- Window Restore on Sleep/Wake
-- =============================================================
-- systemWillSleep  → 全ウィンドウの配置を JSON に保存
-- systemDidWake    → 遅延後にリストア
-- ⌘⌥⌃ + S         → 手動保存
-- ⌘⌥⌃ + R         → 手動リストア

local SAVE_PATH = os.getenv("HOME") .. "/.hammerspoon/window_layout.json"
local RESTORE_DELAY = 3  -- ディスプレイ再認識を待つ秒数

-- -----------------------------------------------
-- Save layout
-- -----------------------------------------------
local function saveLayout()
    local layout = {}
    local allWindows = hs.window.allWindows()
    for _, win in ipairs(allWindows) do
        if win:isStandard() then
            local app = win:application()
            local frame = win:frame()
            local screen = win:screen()
            if app and screen then
                table.insert(layout, {
                    appName = app:name(),
                    bundleID = app:bundleID(),
                    windowTitle = win:title(),
                    windowID = win:id(),
                    frame = {
                        x = frame.x,
                        y = frame.y,
                        w = frame.w,
                        h = frame.h,
                    },
                    screenName = screen:name(),
                    screenID = screen:getUUID(),
                })
            end
        end
    end

    local ok, json = pcall(hs.json.encode, layout, true)
    if not ok then
        print(">>> window_restore: JSON encode failed: " .. tostring(json))
        return
    end

    local f = io.open(SAVE_PATH, "w")
    if f then
        f:write(json)
        f:close()
        print(">>> window_restore: saved " .. #layout .. " windows")
    else
        print(">>> window_restore: failed to write " .. SAVE_PATH)
    end
end

-- -----------------------------------------------
-- Restore layout
-- -----------------------------------------------
local function restoreLayout()
    local f = io.open(SAVE_PATH, "r")
    if not f then
        print(">>> window_restore: no saved layout found")
        return
    end
    local raw = f:read("*a")
    f:close()

    local ok, layout = pcall(hs.json.decode, raw)
    if not ok or type(layout) ~= "table" then
        print(">>> window_restore: failed to parse layout JSON")
        return
    end

    -- スクリーン UUID → screen オブジェクトのマップ
    local screenMap = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        screenMap[screen:getUUID()] = screen
    end

    local restored = 0
    for _, entry in ipairs(layout) do
        local app = hs.application.get(entry.bundleID)
        if app then
            for _, win in ipairs(app:allWindows()) do
                if win:isStandard() and win:title() == entry.windowTitle then
                    local targetScreen = screenMap[entry.screenID]
                    if targetScreen then
                        -- 対象スクリーンに移動してからフレーム設定
                        win:moveToScreen(targetScreen, false, false, 0)
                    end
                    local frame = hs.geometry.rect(
                        entry.frame.x, entry.frame.y,
                        entry.frame.w, entry.frame.h
                    )
                    win:setFrame(frame, 0)
                    restored = restored + 1
                    break
                end
            end
        end
    end

    print(">>> window_restore: restored " .. restored .. "/" .. #layout .. " windows")
    hs.alert.show("Windows restored: " .. restored .. "/" .. #layout)
end

-- -----------------------------------------------
-- Sleep/Wake watcher
-- -----------------------------------------------
local sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemWillSleep then
        print(">>> window_restore: systemWillSleep — saving layout")
        saveLayout()
    elseif event == hs.caffeinate.watcher.systemDidWake then
        print(">>> window_restore: systemDidWake — restoring in " .. RESTORE_DELAY .. "s")
        hs.timer.doAfter(RESTORE_DELAY, function()
            restoreLayout()
        end)
    end
end)
sleepWatcher:start()
print(">>> window_restore: sleep/wake watcher started")

-- -----------------------------------------------
-- Manual hotkeys
-- -----------------------------------------------
local hyper = {"cmd", "alt", "ctrl"}
hs.hotkey.bind(hyper, "S", function()
    saveLayout()
    hs.alert.show("Window layout saved")
end)
hs.hotkey.bind(hyper, "R", function()
    restoreLayout()
end)

print(">>> window_restore: loaded (⌘⌥⌃+S save, ⌘⌥⌃+R restore)")
