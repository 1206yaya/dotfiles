
export PROJECT_ID=

list: # Show this help.
	@awk -F':|#' '/^[a-zA-Z0-9_-]+:.*#/ { if ($$1 != "list") print $$1 ": " $$3 }' Makefile

gen: # build_runner build 
	fvm flutter pub run build_runner build 

genf: # build_runner build --delete-conflicting-outputs
	fvm flutter pub run build_runner build --delete-conflicting-outputs



genintl: # gen-l10n
	fvm flutter gen-l10n

open: # open firebase console
	open https://console.firebase.google.com/u/0/project/${PROJECT_ID}/crashlytics/app/ios/${PROJECT_ID}/dsyms
	

flutter_connect:
	flutterfire configure --project=${PROJECT_ID}

clean.macos: # rm Podfile.lock Pods
	flutter clean
	rm -rf macos/Pods
	rm -rf macos/Podfile.lock
	flutter pub get
	pod install --project-directory=macos

clean.ios: # rm Podfile.lock Pods
	flutter clean
	rm -rf ios/Pods
	rm -rf ios/Podfile.lock
	flutter pub get
	pod install --project-directory=ios

firebase.init: # firebase init 
	fvm flutter pub add firebase_core
	flutterfire configure -y --project=${PROJECT_ID}

genicon:
	fvm flutter pub run flutter_launcher_icons:main

genkey:
	fvm flutter pub add firebase_core firebase_auth google_sign_in
	echo "password: android"
	keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore

genipa:
	flutter build ipa --export-options-plist="ios/configs/ExportOptions.plist"
	ditto -c -k --sequesterRsrc --keepParent build/ios/archive/Runner.xcarchive/dSYMs  Runner.app.dSYM.zip
	open https://console.firebase.google.com/u/0/project/${PROJECT_ID}/crashlytics/app/ios/${PROJECT_ID}/dsyms


start:
	firebase emulators:start --only auth,firestore,functions --import=seed --inspect-functions

