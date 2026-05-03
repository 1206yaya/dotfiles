-- =============================================================
-- Window Layout — スナップショットベースのレイアウト管理
-- =============================================================
-- super(⌘⌥⌃⇧) + 2   → 現在の配置を snapshot に保存
-- super(⌘⌥⌃⇧) + 1   → snapshot から配置を復元
-- screenWatcher       → ディスプレイ接続/切断時に自動復元
-- systemDidWake       → スリープ復帰時に段階的リトライで自動復元

local SNAPSHOT_PATH = os.getenv("HOME") .. "/.hammerspoon/window_snapshot.json"

-- UUID 優先 → name 完全一致 → 安全な部分一致 で screen を解決
-- 部分一致は「クエリ長 >= 4 かつ 候補数が 1 つだけ」のときのみ採用（"Display" のような汎用語の誤マッチを防ぐ）
local function resolveScreen(entry)
    local screens = hs.screen.allScreens()

    if entry.screenUUID then
        for _, s in ipairs(screens) do
            if s:getUUID() == entry.screenUUID then return s, "uuid" end
        end
    end
    if entry.screenName then
        for _, s in ipairs(screens) do
            if s:name() == entry.screenName then return s, "name-exact" end
        end
        if #entry.screenName >= 4 then
            local hits = {}
            for _, s in ipairs(screens) do
                if string.find(s:name(), entry.screenName, 1, true) then
                    table.insert(hits, s)
                end
            end
            if #hits == 1 then return hits[1], "name-partial" end
        end
    end
    return nil, "miss"
end

-- entry の保存座標 → 現在のスクリーン上の絶対 frame に変換
-- 相対座標 (relX..relH) があればスクリーン rearrangement に強いそちらを優先
local function targetFrame(entry, screen)
    local sf = screen:frame()
    if entry.relX and entry.relW then
        return hs.geometry.rect(
            sf.x + entry.relX * sf.w,
            sf.y + entry.relY * sf.h,
            entry.relW * sf.w,
            entry.relH * sf.h)
    end
    return hs.geometry.rect(entry.x, entry.y, entry.w, entry.h)
end

-- 全ウィンドウの位置を保存（screenUUID + 相対座標も同時に記録）
local function saveSnapshot()
    local snapshot = {}
    for _, win in ipairs(hs.window.allWindows()) do
        if win:isStandard() then
            local app = win:application()
            local screen = win:screen()
            local frame = win:frame()
            if app and screen then
                local sf = screen:frame()
                table.insert(snapshot, {
                    appName = app:name(),
                    windowTitle = win:title(),
                    screenName = screen:name(),
                    screenUUID = screen:getUUID(),
                    x = frame.x, y = frame.y, w = frame.w, h = frame.h,
                    relX = (frame.x - sf.x) / sf.w,
                    relY = (frame.y - sf.y) / sf.h,
                    relW = frame.w / sf.w,
                    relH = frame.h / sf.h,
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

    local stats = { restored = 0, missScreen = 0, missApp = 0, missWindow = 0 }
    local usedWindows = {}

    for _, entry in ipairs(snapshot) do
        local app = hs.application.get(entry.appName)
        if not app then
            stats.missApp = stats.missApp + 1
            print(string.format(">>> snapshot: app not running: %s", entry.appName))
        else
            local screen, how = resolveScreen(entry)
            if not screen then
                stats.missScreen = stats.missScreen + 1
                print(string.format(">>> snapshot: screen not found: name=%q uuid=%s (app=%s title=%q)",
                    entry.screenName or "?", entry.screenUUID or "?", entry.appName, entry.windowTitle or ""))
            else
                local matched
                -- 1) タイトル完全一致
                for _, win in ipairs(app:allWindows()) do
                    local id = win:id()
                    if win:isStandard() and not usedWindows[id] and win:title() == entry.windowTitle then
                        matched = win
                        break
                    end
                end
                -- 2) タイトル部分一致
                if not matched and entry.windowTitle and entry.windowTitle ~= "" then
                    for _, win in ipairs(app:allWindows()) do
                        local id = win:id()
                        if win:isStandard() and not usedWindows[id]
                           and string.find(win:title(), entry.windowTitle, 1, true) then
                            matched = win
                            break
                        end
                    end
                end

                if matched then
                    usedWindows[matched:id()] = true
                    matched:moveToScreen(screen, true, false, 0)
                    matched:setFrame(targetFrame(entry, screen), 0)
                    stats.restored = stats.restored + 1
                else
                    stats.missWindow = stats.missWindow + 1
                    print(string.format(">>> snapshot: window not matched: app=%s title=%q",
                        entry.appName, entry.windowTitle or ""))
                end
            end
        end
    end

    print(string.format(">>> snapshot: restored=%d missScreen=%d missApp=%d missWindow=%d (total=%d)",
        stats.restored, stats.missScreen, stats.missApp, stats.missWindow, #snapshot))
    if stats.missScreen > 0 then
        hs.alert.show(string.format("Restored %d/%d  (screen miss=%d)",
            stats.restored, #snapshot, stats.missScreen), 4)
    else
        hs.alert.show(string.format("Restored %d/%d  (app=%d win=%d miss)",
            stats.restored, #snapshot, stats.missApp, stats.missWindow), 4)
    end
end

-- -----------------------------------------------
-- Sleep/Wake watcher — 段階的リトライで自動復元
-- -----------------------------------------------
local RETRY_DELAYS = { 3, 6, 10 }  -- 秒

local sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        print(">>> snapshot: systemDidWake — restoring with retries")
        for _, delay in ipairs(RETRY_DELAYS) do
            hs.timer.doAfter(delay, function()
                print(">>> snapshot: retry at " .. delay .. "s")
                restoreSnapshot()
            end)
        end
    end
end)
sleepWatcher:start()
print(">>> snapshot: sleep/wake watcher started")

-- -----------------------------------------------
-- スクリーン接続/切断時に自動復元
-- -----------------------------------------------
local screenWatcher = hs.screen.watcher.new(function()
    print(">>> snapshot: screen configuration changed — restoring in 2s")
    hs.timer.doAfter(2, restoreSnapshot)
end)
screenWatcher:start()
print(">>> snapshot: screen watcher started")

-- -----------------------------------------------
-- Manual hotkeys
-- -----------------------------------------------
local superKey = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(superKey, "2", function()
    saveSnapshot()
end)

hs.hotkey.bind(superKey, "1", function()
    restoreSnapshot()
end)

print(">>> snapshot: loaded (super+2 save, super+1 restore)")
