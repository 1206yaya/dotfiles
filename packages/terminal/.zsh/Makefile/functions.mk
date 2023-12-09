list:
	@awk -F':' '/^[a-zA-Z0-9_.-]+:.*$$/ { if ($$1 != "list") print $$1 ": " $$2 }' Makefile

init:
	npm install
	mkdir .vscode
# functionsのデバッグ設定ファイルをダウンロード
	curl -o .vscode/launch.json "https://gist.githubusercontent.com/1206yaya/eccb236bfb61a81a455d65f1311686df/raw/09c7120372cb8988a6902d73b0c6a23cb9b76730/launch.json"


build: # typescriptをコンパイルする
	npm run build

buildw: # ファイルの変更を監視して自動でビルドする
	npm run build:watch

start: # ブラウザ（HTTP）で関数を実行する
# --inspect-functions : デバッグ可能にする
	firebase emulators:start --only functions --inspect-functions

shell: # コマンドラインから関数を実行する
	@echo "firebase > helloWorld()"
	npm run shell

func.deploy: # cloud functions deploy
	npm run build; firebase deploy --only functions;
