TOTAL_MINS=0

while true; do
    # --- 25分セクション ---
    afplay /System/Library/Sounds/Glass.aiff
    for i in {1..25}; do
        echo "【作業中】累計時間: ${TOTAL_MINS}分経過 (このセットの残り: $((26-i))分)"
        sleep 60
        ((TOTAL_MINS++))
    done

    # --- 5分セクション ---
    afplay /System/Library/Sounds/Ping.aiff
    for i in {1..5}; do
        echo "【休憩中】累計時間: ${TOTAL_MINS}分経過 (このセットの残り: $((6-i))分)"
        sleep 60
        ((TOTAL_MINS++))
    done
done