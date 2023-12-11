
# include functions/Makefile

list: # Show this help.
	@awk -F':|#' '/^[a-zA-Z0-9_-]+:.*#/ { if ($$1 != "list") print $$1 ": " $$3 }' Makefile


upgrade: # fvm upgrade
	@echo "利用可能なバージョンのリストを取得"
	@echo "fvm releases"
	@echo "特定のバージョンをインストール"
	@echo "fvm install <version>"
	@echo "プロジェクトに設定"
	@echo "fvm use <version>"

watch: 
	fvm flutter pub run build_runner build --delete-conflicting-outputs; flutter pub run build_runner watch 
gen: # build_runner build 
	fvm flutter pub run build_runner build 

genf: # build_runner build --delete-conflicting-outputs
	fvm flutter pub run build_runner build --delete-conflicting-outputs

genintl: # gen-l10n
	fvm flutter gen-l10n

genkey:
	fvm flutter pub add firebase_core firebase_auth google_sign_in
	echo "password: android"
	keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore

get: # pub get
	fvm flutter pub get
	


clean.ios: # rm Podfile.lock Pods
	flutter clean; flutter pub get; cd ios; rm -rf  Podfile.lock ; rm -rf Pods; \
		pod repo update; pod install; cd ..
		
func.init: # cloud functions init
	firebase init 


add.firebase:
	fvm flutter pub add \
		firebase_auth \
		firebase_ui_auth \
		firebase_core \
		cloud_firestore \
		firebase_ui_firestore \
		firebase_storage

add.util:
	fvm flutter pub add \
		flutter_riverpod \
		riverpod_annotation \
		flutter_hooks \
		hooks_riverpod 

	fvm flutter pub add \
		flutter_lints \
		riverpod_lint \
		custom_lint \
		build_runner \
		riverpod_generator \
		json_serializable \
		dartz \
		--dev 

	fvm flutter pub add \
		freezed \
		intl:^0.18.0 \
		go_router:^9.0.3 \
		path_provider \
		flutter_launcher_icons \
		cached_network_image \
		image_picker \
		image_picker_web 

	@echo ""
	@echo "--------------------------------------------------"
	@echo "pubspec.yamlに以下を追加"
	@echo "dependencies:"
	@echo "\tflutter:"
	@echo "\t\tsdk: flutter"
	@echo "\tflutter_localizations:"
	@echo "\t\tsdk: flutter"
	@echo ""
	@echo "flutter:"
	@echo "\tgenerate: true"


run.all: #
	make runios &
	make runandroid &
	make runchrome &
	make runmac &
run.mac:
	fvm flutter run -d macos
run.chrome:
	fvm flutter run -d chrome
# アンドロイドは手動でないと、一つのAVDでエミュレーターが複数起動するエラーが発生する
# runandroid:
# 	emulator -avd Pixel_3a_API_33_arm64-v8a-10GB &
# # エミュレータがオフラインから完全に起動するのを待つ
# 	@while adb shell getprop sys.boot_completed 2>/dev/null | grep -vq 1; do sleep 5; done
# 	@ANDROID_DEVICE_ID=$(shell fvm flutter devices | grep "android" | awk '{print $$6}') && \
# 	echo "@@@@ $$ANDROID_DEVICE_ID"
# 	fvm flutter run -d $$ANDROID_DEVICE_ID &
run.ios: # シミュレーターを起動する
	open -a Simulator
# シミュレータが完全に起動するのを待つ
	@while ! xcrun simctl list devices | grep Booted; do sleep 5; done
	@IOS_DEVICE_ID=$(shell fvm flutter devices | grep "iOS" | awk '{print $$7}') && \
	fvm flutter run -d $$IOS_DEVICE_ID &


start:
	firebase emulators:start --only auth,firestore,functions --import=seed --inspect-functions

pull_official:
	svn checkout https://github.com/letsar/flutter_staggered_grid_view/trunk/examples/assets assets/pub_flutter_staggered_grid_view_official_example/
# svn checkout https://github.com/letsar/flutter_staggered_grid_view/trunk/examples/lib lib/pub_flutter_staggered_grid_view_official_example
# パターン1 svn checkout https://github.com/flutter/packages/trunk/packages/go_router/example/lib lib/official_example
# パターン2 svn checkout https://github.com/rrousselGit/flutter_hooks/trunk/packages/flutter_hooks/example/lib lib/official_example
