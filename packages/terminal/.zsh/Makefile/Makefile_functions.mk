list:
	@awk -F':' '/^[a-zA-Z0-9_.-]+:.*$$/ { if ($$1 != "list") print $$1 ": " $$2 }' Makefile

build: # typescriptをコンパイルする
	npm run build

buildw: # ファイルの変更を監視して自動でビルドする
	npm run build:watch

start: # ブラウザ（HTTP）で関数を実行する
	firebase emulators:start

shell: # コマンドラインから関数を実行する
	@echo "firebase > helloWorld()"
	npm run shell