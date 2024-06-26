

-- 入力デバイス2として使用するデバイス名を設定
set input1 to "BlackHole 16ch"
-- 入力デバイス1として使用するデバイス名を設定
set input2 to "MacBook Air Microphone"

-- System Preferencesを起動してSoundパネルを表示する
tell application "System Preferences"
    activate
    -- 少し待機する（アプリケーションが完全にアクティブになるのを待つ）
    delay 2
    set current pane to pane id "com.apple.preference.sound"
end tell

-- System Preferencesの"Sound"ウィンドウ内で"Input"ラジオボタンをクリックする
tell application "System Events" to tell process "System Preferences"
    delay 1
    tell tab group 1 of window "Sound"
        click radio button "Input"
    end tell
end tell

-- "Input"タブの"input"アンカーを表示する
tell application "System Preferences" to reveal anchor "input" of pane id "com.apple.preference.sound"

-- "Input"タブのテーブル内のデバイスを切り替える
tell application "System Events" to tell process "System Preferences"
    delay 1
    set theTable to table 1 of scroll area 1 of tab group 1 of window 1
    if (selected of row 1 of theTable whose value of text field 1 is input1) then
        select (row 1 of theTable whose value of text field 1 is input2)
    else if (selected of row 1 of theTable whose value of text field 1 is input2) then
        select (row 1 of theTable whose value of text field 1 is input1)
    end if
end tell

-- System Preferencesを終了する
tell application "System Preferences" to quit
