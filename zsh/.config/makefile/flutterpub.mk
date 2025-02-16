
# include functions/Makefile
export PROJECT_ID=
export REGION=us-central

list: # Show this help.
	@awk -F':|#' '/^[a-zA-Z0-9_-]+:.*#/ { if ($$1 != "list") print $$1 ": " $$3 }' Makefile

add.firebase.store:
	fvm flutter pub add \
		firebase_core \
		cloud_firestore \
		firebase_ui_firestore \
		

add.firebase:
	fvm flutter pub add \
		firebase_auth \
		firebase_ui_auth \
		firebase_core \
		cloud_firestore \
		cloud_firestore_web \
		firebase_ui_firestore \
		firebase_storage \
		cloud_functions

add.util.riverpod:
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
		--dev 

	fvm flutter pub add \
		freezed 
	@echo ""
	@echo "--------------------------------------------------"
	@echo "pubspec.yamlに以下を追加"
	@echo "analyzer:"
	@echo "\tplugins:"
	@echo "\t\t- custom_lint"

add.util.amplify:
	fvm flutter pub add \
		amplify_flutter \
		amplify_auth_cognito \
		amplify_authenticator 

add.util.drift:
	fvm flutter pub add \
		drift \
		sqlite3_flutter_libs \
		path_provider \
		path 

	fvm flutter pub add \
		drift_dev \
		build_runner \
		--dev 

add.util:
	fvm flutter pub add \
		flutter_hooks \
		freezed_annotation \
		json_annotation

	fvm flutter pub add \
		flutter_lints \
		custom_lint \
		build_runner \
		json_serializable \
		freezed \
		--dev 

add.dio:
	fvm flutter pub add \
		dio \
		pretty_dio_logger
	fvm flutter pub add \
		http_mock_adapter \
		--dev

add.intl:
	fvm flutter pub add intl
	fvm flutter pub add flutter_localizations --sdk=flutter
	touch lib/l10n/intl_en.arb
	touch lib/l10n/intl_ja.arb
	curl -o l10n.yaml https://gist.githubusercontent.com/1206yaya/1391474f6a6b7dd6dab59b82547b9652/raw/7a260005c877049fed1f4814909a0c00a8780f50/l10n.yaml
	@echo ""
	@echo "--------------------------------------------------"
	@echo "pubspec.yamlに以下を追加"
	@echo "flutter:"
	@echo "\tgenerate: true"

add.retrofit:
	fvm flutter pub add retrofit dio json_serializable
	fvm flutter pub add build_runner retrofit_generator build_runner json_serializable --dev
	
add.env:
	fvm flutter pub add envied
	fvm flutter pub add --dev build_runner
	fvm flutter pub add --dev envied_generator
	
add.util.extra:
	fvm flutter pub add \
		go_router:^9.0.3 \
		path_provider \
		flutter_launcher_icons \
		cached_network_image \
		image_picker \
		image_picker_web 


