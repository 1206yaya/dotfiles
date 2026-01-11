package main

import "ws/cmd"

// これが存在するとき
// /Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain.worktrees/PER-6961

// ws new PER-6961
// としたら、つぎを作成する
// /Users/Komatsu.Aya/ghq/github.com/hrbrain/code-workspaces/PER-6961.code-workspace
// {
//   "folders": [
//     {
//       "path": "/Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain.worktrees/PER-6961/apps/persia/app"
//     },
//     {
//       "path": "/Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain.worktrees/PER-6961/apps/persia/front"
//     },
//     {
//       "path": "/Users/Komatsu.Aya/ghq/github.com/hrbrain/hrbrain.worktrees/PER-6961/apps/persia/schema"
//     }
//   ]
// }

func main() {
	cmd.Execute()
}
