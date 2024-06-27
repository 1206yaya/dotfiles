#!/bin/bash


genlabel() {
  gh label delete bug --yes
  gh label delete documentation --yes
  gh label delete duplicate --yes
  gh label delete enhancement --yes
  gh label delete 'good first issue' --yes
  gh label delete 'help wanted' --yes
  gh label delete invalid --yes
  gh label delete question --yes
  gh label delete wontfix --yes

  gh label create "bug" --description "バグ報告用。" --color FF0000
  gh label create "enhancement" --description "機能追加や改善提案用。" --color 008000
  gh label create "document" --description "ドキュメントの改善や修正用。" --color 0000FF
  gh label create "wontfix" --description "修正しないことが決まった課題。" --color 808080
  gh label create "p1" --description "高優先度の課題。" --color FF4500
  gh label create "p2" --description "中優先度の課題。" --color FFA500
  gh label create "p3" --description "低優先度の課題。" --color FFFF00
  gh label create "data_model" --description "" --color 6A1B9A
  gh label create "blocked" --description "他の課題や要因によりブロックされている課題。" --color 800080
  gh label create "feature" --description "新機能の追加に関する課題。" --color 4682B4
  gh label create "refactor" --description "リファクタリング（コードの整理や改善）に関する課題。" --color 008080
  gh label create "performance" --description "パフォーマンスの向上に関する課題。" --color 00CED1
  gh label create "security" --description "セキュリティ関連の課題。" --color 8B0000
  gh label create "ui" --description "ユーザーインターフェースやユーザーエクスペリエンスに関する課題。" --color FF69B4
  gh label create "duplicate" --description "重複している課題。" --color D3D3D3
  gh label create "invalid" --description "無効な課題（誤報や対応不要なもの）。" --color A9A9A9
  gh label create "ios" --description "" --color 1B95E0
  gh label create "Linux" --description "" --color FCC624
  gh label create "macOS" --description "" --color 000000
  gh label create "windows" --description "" --color 00A4EF
  gh label create "web" --description "" --color 4CAF50
  gh label create "android" --description "" --color 3DDC84
  gh label create "github_actions" --description "" --color 000000
}